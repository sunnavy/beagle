/*
 * Beagle JavaScript Library
 *
 * Copyright 2011, sunnavy@gmail.com
 * licensed under GPL Version 2.
 */

beaglePrefix = "/";

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
    var year = $('div.beagle').children('span[name=year]').text();

    if ( ! year ) {
        var result =  window.location.pathname.match(/archive\/(\d{4})/);
        if ( result ) {
            year = result[1];
        }
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
    beaglePrefix = $('div.beagle').children('span[name=prefix]').text() || '/';

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

    $('div.message').delay(3000).fadeOut('slow');

}

