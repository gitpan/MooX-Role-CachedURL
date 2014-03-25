package
    CPAN::Robots;

use Moo;
with 'MooX::Role::CachedURL';

has '+url' => (default => sub { 'http://www.cpan.org/robots.txt' });

1;
