package MooX::Role::CachedURL;
$MooX::Role::CachedURL::VERSION = '0.05';
use 5.006;
use Moo::Role;
use File::HomeDir;
use File::Spec::Functions 'catfile';
use HTTP::Tiny;
use Time::Duration::Parse qw/ parse_duration /;
use Carp;

has 'url'           => (is => 'ro');
has 'path'          => (is => 'ro');
has 'cache_path'    => (is => 'rw');
has 'max_age'       => (is => 'ro');

sub BUILD
{
    my $self = shift;

    if ($self->path) {
        return if -f $self->path;
        croak "the file you specified with 'path' doesn't exist";
    }

    # If constructor didn't specify a local file, then mirror the file
    if (not $self->cache_path) {
        my $basename = $self->url;
           $basename =~ s!^.*[/\\]!!;

        my $classid  = ref($self);
           $classid  =~ s/::/-/g;

        $self->cache_path( catfile(File::HomeDir->my_dist_data( $classid, { create => 1 } ), $basename) );
    }

    if (-f $self->cache_path && defined($self->max_age)) {
        my $max_age_in_seconds = parse_duration($self->max_age);
        return unless time() - $max_age_in_seconds > (stat($self->cache_path))[9];
    }

    my $response;
    eval { $response = HTTP::Tiny->new()->mirror($self->url, $self->cache_path) };
    if (not $response->{success}) {
        croak "failed to mirror @{[ $self->url ]}: $response->{status} $response->{reason}";
    }

}

sub open_file
{
    my $self     = shift;

    my $layers   = ':encoding(UTF-8)';
    my $filename = defined($self->path)
                   ? $self->path
                   : $self->cache_path;

    if ($filename =~ /\.gz\z/) {
        require PerlIO::gzip;
        $layers = ':gzip'.$layers;
    }

    open(my $fh, '<'.$layers, $filename)
        || croak "can't open $filename: $!";

    return $fh;
}

sub close_file
{
    my $self = shift;
    my $fh   = shift;

    close($fh);
}

1;

=head1 NAME

MooX::Role::CachedURL - a role providing a locally cached copy of a remote file

=head1 SYNOPSIS

 package MyClass;
 use Moo;
 with 'MooX::Role::CachedURL';
 has '+url' => (default => sub { 'http://www.cpan.org/robots.txt' });
 
 sub my_method {
    my $self = shift;
    my $fh   = $self->open_file;
 
    while (<$fh>) {
        ...
    }
    $self->close_file($fh);
 }

Then in the user of MyClass:

 use MyClass;
 my $object = MyClass->new(max_age => '2 days');
  
 print "local file is ", $object->cache_path, "\n";

=head1 DESCRIPTION

This role represents a remote file that you want to cache locally,
and then process.
This is common functionality that I'm pulling out of my L<PAUSE::Users>,
L<PAUSE::Permissions> and L<PAUSE::Packages> modules.

PAUSE::Users provides a simple interface to the C<00whois.xml> file
that is generated by PAUSE.
It caches the file locally,
then provides a mechanism for iterating over all users in the file.

=head1 ATTRIBUTES

=head2 cache_path

The full path to the local file where the content of the remote URL
will be cached. You can provide your own path, but if you don't,
then an appropriate path for your operating system will be generated.

=head2 path

A full or relative path to your own copy of the cached content.
If you provide this, then your content will be used,
without checking the remote URL.
If the file you pass doesn't exist, the module will C<croak()>.

=head2 url

This specifies the URL that should be cached locally.
It should be over-ridden in the composing class, as shown in the SYNOPSIS above.

=head2 max_age

Specifies the maximum age of the local copy, in seconds.
We won't even look for a new remote copy if the cached copy is younger than this.

You can specify max_age using any of the notations supported by L<Time::Duration::Parse>.
For example:

 max_age => '2 hours',

=head1 Support for gzip'd files

If the C<cache_path> or C<path> attribute ends in C<.gz>,
then the file is assumed to be gzip'd, and will be transparently handled
using L<PerlIO::gzip>.

=head1 TODO

=over 4

=item * Switch to LWP for general URL handling, not just HTTP

=item * Ability for a class to transform content when caching

=back

=head1 REPOSITORY

L<https://github.com/neilbowers/MooX-Role-CachedURL>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
