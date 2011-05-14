package Beagle::Handler;
use Any::Moose;
use Lingua::EN::Inflect 'PL';

my @models;

BEGIN {
    require Class::Load;
    require Module::Pluggable::Object;
    my $models =
      Module::Pluggable::Object->new( search_path => 'Beagle::Model', );
    @models = $models->plugins;
    for my $m (@models) {
        Class::Load::load_class($m);
    }
}

use Beagle::Backend;
use Beagle::Util;
use File::Path 'make_path';

has 'name' => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    default => sub { root_name( $_[0]->root ) },
);

has 'drafts' => (
    isa     => 'Bool',
    is      => 'ro',
    lazy    => 1,
    default => 1,
);

has 'backend' => (
    isa     => 'Beagle::Backend::base',
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $root = beagle_root();
        return Beagle::Backend->new( root => $root, type => root_type($root) );
    },
    handles => [qw/type root/],
);

has 'cache' => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $name = cache_name($self->name);
        return catfile( beagle_home_cache,
            $name . ( $self->drafts ? '.drafts' : '' ) );
    },
);

has 'info' => (
    isa     => 'Beagle::Model::Info',
    is      => 'rw',
    handles => ['sites'],
);

my %entry_info;
for my $model (@models) {
    next if $model =~ /^Beagle::Model::(?:Info|Attachment|Entry)$/;
    next unless $model =~ /^Beagle::Model::(\w+)$/;
    my $type = lc $1;
    my $pl   = PL($type);
    $entry_info{$pl} = { class => $model, type => $type };

    has $pl => (
        isa     => "ArrayRef[$model]",
        is      => 'rw',
        default => sub { [] },
        $type ne 'comment'
        ? (
            trigger => sub {
                my $self = shift;
                $self->init_entries;
            }
          )
        : (),
    );
}

sub entry_info { return { %entry_info } }

has 'entries' => (
    isa     => 'ArrayRef[Beagle::Model::Entry]',
    is      => 'rw',
    default => sub { [] },
);

has 'map' => (
    isa     => 'HashRef[Beagle::Model::Entry]',
    is      => 'rw',
    default => sub { {} },
    lazy    => 1,
);

has 'attachments_map' => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { {} },
    lazy    => 1,
);

has 'comments_map' => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { {} },
    lazy    => 1,
);

has 'updated' => (
    isa     => 'Int',
    is      => 'rw',
    default => 0,
);

sub BUILD {
    my $self = shift;
    my $args = shift;

    if ( $args->{root} || $args->{name} ) {
        my $root = $args->{root} || name_root( $args->{name} );
        $self->backend(
            Beagle::Backend->new(
                root => $root,
                type => $args->{type} || root_type($root),
            )
        );
        $self->name( root_name($root) );
    }

    my $cache       = $self->cache;
    my $need_update = 1;

    if ( enabled_cache() && -e $cache ) {
        require Storable;
        %$self = %{ Storable::retrieve($cache) };
        $self->root( $args->{root} )
          if $args->{root} && ( $self->root || '' ) ne $args->{root};

        if ( ( $self->updated || 0 ) == ( $self->backend->updated || 0 ) ) {
            undef $need_update;
        }

        return $self unless $need_update;
    }

    if ($need_update) {

        $self->map( {} );
        $self->init_info;
        for my $attr ( keys %{ $self->entry_info } ) {
            my $method = "init_$attr";
            if ( $self->can($method) ) {
                $self->$method;
            }
            else {
                $self->init_entry_attr($attr);
            }
        }

        $self->init_attachments;

        my $updated = $self->backend->updated;
        $self->updated($updated) if $updated;
        $self->update_cache if enabled_cache();
        $self->update_global_map;
    }

    return $self;
}

sub update_cache {
    my $self = shift;
    return unless enabled_cache();

    unless ( -e $self->cache ) {
        my $parent = parent_dir( $self->cache );
        make_path($parent) or die $! unless -e $parent;
    }

    require Storable;
    Storable::nstore( $self, $self->cache );
}

sub update_global_map {
    my $self = shift;
    my $map  = entry_map();
    for my $key ( keys %$map ) {
        delete $map->{$key}
          if $map->{$key} eq $self->name;
    }
    for my $entry ( @{ $self->comments }, @{ $self->entries } ) {
        $map->{ $entry->id } = $self->name;
    }
    set_entry_map($map);
}

sub init_info {
    my $self    = shift;
    my $backend = $self->backend;
    ( undef, my $string ) = $backend->read( path => 'info' );
    my $info = Beagle::Model::Info->new_from_string(
        $string,
        root => $self->root,
        path => 'info'
    );
    $self->info($info);
    $self->map->{ $info->id } = $info;
}

sub init_entry_attr {
    my $self    = shift;
    my $attr    = shift;
    my $backend = $self->backend;
    {
        my %all = $backend->read( type => $self->entry_info->{$attr}{type} );
        my @entries;
        for my $path ( keys %all ) {
            my $class = $self->entry_info->{$attr}{class};

            my $entry = $class->new_from_string(
                $all{$path},
                root     => $self->root,
                path     => $path,
                timezone => $self->info->timezone || 'UTC',
            );
            next if $entry->draft && !$self->drafts;

            $entry->author(
                Email::Address->new( $self->info->name, $self->info->email )
                  ->format )
              unless $entry->author;

            push @entries, $entry;
            $self->map->{ $entry->id } = $entry;
        }

        @entries =
          sort { $b->created <=> $a->created } @entries;
        $self->$attr( \@entries );
    }
}

sub init_attachments {
    my $self            = shift;
    my $backend         = $self->backend;
    my %attachments_map = ();
    my %all             = $backend->read( type => 'attachment' );
    for my $id ( keys %all ) {
        $attachments_map{$id} = {
            map {
                $_ => Beagle::Model::Attachment->new(
                    name      => $_,
                    parent_id => $id,
                    root      => $self->root,
                  )
              } @{ $all{$id} }
        };
    }
    $self->attachments_map( \%attachments_map );
}

sub init_comments {
    my $self    = shift;
    my $backend = $self->backend;
    my %map     = ();
    my %all     = $backend->read( type => 'comment' );
    my @comments;
    for my $parent_id ( keys %all ) {
        my $info = $all{$parent_id};
        for my $path ( keys %$info ) {
            my $class = "Beagle::Model::Comment";

            my $comment = $class->new_from_string(
                $info->{$path},
                root      => $self->root,
                parent_id => $parent_id,
                path      => $path,
                timezone  => $self->info->timezone || 'UTC',
            );
            next if $comment->draft && !$self->drafts;

            $comment->author(
                Email::Address->new( $self->info->name, $self->info->email )
                  ->format )
              unless $comment->author;

            push @comments, $comment;
            $self->map->{ $comment->id } = $comment;
            $map{$parent_id}{ $comment->id } = $comment;
        }
    }
    @comments =
      sort { $b->created <=> $a->created } @comments;

    $self->comments( \@comments );
    $self->comments_map( \%map );
}

sub total_size {
    my $self = shift;
    require Devel::Size;
    return Devel::Size::total_size($self);
}

sub list {
    my $self = shift;

    my %ret;

    return map { $_ => $self->$_ } qw/info total_size sites
      entries map attachments_map comments_map updated entry_info
      /, keys %{ $self->entry_info };
}

sub update_info {
    my $self = shift;
    my $info = shift;
    return unless $self->backend->update( $info, @_ );
    $self->info($info);
    return 1;
}

sub update {
    my $self    = shift;
    my $updated = $self->backend->updated || 0;
    my $map     = $self->map;

    if ( $self->updated != $updated ) {
        $self->map( {} );
        $self->init_info;
        for my $attr ( keys %{ $self->entry_info } ) {
            my $method = "init_$attr";
            if ( $self->can($method) ) {
                $self->$method;
            }
            else {
                $self->init_entry_attr($attr);
            }
        }

        $self->init_attachments;
        $self->updated($updated);
    }
}

sub create_entry {
    my $self   = shift;
    my $entry  = shift;
    my $type   = $entry->type;
    my $method = "create_$type";
    if ( $self->can($method) ) {
        return $self->$method( $entry, @_ );
    }
    else {
        return unless $self->backend->create( $entry, @_ );
        $self->map->{ $entry->id } = $entry;
        if ( $type eq 'comment' ) {
            $self->comments( [ $entry, @{ $self->comments } ] );
            $self->comments_map->{ $entry->parent_id }{ $entry->id } = $entry;
        }
        else {
            my $attr = PL($type);
            $self->$attr( [ $entry, @{ $self->$attr } ] );
        }
    }
    return 1;
}

sub update_entry {
    my $self   = shift;
    my $entry  = shift;
    my $type   = $entry->type;
    my $method = "create_$type";
    if ( $self->can($method) ) {
        return $self->$method( $entry, @_ );
    }
    else {
        return unless $self->backend->update( $entry, @_ );
        if ( $type eq 'comment' ) {
            $self->comments(
                [
                    map { $_->id eq $entry->id ? $entry : $_ }
                      @{ $self->comments }
                ]
            );
            $self->comments_map->{ $entry->parent_id }{ $entry->id } = $entry;
        }
        else {
            my $attr = PL($type);
            $self->$attr(
                [
                    map { $_->id eq $entry->id ? $entry : $_ } @{ $self->$attr }
                ]
            );
        }
    }
    return 1;
}

sub delete_entry {
    my $self   = shift;
    my $entry  = shift;
    my $type   = $entry->type;
    my $method = "delete_$type";
    if ( $self->can($method) ) {
        return $self->$method( $entry, @_ );
    }
    else {
        return unless $self->backend->delete( $entry, @_ );
        delete $self->map->{ $entry->id };
        if ( my $att = $self->attachments_map->{ $entry->id } ) {
            $self->delete_attachment($_)
              or warn "failed to delete attachment " . $_->id
              for values %$att;
        }
        if ( my $comment = $self->comments_map->{ $entry->id } ) {
            $self->delete_entry($_)
              or warn "failed to delete comment " . $_->id
              for values %$comment;
        }

        if ( $entry->type eq 'comment' ) {
            delete $self->comments_map->{ $entry->parent_id }{ $entry->id };
        }
    }
    return 1;
}

sub create_attachment {
    my $self       = shift;
    my $attachment = shift;
    return unless $self->backend->create( $attachment, @_ );
    $self->attachments_map->{ $attachment->parent_id }{ $attachment->name } =
      $attachment;
    return 1;
}

sub delete_attachment {
    my $self       = shift;
    my $attachment = shift;
    return unless $self->backend->delete( $attachment, @_ );
    delete $self->attachments_map->{ $attachment->parent_id }
      { $attachment->name };
    return 1;
}

sub init_entries {
    my $self = shift;
    my @entries =
      sort { $b->created <=> $a->created }
      map  { @{ $self->$_ } } grep { $_ ne 'comments' }  keys %{ $self->entry_info };
    $self->entries( \@entries );
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 AUTHOR

    sunnavy  C<< sunnavy@gmail.com >>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

