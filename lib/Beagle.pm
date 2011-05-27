package Beagle;
our $VERSION = '0.01';

1;

__END__

=head1 NAME

Beagle - manage/version/spread articles, reviews, barks, etc.

=head1 SYNOPSIS

    $ beagle config --init # give it your name and email
    $ beagle create --name foo

    # if you already have one, you can follow it
    $ beagle follow git_repo_uri --name foo

    $ beagle help
    $ beagle ls # show/search entries
    $ beagle show id1 # show id1
    $ beagle update id1 # update id1
    $ beagle rm id1 # delete id1
    $ beagle shell # beagle shell

=head1 DESCRIPTION

Beagle is your assistant to help you track your own or other people's
articles, reviews, barks and tasks, etc.

Technically, it's a thin wrapper of git(maybe more vcs in the future),
which uses git as data source to create/show/update/delete/publish all
kinds of entries( articles, review, etc ).

=head1 AUTHOR

sunnavy  <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


