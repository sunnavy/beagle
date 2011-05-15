/*
 * Beagle JavaScript Library
 *
 * Copyright 2011, sunnavy@gmail.com
 * licensed under the GPL Version 2.
 */

function beagleBindKeys () {
    $('textarea').keydown(function (e) {
        if ( e.keyCode == 13 && e.ctrlKey ) {
            $(this).closest('form').submit();
            $(this).val('');
        }
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

function beagleAjaxComment ( ) {
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
                            var parent = form.closest('div.comments').children('div.content');
                            parent.append(str);
                            beagleContrast(parent);
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

function beagleAdminInit ( ) {

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

    beagleAjaxComment();
    beagleAjaxDelete();
    beagleBindKeys();

    $('textarea.markitup.wiki').markItUp( wikiSettings );
    $('textarea.markitup.markdown').markItUp( markdownSettings );
}

