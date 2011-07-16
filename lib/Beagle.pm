package Beagle;
our $VERSION = '0.01';

1;

__END__

=head1 NAME

Beagle - a modern way to manage/track/serve posts

=head1 SYNOPSIS

    $ beagle help
    $ beagle config --init
    $ beagle init /path/to/foo.git  --bare

    # if you already have one, you can follow it
    $ beagle follow /path/to/foo.git

    $ beagle article --title foo --body bar
    $ beagle ls
    $ beagle show ID1
    $ beagle update ID1
    $ beagle rm ID1
    $ beagle shell

    $ beagle pull
    $ beagle push

    $ beagle web

=head1 DESCRIPTION

Technically, it's a thin wrapper of git(maybe more vcs in the future), which
uses it as data source to manage/track/serve all kinds of entries( articles,
review, etc ).

=head1 SEE ALSO

L<Beagle::Manual::Tutorial>

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


