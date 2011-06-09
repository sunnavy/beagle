package Beagle::Web::Router;
use Beagle::Web;
use Beagle::Handler;
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

my $router = Router::Simple->new();
my $admin  = $router->submapper(
    '/admin',
    {},
    {
        on_match => sub {
            return Beagle::Web->enabled_admin() ? 1 : 0;
        },
    }
);

sub any {
    my $methods;
    $methods = shift if @_ == 3;

    my $pattern = shift;
    my $code    = shift;
    my $dest    = { code => $code };
    my $opt     = { $methods ? ( method => $methods ) : () };

    if ( $pattern =~ s{^/admin(?=/)}{} ) {
        $admin->connect( $pattern, $dest, $opt );
    }
    else {
        $router->connect( $pattern, $dest, $opt, );
    }
}

sub get {
    any( [qw/GET HEAD/], $_[0], $_[1] );
}

sub post {
    any( [qw/POST/], $_[0], $_[1] );
}

my ( $bh, %updated, %bh, $all, $name );
my $root = beagle_root('not die');
my $req;

if ( $ENV{BEAGLE_ALL} || !$root ) {
    $all = beagle_roots();
    for my $n ( keys %$all ) {
        local $Beagle::Util::BEAGLE_ROOT = $all->{$n}{local};
        $bh{$n} =
          Beagle::Handler->new( drafts => Beagle::Web->enabled_admin() );
        if ( $root && $root eq $all->{$n}{local} ) {
            $bh   = $bh{$n};
            $name = $n;
        }
        $router->connect(
            "/$n",
            {
                code => sub {
                    change_handler( name => $n );
                },
            }
        );

    }

    $bh ||= ( values %bh )[0];
    $name ||= $bh->name if $bh;
}
else {
    $bh = Beagle::Handler->new( drafts => Beagle::Web->enabled_admin() );
    $name = $bh->name;
}

use Text::Xslate;
my $xslate = Text::Xslate->new(
    path        => [ catdir( beagle_share_root(), 'views' ) ],
    cache_dir   => File::Spec->tmpdir,
    cache       => 1,
    input_layer => ':utf8',
    function    => {
        substr => sub {
            my ( $content, $number ) = @_;
            $number ||= 40;
            utf8::decode($content);
            if ( length $content > $number ) {
                $content = substr( $content, 0, $number - 4 ) . '...';
            }
            utf8::encode($content);
            return $content;
        },
        length => sub {
            return length shift;
        },
        size => sub {
            my $value = shift;
            return 0 unless $value;
            return 1 unless ref $value;
            if ( ref $value eq 'ARRAY' ) {
                return scalar @$value;
            }
            elsif ( ref $value eq 'HASH' ) {
                my $size = 0;
                for ( keys %$value ) {
                    if ( ref $value->{$_} && ref $value->{$_} eq 'ARRAY' ) {
                        $size += @{ $value->{$_} };
                    }
                    else {
                        $size += 1;
                    }
                }
                return $size;
            }
            return;
        },
        subarr => sub {
            my $value  = shift;
            my $length = shift;
            return $value unless $length;
            if ( scalar @$value <= $length ) {
                return $value;
            }
            else {
                return [ splice @$value, 0, $length ];
            }
        },
        can => sub {
            my ( $obj, $method ) = @_;
            return $obj->can($method);
        },
        split_id => sub {
            join '/', split_id(shift);
        },
        email_name => sub {
            require Email::Address;
            my $value = shift;
            my (@addr) = Email::Address->parse($value);
            if (@addr) {
                join ', ', map { $_->name } @addr;
            }
            else {
                return $value;
            }
        },
        match => sub {
            my $value = shift;
            my $regex = shift;
            return unless defined $value && defined $regex;
            return $value =~ qr/$regex/i;
        },
        _ => sub {
            my @lang = I18N::LangTags::implicate_supers(
                I18N::LangTags::Detect->http_accept_langs(
                    $req->header('Accept-Language')
                )
            );
            my $handle =
              Beagle::I18N->get_handle( @lang );

            $handle->maketext( @_ );
        },
    },
);

sub render {
    my $template = shift;
    my %vars = ( default_options(), @_ );
    return $xslate->render( "$template.tx", \%vars );
}
sub redirect {
    my $location = shift;
    my $code     = shift;
    $req->new_response( $code || 302, [ Location => $location || '/' ] );
}

sub change_handler {
    my %vars = @_;
    my $n    = $vars{name};
    $Beagle::Util::BEAGLE_ROOT = $all->{$n}{local};
    $bh                        = $bh{$n};
    $name                      = $n;
    redirect '/';
}

get '/' => sub {
    my $limit = scalar @{ $bh->entries } - 1;
    $limit = 9 if $limit > 9;
    render 'index', entries => [ @{ $bh->entries }[ 0 .. $limit ] ];
};

get '/fragment/menu' => sub {
    render 'menu';
};

get '/fragment/entry/:id' => sub {
    my %vars = @_;
    my $i    = $vars{id} or return;
    my @ret  = resolve_id( $i, handler => $bh );
    return unless @ret == 1;

    render 'entry', entry => $ret[0]->{entry};
};

get '/tag/:tag' => sub {
    my %vars = @_;
    my $tag  = $vars{tag};

    return redirect '/' unless $tag && Beagle::Web->tags($bh)->{$tag};

    render 'index',
      $tag  => 1,
      title => "tag $tag",
      entries => [ map { $bh->map->{$_} } @{ Beagle::Web->tags($bh)->{$tag} } ];
};

get '/date/{year:[0-9]+}' => sub {
    my %vars = @_;
    my $year = $vars{year};
    return redirect '/'
      unless $year && Beagle::Web->years($bh)->{$year};
    return render 'index',
      entries => [
        map   { $bh->map->{$_} }
          map { @{ Beagle::Web->years($bh)->{$year}{$_} } }
          keys %{ Beagle::Web->years($bh)->{$year} }
      ],
      title => "in $year";
};

get '/date/{year:[0-9]}/{month:[0-9]{2}}' => sub {
    my %vars  = @_;
    my $year  = $vars{year};
    my $month = $vars{month};
    return redirect '/' unless Beagle::Web->years($bh)->{$year}{$month};
    return render 'index',
      entries =>
      [ map { $bh->map->{$_} } @{ Beagle::Web->years($bh)->{$year}{$month} } ],
      title => "in $year/$month";
};

get '/entry/:id' => sub {
    my %vars = @_;
    my $i    = $vars{id};
    my @ret  = resolve_id( $i, handler => $bh );
    return redirect "/" unless @ret == 1;
    my $id = $ret[0]->{id};
    return redirect "/entry/$id" unless $i eq $id;

    my $entry = $ret[0]->{entry};

    if ( $entry->type eq 'comment' ) {
        return redirect '/entry/' . $entry->parent_id . '#' . $entry->id;
    }

    render 'index',
      entries      => [$entry],
      $entry->type => 1,
      title        => $entry->summary(10);
};

get '/about' => sub {
    render 'about', title => 'about';
};

get '/feed' => sub { Beagle::Web->feed($bh)->to_string };

get '/search' => sub {
    render 'search', title => 'search';
};

post '/search' => sub {
    my $query = $req->param('query');
    my @found;
    for my $entry ( @{ $bh->entries } ) {
        push @found, $entry if $entry->serialize =~ /\Q$query/i;
    }

    @found = sort { $b->updated <=> $a->updated } @found;

    if ( $req->header('Accept') =~ /json/ ) {
        return to_json(
            {
                results =>
                  [ map { { id => $_->id, summary => $_->summary } } @found ],
            }
        );
    }
    else {
        if ( @found == 1 ) {
            return redirect '/entry/' . $found[0]->id;
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
    render 'admin/entries', title => 'admin';
};

get '/admin/entry/:type/new' => sub {
    my %vars = @_;
    my $type = lc $vars{'type'};
    if ($type) {
        my $class = 'Beagle::Model::' . ucfirst lc $type;
        if ( try_load_class($class) ) {

            my $entry = $class->new( id => 'new' );

            return render 'admin/entry',
              entry => $entry,
              form  => Beagle::Web::Form->new(
                field_list => scalar Beagle::Web->field_list($entry) ),
              title => 'create ' . A($type);
        }
    }
};

get '/admin/entry/{id:\w{32}}' => sub {
    my %vars = @_;
    my ($id) = $vars{id};

    return redirect '/admin/entries' unless $bh->map->{$id};
    render 'admin/entry',
      message => $vars{'message'},
      entry   => $bh->map->{$id},
      form    => Beagle::Web::Form->new(
        field_list => scalar Beagle::Web->field_list( $bh->map->{$id} ) ),
      title => "update $id";
};

post '/admin/entry/:type/new' => sub {
    my %vars = @_;
    my $type = $vars{'type'};
    if ($type) {
        my $class = 'Beagle::Model::' . ucfirst lc $type;
        if ( try_load_class($class) ) {
            my $entry = $class->new( timezone => $bh->info->timezone );
            if ( $entry->can('author') && !$entry->author ) {
                $entry->author(
                    Email::Address->new( $bh->info->name, $bh->info->email )
                      ->format );
            }

            if ( $type eq 'comment' && !$req->param('format') ) {

                # make comment's format be plain by default if from web ui
                $entry->format('plain');
            }

            if ( process_fields( $entry, $req->parameters->mixed ) ) {
                my ($created) =
                  $bh->create_entry( $entry, message => $vars{message}, );

                if ($created) {
                    add_attachments( $entry, $req->upload('attachments') );
                    if ( $req->header('Accept') =~ /json/ ) {
                        my $ret = {
                            status    => 'created',
                            parent_id => $entry->parent_id,
                            content   => render( 'entry', entry => $entry ),
                        };
                        return to_json($ret);
                    }

                    if ( $type eq 'comment' ) {
                        return
                            redirect '/entry/'
                          . $entry->parent_id
                          . '?message=created' . '#'
                          . $entry->id;
                    }
                    else {
                        return
                            redirect '/entry/'
                          . $entry->id
                          . '?message=created';
                    }
                }
                else {
                    if ( $req->header('Accept') =~ /json/ ) {
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

    if ( $req->header('Accept') =~ /json/ ) {
        my $ret = {
            status  => 'error',
            content => "invalid type: $type",
        };
        return to_json($ret);
    }
    else {
        redirect '/admin/entries';
    }
};

post '/admin/entry/{id:\w{32}}' => sub {
    my %vars = @_;
    my ($id) = $vars{id};

    if ( my $entry = $bh->map->{$id} ) {

        if ( process_fields( $entry, $req->parameters->mixed ) ) {

            $bh->update_entry( $entry, message => $vars{message} );

            my $del = $vars{'delete-attachments'};
            delete_attachments( $entry, ref $del ? @$del : $del );

            add_attachments( $entry, $req->upload('attachments') );

            render 'admin/entry',
              entry => $entry,
              form  => Beagle::Web::Form->new(
                field_list => scalar Beagle::Web->field_list($entry) ),
              message => 'updated';
        }
        else {
            render 'admin/entry',
              entry => $entry,
              form  => Beagle::Web::Form->new(
                field_list => scalar Beagle::Web->field_list($entry) ),
              message => 'invalid';
        }
    }
    else {
        redirect '/admin/entries';
    }
};

post '/admin/entry/delete' => sub {
    my $id = $req->param(id);

    if ( my $entry = $bh->map->{$id} ) {
        $bh->delete_entry($entry);
        if ( $req->header('Accept') =~ /json/ ) {
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

    redirect '/admin/entries';
};

any '/admin/info' => sub {
    my $entry = $bh->info;
    redirect '/admin/entry/' . $entry->id;
};

if ($bh) {
    for my $site ( @{ $bh->sites } ) {
        get "/$site->{name}" => sub {
            redirect $site->{url};
        };
    }
}

get '/favicon.ico' => sub {
    if ( $bh->info->avatar && $bh->info->avatar ne '/favicon.ico' ) {
        redirect $bh->info->avatar;
    }
    else {
        redirect '/system/beagle.png';
    }
};

get '/static/*' => sub {
    my %vars = @_;
    my @parts = split '/', decode_utf8 $vars{splat}[0];
    my $file =
      encode( 'locale_fs', catfile( beagle_static_root($bh), @parts ) );
    return unless -e $file && -r $file;

    my $res = $req->new_response('200');
    $res->content_type( mime_type($file) );
    $res->body( read_file $file);
    return $res;
};

post '/utility/markitup' => sub {
    my $data = $req->param('data');
    return unless $data;
    my $format = $req->param('format');
    return unless $format;

    my $content;
    if ( $format eq 'wiki' ) {
        $content = parse_wiki($data);
    }
    elsif ( $format eq 'markdown' ) {
        $content = parse_markdown($data);
    }
    render 'markitup', content => $content;
};

sub process_fields {
    my ( $entry, $params ) = @_;

    my %fields = Beagle::Web->field_list( $entry );
    for my $field ( keys %$params ) {
        next unless $entry->can($field) && $fields{$field};
        my $new = $params->{$field};
        if ( $field eq 'body' ) {
            $new = $entry->parse_body($new);
        }

        my $old = $entry->serialize_field($field);

        if ( "$new" ne "$old" ) {
            $entry->$field( $entry->parse_field( $field, $new ) );
        }
    }
    return 1;
}

sub delete_attachments {
    my ( $entry, @names ) = @_;
    for my $name (@names) {
        next unless defined $name;
        my $att = Beagle::Model::Attachment->new(
            name      => $name,
            parent_id => $entry->id,
        );
        $bh->delete_attachment($att);
    }
}

sub add_attachments {
    my ( $entry, @attachments ) = @_;
    for my $upload (@attachments) {
        next unless $upload;

        my $basename = decode_utf8 $upload->filename;
        $basename =~ s!\\!/!g;
        $basename =~ s!.*/!!;

        my $att = Beagle::Model::Attachment->new(
            name         => $basename,
            content_file => $upload->tempname,
            parent_id    => $entry->id,
        );
        $bh->create_attachment( $att,
                message => 'added attachment '
              . $basename
              . ' for entry '
              . $entry->id );
    }
}

sub current_handler { $bh }

sub default_options {
    return (
        $bh->list,
        name          => $name,
        enabled_admin => Beagle::Web->enabled_admin(),
        feed          => Beagle::Web->feed($bh),
        years         => Beagle::Web->years($bh),
        tags          => Beagle::Web->tags($bh),
        ( $req->env->{'BEAGLE_NAME'} || $req->header('X-Beagle-Name') )
        ? ()
        : ( roots => $all ),
    );
}

sub handle_request {
    my $env = shift;
    use File::Slurp;
    $req = Beagle::Web::Request->new($env);
    my $n = $req->env->{'BEAGLE_NAME'} || $req->header('X-Beagle-Name');
    if ( $n && $bh{$n} ) {
        $bh   = $bh{$n};
        $name = $n;
    }

    if ( Beagle::Web->enabled_admin() ) {
        $bh->update;
        Beagle::Web->update_years($bh);
        Beagle::Web->update_tags($bh);
        Beagle::Web->update_feed($bh);
    }
    else {
        if ( !$updated{$name} || time - $updated{$name} >= 10 ) {
            $bh->update;
            $updated{$name} = time;
        }
    }

    my $res;

    if ( my $match = $router->match($env) ) {
        if ( my $method = delete $match->{code} ) {
            $ret = $method->(%$match);
            if ( ref $ret && ref $ret eq 'Plack::Response' ) {
                $res = $ret;
            }
            else {
                if ( defined $ret ) {
                    $res = $req->new_response( 200, [], [ encode_utf8 $ret] );
                }
                else {
                    $res = $req->new_response( 403, [], [] );
                }
            }
        }
    }

    $res ||= $req->new_response(405);

    $res->finalize;
}

1;

__END__

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


