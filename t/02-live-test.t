#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 4;
use Test::File;
use MooX::Role::CachedURL;

use lib qw(t/lib);
use CPAN::Robots;


my $robots;

eval { $robots = CPAN::Robots->new() };

SKIP: {
    skip("looks like you're offline", 4) if $@ && $@ =~ /failed to mirror/;

    file_exists_ok($robots->cache_path, "Did the file get cached locally?");
    file_contains_like($robots->cache_path, qr/Hello Robots/ms, "Does it contain expected content?");
    ok(unlink($robots->cache_path), "Remove the file we just cached");
    file_not_exists_ok($robots->cache_path, "So the file shouldn't be there now");
}

