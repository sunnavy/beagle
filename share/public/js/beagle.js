/*
 * Beagle JavaScript Library
 *
 * Copyright 2011, sunnavy@gmail.com
 * Dual licensed under the MIT or GPL Version 2 licenses.
 */

function beagleContrast (p) {
    if ( !p ) {
        p = 'body';
    }
    $(p).find('.contrast').removeClass('odd even');
    $(p).find('.contrast:odd').addClass('odd');
    $(p).find('.contrast:even').addClass('even');
}

function beagleIsEmpty ( e ) {
    var v = e.val();
    if ( v == '' || v == e.attr('placeholder') ) {
        return true;
    }

    if ( v.match(/\S/) ) {
        return false;
    }
    return true;
}

function beagleIsInRange ( e, start, end ) {
    var l = e.val().length;
    return l >= start && l <= end;
}

function beagleToggle ( ) {
    if ( $(this).parent().children('ul:not(:hidden)').length ) {
        $(this).parent().children('ul:not(:hidden)').hide();
        $(this).html('+');
    }
    else {
        $(this).parent().children('ul:hidden').show();
        $(this).html('-');
    }
}

function beagleBindKeys () {
    $('textarea').keydown(function (e) {
        if ( e.keyCode == 13 && e.ctrlKey ) {
            $(this).closest('form').submit();
            $(this).val('');
        }
    } );
}

function beagleAjaxSearch () {
    $('form.search').ajaxForm( {
        url: '/search',
        dataType: 'json',
        type: 'post',
        beforeSubmit: function (arr, form) {
            var e = form.find('input[name=query]');
            if ( beagleIsEmpty( e ) ) {
                return false;
            }
            else {
                return true;
            }
        },
        success: function( json, status, xhr, form ) {
            form.submitted = false;

            if ( json ) {
                if ( json.results.length >= 1 ) {
                    form.find('input').val('');
                    if ( json.results.length == 1 ) {
                        $('#content').load(
                            '/fragment/entry/' + json.results[0].id, function() {
                                beagleContrast('#content');
                            }
                        );
                    }
                    else {
                        var html = '<div class="results"><ul>';
                        for ( i in json.results ) {
                            var entry = json.results[i];
                            html += '<li><a href="/entry/' + entry.id + '" >' + entry.summary + '</a></li>';
                        }
                        html += '</ul></div>';
                        $('#content').html( html );
                    }
                }
                else {
                    $('#content').html( '<div class="warnings">not found</div>' );
                }
            }
        },
    } );
}

function beagleAjaxDelete () {
    $('form.delete').ajaxForm( {
        url: '/admin/entry/delete',
        dataType: 'json',
        type: 'post',
        beforeSubmit: function (arr, form) {
            var yes = confirm('really delete?');
            if ( !yes ) {
                return false;
            }
            var id = form.find('input[name=id]').val();
            if ( !id ) {
                return false;
            }
            return true;
        },
        success: function( json, status, xhr, form ) {
            if ( json && json.status == 'deleted' ) {
                var id = form.find('input[name=id]').val();
                $('div#'+id).remove();
                if ( json.redraw_menu ) {
                    $('#menu').load('/fragment/menu', function () {
                        beagleContrast('#menu');
                    } );
                }
                beagleContrast('#content');
            }
        },
    } );
}

function beagleAjaxComment ( admin ) {
    $('div.create-comment form').ajaxForm(
            {
                beforeSubmit: function (arr,form) {
                    var e = form.find('textarea');
                    if ( beagleIsEmpty( e ) ) {
                        return false;
                    }
                    else if ( !beagleIsInRange( e, 0, 1000 ) ) {
                        $('<div></div>').html('Content is too large!').dialog({
                            autoOpen: true,
                            title: 'Error!',
                            show: 'slide',
                        });
                        return false;
                    }

                    else {
                        return true;
                    }
                },
                url: "/admin/entry/comment/new",
                dataType: 'json',
                type: 'post',
                success: function(json, status, xhr, form ) {
                    form.submitted = false;
                    if ( json ) {

                        if ( json.status == 'created' ) {
                            var str = json.content;
                            form.find('textarea').val('');
                            if ( admin ) {
                                var parent = form.closest('div.comments').children('div.content');
                                parent.append(str);
                                beagleContrast(parent);
                            }
                            else {
                                $('<div></div>').html('Thanks for your comment!').dialog({
                                    autoOpen: true,
                                    title: 'Sent!',
                                    show: 'slide',
                                });
                            }
                            return true;
                        }
                        else {
                            $('<div></div>').html(json.message).dialog({
                                autoOpen: true,
                                title: json.status,
                                show: 'slide',
                            });
                        }
                    }
                },
            }
    );
}

function beagleArchive ( ) {
    var result = window.location.pathname.match(/date\/(\d{4})/);
    var year;
    if ( result ) {
        year = result[1];
    }

    if ( year ) {
        $('.toggle-expand.year_' + year).parent().children('ul').show();
        $('.toggle-expand.year_' + year).html('-');
    }
    else {
        $('.toggle-expand:first').parent().children('ul').show();
        $('.toggle-expand:first').html('-');
    }
    $('.toggle-expand').toggle( beagleToggle, beagleToggle );
}

function beagleInit ( opts ) {
    prettyPrint();
    $('a.toggle-hide').toggle(
        function() {
            $(this).closest('div:has("div.content")').children('div.content').hide();
            $(this).text('show');
        },
        function() {
            $(this).closest('div:has("div.content")').children('div.content').show();
            $(this).text('hide');
        }
    );

    $('a.title-toggle-hide').toggle(
        function() {
            $(this).closest('div:has("div.content")').children('div.content').hide();
        },
        function() {
            $(this).closest('div:has("div.content")').children('div.content').show();
        }
    );

    $('select[name=format]').change( function() {
        var val = $('select[name=format]').val();
        var e = $(this).closest('form').find('textarea')
        var form = $(this).closest('form');
        if ( val == 'plain' ) {
            e.markItUpRemove();
        }
        else if ( val == 'wiki' ) {
            if ( !form.find('div.markItUp').length ) {
                e.markItUp( wikiSettings );
            }
        }
        else if ( val == 'markdown' ) {
            if ( !form.find('div.markItUp').length ) {
                e.markItUp( markdownSettings );
            }
        }
    });


    $('a.delete').click( function() {
        var form = $(this).closest('form');
        if ( form ) {
            form.submit();
        }
        return false;
    } );

    beagleAjaxComment( opts['admin'] );

    if ( opts['admin'] ) {
        beagleAjaxDelete();
    }

    beagleAjaxSearch();
    beagleArchive();
    beagleBindKeys();
    beagleContrast();

    $('div.message').delay(3000).fadeOut('slow');

    if ( opts['admin'] ) {
        $('textarea.markitup.wiki').markItUp( wikiSettings );
        $('textarea.markitup.markdown').markItUp( markdownSettings );
    }


    $('form').submit(function() {
        if (this.submitted) {
            return false;
        }
        else {
            this.submitted = true;
        }
    });

}

