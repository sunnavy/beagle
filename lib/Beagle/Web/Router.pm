package Beagle::Web::Router;
use Beagle::Web;
use Beagle::Util;
use Encode;
use Lingua::EN::Inflect 'A';
use Class::Load ':all';
use Router::Simple;
use Beagle::Web::Request;
use Beagle::Web::Form;
use JSON;
use Beagle::I18N;
use I18N::LangTags;
use I18N::LangTags::Detect;
use Beagle::Web::Router::Util;

get '/' => sub {
    my $limit = scalar @{ bh()->entries };
    my $max   = Beagle::Web->home_limit;
    $limit = $max if $limit > $max;
    render 'index',
      entries => [ @{ bh()->entries }[ 0 .. $limit - 1 ] ];
};

get '/fragment/menu' => sub {
    render 'menu';
};

get '/fragment/entry/:id' => sub {
    my %vars = @_;
    my $i    = $vars{id} or return;
    my @ret  = resolve_id( $i, handle => bh() );
    return unless @ret == 1;

    render 'entry', entry => $ret[0]->{entry};
};

get '/tag/:tag' => sub {
    my %vars = @_;
    my $tag  = decode_utf8 $vars{tag};

    return Beagle::Web::redirect '/'
      unless $tag && Beagle::Web->tags( bh() )->{$tag};

    render 'index',
      $tag  => 1,
      title => "tag $tag",
      entries =>
      [ map { bh()->map->{$_} } @{ Beagle::Web->tags( bh() )->{$tag} } ],
      prefix => $prefix || '../';
};

get '/date/{year:[0-9]+}' => sub {
    my %vars = @_;
    my $year = $vars{year};
    return Beagle::Web::redirect '/'
      unless $year && Beagle::Web->years( bh() )->{$year};
    return render 'index',
      entries => [
        map   { bh()->map->{$_} }
          map { @{ Beagle::Web->years( bh() )->{$year}{$_} } }
          keys %{ Beagle::Web->years( bh() )->{$year} }
      ],
      title  => "in $year",
      prefix => $prefix || '../';
};

get '/date/{year:[0-9]+}/{month:[0-9]{2}}' => sub {
    my %vars  = @_;
    my $year  = $vars{year};
    my $month = $vars{month};
    return Beagle::Web::redirect '/'
      unless Beagle::Web->years( bh() )->{$year}{$month};
    return render 'index',
      entries => [ map { bh()->map->{$_} }
          @{ Beagle::Web->years( bh() )->{$year}{$month} } ],
      title  => "in $year/$month",
      prefix => $prefix || '../../';
};

get '/entry/:id' => sub {
    my %vars = @_;
    my $i    = $vars{id};
    my @ret  = resolve_id( $i, handle => bh() );
    return Beagle::Web::redirect "/" unless @ret == 1;
    my $id = $ret[0]->{id};
    return Beagle::Web::redirect "/entry/$id" unless $i eq $id;

    my $entry = $ret[0]->{entry};

    if ( $entry->type eq 'comment' ) {
        return
            Beagle::Web::redirect '/entry/'
          . $entry->parent_id . '#'
          . $entry->id;
    }

    render 'index',
      entries      => [$entry],
      $entry->type => 1,
      title        => $entry->summary(10),
      prefix       => $prefix || '../';
};

get '/about' => sub {
    render 'about', title => 'about';
};

get '/feed' => sub { Beagle::Web->feed()->to_string };

any '/search' => sub {
    my $query = req()->param('query');
    return render 'search', title => 'search' unless $query;

    my @found;
    for my $entry ( @{ bh()->entries } ) {
        push @found, $entry if $entry->serialize =~ /\Q$query/i;
    }

    @found = sort { $b->updated <=> $a->updated } @found;

    if ( req()->header('Accept') =~ /json/ ) {
        return to_json(
            {
                results => [
                    map { { id => $_->id, summary => $_->summary(80) } } @found
                ],
            }
        );
    }
    else {
        if ( @found == 1 ) {
            return Beagle::Web::redirect '/entry/' . $found[0]->id;
        }
        else {
            render 'search',
              title   => 'search',
              results => \@found,
              query   => $query;
        }
    }
};

get '/admin/entries' => sub {
    render 'admin/entries',
      title  => 'admin',
      prefix => $prefix || '../';
};

get '/admin/entry/:type/new' => sub {
    my %vars = @_;
    my $type = lc $vars{'type'};
    if ($type) {
        my $class = entry_type_info->{ lc $type };
        if ( try_load_class($class) ) {

            my $entry = $class->new( id => 'new' );

            return render 'admin/entry',
              entry => $entry,
              form  => Beagle::Web::Form->new(
                field_list => scalar Beagle::Web->field_list($entry) ),
              title  => 'create ' . A($type),
              prefix => $prefix || '../../../';
        }
    }
};

get '/admin/entry/{id:\w{32}}' => sub {
    my %vars = @_;
    my ($id) = $vars{id};

    return Beagle::Web::redirect '/admin/entries' unless bh()->map->{$id};
    render 'admin/entry',
      message => $vars{'message'},
      entry   => bh()->map->{$id},
      form    => Beagle::Web::Form->new(
        field_list => scalar Beagle::Web->field_list( bh()->map->{$id} ) ),
      title  => "update $id",
      prefix => $prefix || '../../';
};

post '/admin/entry/:type/new' => sub {
    my %vars = @_;
    my $type = $vars{'type'};
    if ($type) {
        my $class = 'Beagle::Model::' . ucfirst lc $type;
        if ( try_load_class($class) ) {
            my $entry = $class->new( timezone => bh()->info->timezone );
            if ( $entry->can('author') && !$entry->author ) {
                $entry->author(
                    Email::Address->new( bh()->info->name, bh()->info->email )
                      ->format );
            }

            if ( $type eq 'comment' && !req()->param('format') ) {

                # make comment's format be plain by default if from web ui
                $entry->format('plain');
            }

            if ( process_fields( $entry, req()->parameters->mixed ) ) {
                my ($created) =
                  bh()->create_entry( $entry, message => $vars{message}, );

                if ($created) {
                    add_attachments( $entry, req()->upload('attachments') );
                    if ( req()->header('Accept') =~ /json/ ) {
                        my $ret = {
                            status    => 'created',
                            parent_id => $entry->parent_id,
                            content =>
                              render( 'entry', entry => $entry ),
                        };
                        return to_json($ret);
                    }

                    if ( $type eq 'comment' ) {
                        return
                            Beagle::Web::redirect '/entry/'
                          . $entry->parent_id
                          . '?message=created' . '#'
                          . $entry->id;
                    }
                    else {
                        return
                            Beagle::Web::redirect '/entry/'
                          . $entry->id
                          . '?message=created';
                    }
                }
                else {
                    if ( req()->header('Accept') =~ /json/ ) {
                        my $ret = {
                            status  => 'error',
                            message => 'failed to create',
                        };
                        return to_json($ret);
                    }
                }
            }
            else {
                return render "admin/entry/$type/new",
                  entry => $entry,
                  form  => Beagle::Web::Form->new(
                    field_list => scalar Beagle::Web->field_list($entry) ),
                  message => 'invalid';
            }
        }
    }

    if ( req()->header('Accept') =~ /json/ ) {
        my $ret = {
            status  => 'error',
            content => "invalid type: $type",
        };
        return to_json($ret);
    }
    else {
        Beagle::Web::redirect '/admin/entries';
    }
};

post '/admin/entry/{id:\w{32}}' => sub {
    my %vars = @_;
    my ($id) = $vars{id};

    if ( my $entry = bh()->map->{$id} ) {

        if ( process_fields( $entry, req()->parameters->mixed ) ) {

            bh()->update_entry( $entry, message => $vars{message} );

            my $del = $vars{'delete-attachments'};
            delete_attachments( $entry, ref $del ? @$del : $del );

            add_attachments( $entry, req()->upload('attachments') );

            render 'admin/entry',
              entry => $entry,
              form  => Beagle::Web::Form->new(
                field_list => scalar Beagle::Web->field_list($entry) ),
              message => 'updated',
              prefix  => $prefix || '../../';
        }
        else {
            render 'admin/entry',
              entry => $entry,
              form  => Beagle::Web::Form->new(
                field_list => scalar Beagle::Web->field_list($entry) ),
              message => 'invalid',
              prefix  => $prefix || '../../';
        }
    }
    else {
        Beagle::Web::redirect '/admin/entries';
    }
};

post '/admin/entry/delete' => sub {
    my $id = req()->param('id');

    if ( my $entry = bh()->map->{$id} ) {
        bh()->delete_entry($entry);
        if ( req()->header('Accept') =~ /json/ ) {
            my $ret = { status => 'deleted' };
            $ret->{redraw_menu} = 1 unless $entry->type eq 'comment';
            return to_json($ret);
        }
    }
    else {
        return to_json {
            status  => 'error',
            message => 'not exist'
        };
    }

    Beagle::Web::redirect '/admin/entries';
};

any '/admin/info' => sub {
    my $entry = bh()->info;
    Beagle::Web::redirect '/admin/entry/' . $entry->id;
};

get '/favicon.ico' => sub {
    if ( bh()->info->avatar && bh()->info->avatar ne '/favicon.ico' ) {
        Beagle::Web::redirect bh()->info->avatar;
    }
    else {
        Beagle::Web::redirect '/system/beagle.png';
    }
};

get '/static/*' => sub {
    my %vars  = @_;
    my @parts = split '/', decode_utf8 $vars{splat}[0];
    my $file  = encode( 'locale_fs', catfile( static_root( bh() ), @parts ) );
    return unless -e $file && -r $file;

    my $res = req()->new_response('200');
    $res->content_type( mime_type($file) );
    $res->body( read_file $file);
    return $res;
};

post '/utility/markitup' => sub {
    my $data = req()->param('data');
    return unless $data;
    my $format = req()->param('format');
    return unless $format;

    my $content;
    if ( $format eq 'wiki' ) {
        $content = parse_wiki($data);
    }
    elsif ( $format eq 'markdown' ) {
        $content = parse_markdown($data);
    }
    render 'markitup',
      content => $content,
      prefix  => $prefix || '../';
};

get '/extra/*' => sub {
    my %vars = @_;
    my $name = decode_utf8 $vars{splat}[0];
    return unless $name;
    return unless Beagle::Web->template_exists("extra/$name");
    render("extra/$name");
};

1;

__END__

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


