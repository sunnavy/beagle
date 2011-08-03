/*
 * Beagle JavaScript Library
 *
 * Copyright 2011, sunnavy@gmail.com
 * licensed under GPL Version 2.
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

function beagleListHover ( ) {
    $('div.list div.summary h3 a, div.list div.summary div.glance' ).hoverIntent(
    {
        timeout: 500,
        over: function () {
            var parent = $(this).closest('div.summary');
            var glance = parent.children( 'div.glance' ).first();
            if ( glance && glance.text() == '' ) {
                var id = parent.find('a').first().attr('id');
                if ( id ) {
                    $.get('/fragment/entry/' + id, function ( data ) {
                        glance.html(data);
                    } );
                }
            }
            glance.show();
        },
        out: function () {}
    }
    );

    $('div.list div.summary').hoverIntent( {
        timeout: 500,
        over: function () {},
        out: function () { $(this).children('div.glance').hide() }
    } );
}

function beagleInit ( opts ) {
    prettyPrint();

    $('a.toggle.hide').click(
        function() {
            $(this).closest('div:has("div.content")').children('div.content').hide();
            $(this).hide();
            $(this).siblings('a.toggle.show').show();
            return false;
        }
    );
    $('a.toggle.show').click(
        function() {
            $(this).closest('div:has("div.content")').children('div.content').show();
            $(this).hide();
            $(this).siblings('a.toggle.hide').show();
            return false;
        }
    );

    $('a.comments-toggle').click(
        function() {
            var comments =
                $(this).closest('div.comments').children('div.content');
            if ( comments.is(':visible') ) {
                comments.hide();
            }
            else {
                comments.show();
            }
            return false;
        }
    );

    beagleArchive();
    beagleContrast();
    beagleListHover();

    $('div.message').delay(3000).fadeOut('slow');

}

