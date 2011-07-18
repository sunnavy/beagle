package Beagle::Web;
use Beagle;
use Beagle::Util;
use Encode;

sub enabled_admin {

    return
      defined $ENV{BEAGLE_WEB_ADMIN} && length $ENV{BEAGLE_WEB_ADMIN}
      ? ( $ENV{BEAGLE_WEB_ADMIN} ? 1 : 0 )
      : ( core_config()->{web_admin} ? 1 : 0 );
}

my %feed;

sub feed {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';

    my $bh   = shift;
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

    my $limit = scalar @{$entries};
    my $max = feed_max();
    $limit = $max if $limit > $max;

    for my $entry ( @{$entries}[ 0 .. $limit-1 ] ) {
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
        $item->author( $info->name . ' (' . $info->email . ')' );
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

        \&Beagle::Web::Router::handle_request;
    }
}

sub home_max {
    return $ENV{BEAGLE_WEB_HOME_MAX} || core_config->{web_home_max} || 10;
}

sub feed_max {
    return $ENV{BEAGLE_WEB_FEED_MAX} || core_config->{web_feed_max} || 20;
}

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
