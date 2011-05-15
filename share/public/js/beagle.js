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

function beagleAjaxSearch () {
    $('#search form').submit( function () {
        var form = $(this);
        var query = form.find('input[name=query]');
        if ( ! beagleIsEmpty( query ) ) {
            $.ajax( {
                type: 'post',
                url: '/search',
                data: { query: query.val() },
                dataType: 'json',
                success: function (json) {
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
                    $('#search form').find('input[name=query]').val('');

                } } );
        }
        return false;
    } )
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

    beagleAjaxSearch();
    beagleArchive();
    beagleContrast();

    $('div.message').delay(3000).fadeOut('slow');

    $('form').submit(function() {
        if (this.submitted) {
            return false;
        }
        else {
            this.submitted = true;
        }
    });

}

