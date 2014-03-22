#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 4;
use Test::File;
use MooX::Role::CachedURL;

{
    package
        CPAN::Robots;

    use Moo;
    with 'MooX::Role::CachedURL';

    has '+url' => (default => sub { 'http://www.cpan.org/robots.txt' });
}

package main;

use CPAN::Robots;

my $robots;

eval { $robots = CPAN::Robots->new() };

SKIP: {
    skip("looks like you're offline", 4) if $@ && $@ =~ /failed to mirror/;

    file_exists_ok($robots->path, "Did the file get cached locally?");
    file_contains_like($robots->path, qr/Hello Robots/ms, "Does it contain expected content?");
    ok(unlink($robots->path), "Remove the file we just cached");
    file_not_exists_ok($robots->path, "So the file shouldn't be there now");
}

