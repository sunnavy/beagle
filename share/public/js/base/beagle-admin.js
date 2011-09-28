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
        }
    } );
}

function beagleAjaxDeleteEntry () {
    $('form.delete.entry').ajaxForm( {
        url: beaglePrefix + 'admin/entry/delete',
        dataType: 'json',
        type: 'post',
        beforeSubmit: function (arr, form) {
            var id = form.find('input[name=id]').val();
            if ( !id ) {
                return false;
            }
            return true;
        },
        success: function( json, status, xhr, form ) {
            if ( json && json.status == 'deleted' ) {
                if ( window.location.pathname.match(/admin\/entries/ ) ) {
                    $(form).closest('li').remove();
                    beagleContrast($(form).closest('ul'));
                }
                else if ( window.location.pathname.match(/admin\/entry/ ) ) {
                    window.location = beaglePrefix+'admin/entries';
                }
                else {
                    var id = form.find('input[name=id]').val();
                    $('#'+id).remove();
                    if ( json.redraw_menu ) {
                        $('#menu').load(beaglePrefix + 'fragment/menu', function () {
                            beagleContrast('#menu');
                        } );
                    }
                    beagleContrast($(form).closest('comments'));
                }
            }
        },
    } );
}

function beagleAjaxCreateComment ( ) {
    $('form.create-comment').ajaxForm(
            {
                beforeSubmit: function (arr,form) {
                    var e = form.find('textarea');
                    if ( beagleIsEmpty( e ) ) {
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
                            var comments =
                                form.closest('div.comments').children('div.content');
                            if ( comments.is(':not(:visible)') ) {
                                comments.show();
                            }
                            return true;
                        }
                        else {
                            alert( json.status );
                        }
                    }
                },
            }
    );
}

function beagleAdminInit ( ) {

    $('select[name=format]').change( function() {
        var val = $('select[name=format]').val();
        var e = $(this).closest('form').find('textarea');
        var form = $(this).closest('form');
        if ( val == 'wiki' ) {
            if ( !form.find('div.markItUp').length ) {
                e.markItUp( wikiSettings );
            }
        }
        else if ( val == 'markdown' ) {
            if ( !form.find('div.markItUp').length ) {
                e.markItUp( markdownSettings );
            }
        }
        else {
            e.markItUpRemove();
        }
    });


    $('a.delete').click( function() {
        var form = $(this).closest('form');
        if ( form ) {
            form.submit();
        }
        return false;
    } );

    beagleAjaxCreateComment();
    beagleAjaxDeleteEntry();
    beagleBindKeys();

    $('textarea.markitup.wiki').markItUp( wikiSettings );
    $('textarea.markitup.markdown').markItUp( markdownSettings );

    $('input.attach-more').click( function() {
        var att = $(this).closest('form').find('div.attach').first().clone();
        var p = $(this).closest('div.wrapper');
        p.before(att);
        return false;
    } );

    $('div.hover.create-entry' ).hoverIntent(
    {
        timeout: 500,
        over: function () {
            $(this).children('ul').show();
        },
        out: function () { $(this).children('ul').hide(); }
    }
    );
}

