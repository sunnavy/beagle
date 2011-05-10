package Beagle::Web;
use Beagle;
use Beagle::Util;
use Encode;

our $VERSION = '0.01';

sub share_root {
    my @root =
      splitdir( rel2abs( parent_dir( $INC{'Beagle.pm'} ) ) );

    if (   $root[-2] ne 'blib'
        && $root[-1] eq 'lib'
        && ( $^O !~ /MSWin/ || $root[-2] ne 'site' ) )
    {

        # so it's -Ilib in the Beagle's source dir
        $root[-1] = 'share';
    }
    else {
        push @root, qw/auto share dist Beagle/;
    }

    return catdir(@root);
}

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

    my $limit = scalar @{$entries} - 1;
    $limit = 19 if $limit > 19;
    for my $entry ( @{$entries}[ 0 .. $limit ] ) {
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
    return dclone($years{$name}) if $years{$name};

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

    return dclone($tags{$name}) if $tags{$name};

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
    my @list  = (
        author => { type => 'Text', },
        format => {
            type => 'Select',
            options =>
              [ map { { label => $_, value => $_ } } qw/plain wiki markdown/ ],
        },
        draft => { type => 'Boolean', },
        body  => {
            type  => 'TextArea',
            apply => [
                {
                    check => sub {
                        length $_[0]
                          && $_[0] =~ /\S/
                          && length $_[0] <= 1000;
                    },
                }
            ],
        },
    );

    my $type = $entry->type;
    if ( $type eq 'article' ) {
        unshift @list,
          title => { type => 'Text', },
          tags  => { type => 'Text', };
    }
    elsif ( $type eq 'review' ) {
        unshift @list,
          title => { type => 'Text', },
          tags  => { type => 'Text', };
        push @list,
          map { $_ => { type => 'Text' } }
          qw/isbn writer translator publisher published place/;
    }
    elsif ( $type eq 'comment' ) {
        unshift @list, map { $_ => { type => 'Text' } } qw/author parent_id/;
    }
    elsif ( $type eq 'info' ) {
        unshift @list,
          map { $_ => { type => 'Text' } }
          qw/title url copyright timezone style sites
          name email career location avatar public_key/;
    }

    @list = _fill_values($entry, @list);
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

1;

__END__

=head1 NAME

Beagle::Web - web interface of Beagle

=head1 DESCRIPTION

Beagle::Web - web interface of Beagle

=head1 AUTHOR

sunnavy  C<< sunnavy@gmail.com >>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.