package Beagle::Web;
use Beagle;
use Beagle::Util;
use Beagle::Handle;
use Beagle::Web::Request;
use Beagle::I18N;
use I18N::LangTags;
use I18N::LangTags::Detect;
use Data::Page;
use URI::QueryParam;

my %feed;

sub feed {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';

    my $bh   = handle();
    my $name = $bh->name;
    return $feed{$name} if $feed{$name};

    my $backend = $bh->backend;
    my $info    = $bh->info;
    my $entries = $bh->entries;

    require XML::FeedPP;
    my $feed = XML::FeedPP::RSS->new( link => $info->url );
    $feed->copyright( $info->copyright );
    $feed->title( $info->title );
    $feed->description( $info->body );
    $feed->pubDate( $entries->[0]->created ) if @$entries;
    $feed->image( $info->avatar, $info->title, $info->url, $info->body, 80,
        80 );

    my $limit = $ENV{BEAGLE_WEB_FEED_LIMIT} || $info->web_feed_limit() || 20;
    if ( scalar @$entries > $limit ) {
        $entries = [ @{$entries}[ 0 .. $limit-1] ];
    }

    for my $entry ( @$entries ) {
        my $item = $feed->add_item();
        $item->link( $info->url . "/entry/" . $entry->id );
        if ( $entry->can('title') ) {
            $item->title( $entry->title );
        }
        elsif ( $entry->can('summary') ) {
            $item->title( $entry->summary(30) );
        }
        else {
            $item->title( $entry->type );
        }

        $item->description(
              $entry->can('body_html')
            ? $entry->body_html
            : $entry->body
        );

        $item->pubDate( $entry->created );
        $item->author( $entry->author || $info->name . ' (' . $info->email . ')' );
        my $category = $entry->type,;
        if ( $entry->can('tags') ) {
            $category = join ', ', $category, $entry->type,
              from_array( $entry->tags );
        }
        $item->category($category);
    }

    $feed->normalize();
    return $feed{$name} = $feed;
}

sub update_feed {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $bh = shift;
    delete $feed{ $bh->name };
    feed($bh);
}

my %years;
my %tags;

use Storable 'dclone';

sub years {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $bh   = shift;
    my $name = $bh->name;
    return dclone( $years{$name} ) if $years{$name};

    my $years = {};
    for my $entry ( @{ $bh->entries } ) {
        push @{ $years->{ $entry->created_year }{ $entry->created_month } },
          $entry->id;
    }

    $years{$name} = $years;
    return dclone($years);
}

sub update_years {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $bh = shift;
    delete $years{ $bh->name };
    years($bh);
}

sub tags {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $bh   = shift;
    my $name = $bh->name;

    return dclone( $tags{$name} ) if $tags{$name};

    my $tags = {};
    for my $entry ( @{ $bh->entries } ) {
        if ( $entry->can('tags') ) {
            for my $tag ( @{ $entry->tags } ) {
                push @{ $tags->{$tag} }, $entry->id;
            }
        }
        push @{ $tags->{ $entry->type } }, $entry->id;
    }
    $tags{$name} = $tags;
    return dclone($tags);
}

sub update_tags {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $bh = shift;
    delete $tags{ $bh->name };
    tags($bh);
}

sub field_list {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $entry = shift;
    my @list = (
        author => { type => 'text', },
        format => {
            type    => 'select',
            options => [
                map { { label => $_, value => $_ } } qw/plain wiki markdown pod/
            ],
        },
        draft => { type => 'boolean', },
        body  => { type => 'textarea', },
    );

    if ( $type ne 'info' && $type ne 'comment' ) {
        push @list, tags  => { type => 'text', },
    }

    my $type = $entry->type;
    if ( $type ne 'entry' ) {
        my $names = $entry->extra_meta_fields;
        for my $name (@$names) {
            my $attr = $entry->meta->get_attribute($name);
            my $const = $attr->type_constraint;
            if ($const) {
                if ( $const->can('values') ) {
                    push @list, $name => {
                        type    => 'select',
                        options => $const->values,
                    };
                    next;
                }
                elsif ( "$const" eq 'Bool' ) {
                    push @list, $name => { type => 'boolean', };
                    next;
                }
            }
            push @list, $name => { type => 'text', };
        }
    }

    @list = _fill_values( $entry, @list );
    return wantarray ? @list : \@list;
}

sub _fill_values {
    my $entry  = shift;
    my @fields = @_;
    my @filled;
    while (@fields) {
        my $name = shift @fields;
        my $opt  = shift @fields;
        $opt->{default} = $entry->serialize_field($name);
        push @filled, $name, $opt;
    }
    return @filled;
}

use Plack::Builder;

sub app {
    require Beagle::Web::Router;

    builder {
        for my $plugin ( reverse plugins() ) {
            my $root = catdir( share_root($plugin), 'public' );
            if ( -e $root ) {
                enable 'Static',
                  path => sub                          { s!^/system/!! },
                  root => catdir( share_root($plugin), 'public' ),
                  pass_through => 1;
            }
        }

        enable 'Static',
          path => sub                   { s!^/system/!! },
          root => catdir( share_root(), 'public' );

        \&handle_request;
    }
}

sub template_exists {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $name = shift;
    return unless defined $name;
    $name .= '.tx' unless $name =~ /\.tx$/;
    my @roots = web_template_roots();
    my @parts = split /\//, $name;
    for my $root (@roots) {
        return 1 if -e encode( locale_fs => catfile( $root, @parts ) );
    }
    return;
}

my ( $bh, %updated, %bh, $name, $names, $prefix, $static, $router, %xslate );
$prefix = '/';
my $req;

use Text::Xslate;
sub xslate {
    my $n = shift   || $name;
    my $b = $bh{$n} || $bh;
    return $xslate{$n} if $xslate{$n};
    return $xslate{$n} = Text::Xslate->new(
        path =>
          [ map { catdir( $_, $b->info->web_layout ) } web_template_roots() ],
        cache_dir   => catdir( File::Spec->tmpdir, 'beagle_web_cache' ),
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
                return $value =~ qr/$regex/;
            },
            grep => sub {
                my $values = shift;
                my $regex  = shift;
                return unless defined $values && defined $regex;

                my $flag;
                if (@_) {
                    $flag = $_[0];
                }
                else {
                    $flag = 1;
                }

                return [ grep { /$regex/ ? $flag : 0 } @$values ];
            },
            _ => sub {
                my $handle = i18n_handle();
                $handle->maketext(@_);
            },
            template_exists => sub { Beagle::Web->template_exists(@_) },
        },
    );
}

sub init {
    require Beagle::Web::Router;
    $router = Beagle::Web::Router->router;
    for my $plugin ( plugins() ) {
        my $m = $plugin . '::Web::Router';
        if ( load_optional_class($m) ) {
            my $r = $m->router;
            if ($r) {
                unshift @{ $router->{routes} }, @{ $r->{routes} }
                  if $r->{routes};
            }
        }
    }

    my $all = roots();
    if ( web_all() ) {
        $names = [ sort keys %$all ];
    }
    elsif ( web_names() ) {
        $names = [ web_names() ];
    }

    my $root = current_root('not die');
    if ( !$root ) {
        $names = [ sort keys %$all ];
    }

    $names = [ grep { $all->{$_} } @$names ] if $names;

    if ( $names ) {
        if ( @$names == 1 ) {
            $bh = Beagle::Handle->new(
                drafts => web_admin(),
                name   => $names->[0],
            );
            $bh{$names->[0]} = $bh;
            undef $names;
        }
        else {
            for my $n (@$names) {
                $bh{$n} = Beagle::Handle->new(
                    drafts => web_admin(),
                    root   => $all->{$n}{local},
                );
                if ( $root && $root eq $all->{$n}{local} ) {
                    $bh   = $bh{$n};
                    $name = $n;
                }
                $router->connect(
                    "/$n",
                    {
                        code => sub {
                            change_handle( name => $n );
                            redirect('/');
                        },
                    }
                );
            }
            $bh = ( values %bh )[0];
        }

        $name = $bh->name;
    }
    else {
        $bh = Beagle::Handle->new(
            drafts => web_admin(),
            root   => $root,
        );
        $name = $bh->name;
        $bh{$name} = $bh;
    }

    for my $plugin ( plugins() ) {
        my $name;
        if ( $plugin->can('name') ) {
            $name = $plugin->name;
        }

        unless ($name) {
            $name = $plugin;
            $name =~ s!^Beagle::Plugin::!!;
            $name =~ s!::!-!g;
        }

        $name = lc $name;

        if (
            -e catfile( share_root($plugin), 'public', $name, 'css',
                'main.css' ) )
        {
            push @css, join '/', $name, 'css', 'main.css';
        }

        if ( -e catfile( share_root($plugin), 'public', $name, 'js', 'main.js' )
          )
        {
            push @js, join '/', $name, 'js', 'main.js';
        }
    }
}

sub i18n_handle {
    my @lang = I18N::LangTags::implicate_supers(
        I18N::LangTags::Detect->http_accept_langs(
            $req->header('Accept-Language')
        )
    );
    unshift @lang, $bh->info->language if $bh->info->language;
    return Beagle::I18N->get_handle(@lang);
}


sub change_handle {
    my %vars = @_;
    if ( $vars{handle} ) {
        $bh = $vars{handle};
        $name = $bh->name;
        $bh{$name} = $bh;
    }
    elsif ( $vars{name} ) {
        my $n = $vars{name};
        $bh                 = $bh{$n};
        $name               = $n;
    }
    else {
        return;
    }

    return $Beagle::Util::ROOT = $bh->root;
}

sub process_fields {
    my ( $entry, $params ) = @_;

    my %fields = Beagle::Web->field_list($entry);
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

sub handle { $bh }
sub request { $req }

sub set_prefix {
    $prefix = shift;
}

sub set_static {
    $static = shift;
}


sub default_options {
    my $bh = handle();

    return (
        $bh->list,
        name        => $name,
        admin       => web_admin(),
        feed        => Beagle::Web->feed($bh),
        years       => Beagle::Web->years($bh),
        tags        => Beagle::Web->tags($bh),
        entry_types => entry_types(),
        prefix      => $prefix,
        static      => $static,
        css         => \@css,
        js          => \@js,
        ( $req->env->{'BEAGLE_NAME'} || $req->header('X-Beagle-Name') )
        ? ()
        : ( names => $names ),
    );
}

sub render {
    my $template = shift;
    my %vars = ( default_options(), @_ );
    if ( $vars{entries} ) {
        my $limit = $ENV{BEAGLE_WEB_PAGE_LIMIT} || $bh->info->web_page_limit;
        $vars{page} = request()->param('p') || 1;
        my $page = Data::Page->new( scalar @{ $vars{entries} },
            $limit, $vars{page} );
        $vars{entries}   = [ $page->splice( $vars{entries} ) ];

        # page from user may exceed the range
        $vars{page} = $page->current_page;

        my $first = $page->first_page;
        my $last = $page->last_page;

        if ( $first != $last ) {
            my @pages;

            my @before = $first .. $vars{page} - 1;
            if ( @before > 9 ) {
                push @pages, @before[$#before-9 .. $#before ];
                $vars{first_page} = $first;
            }
            else {
                push @pages, @before;
            }

            push @pages, $vars{page};

            my @after = $vars{page} + 1 .. $last;
            if ( @after > 10 ) {
                push @pages, @after[0 .. 9 ];
                $vars{last_page} = $last;
            }
            else {
                push @pages, @after;
            }

            $vars{pages} = [
                map {
                    my $page = $_;
                    my $uri  = request()->uri;
                    $uri->query_param( p => $page );
                    [ $page, $uri->path_query ];
                  } @pages
            ];

            for my $edge (qw/first_page last_page/) {
                next unless $vars{$edge};
                my $uri = request()->uri;
                $uri->query_param( p => $vars{$edge} );
                $vars{$edge} = [ $vars{$edge}, $uri->path_query ];
            }
        }
    }
    return xslate()->render( "$template.tx", \%vars );
}

sub redirect {
    my $location = shift;
    my $code     = shift;
    $req->new_response( $code || 302, [ Location => $location || '/' ] );
}

sub handle_request {
    my $env = shift;
    init() unless $bh;

    $req = Beagle::Web::Request->new($env);

    my $n = $req->env->{'BEAGLE_NAME'} || $req->header('X-Beagle-Name');
    $n = decode_utf8($n) unless Encode::is_utf8($n);

    if ( $names && $n && grep { $n eq $_ } @$names ) {
        $bh   = $bh{$n};
        $name = $n;
    }

    if (   web_admin()
        || !$updated{$name}
        || time - $updated{$name} >= 60 )
    {
        $bh->update;
        update_years($bh);
        update_tags($bh);
        update_feed($bh);
        $updated{$name} = time;
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
                    $res = $req->new_response(
                        200,
                        [ 'Content-Type' => 'text/html' ],
                        [ encode_utf8 $ret]
                    );
                }
                else {
                    $res = $req->new_response( 404, [], [] );
                }
            }
        }
    }

    $res ||= $req->new_response(405);

    $res->finalize;
}

sub prefix { $prefix };

1;

__END__

=head1 NAME

Beagle::Web - web interface of Beagle

=head1 DESCRIPTION

Beagle::Web - web interface of Beagle

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
