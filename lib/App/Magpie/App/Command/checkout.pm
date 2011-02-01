use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command::checkout;
# ABSTRACT: check-out or update a given package

use Path::Class;

use App::Magpie::App -command;


# -- public methods

sub command_names { qw{ checkout co }; }

sub description {
"Check out a package from Mageia repository, or update the local
check-out if it already exists."
}

sub opt_spec {
    my $self = shift;
    return (
        [],
        [ 'directory|d=s' => "directory where to check out", { default => "." } ],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;

    # fetch package to be checked out
    my $pkg = shift @$args;
    $self->usage_error( "A package should be specified." )
        unless defined $pkg;

    my $dir    = dir( $opts->{directory} );
    my $pkgdir = $dir->subdir( $pkg );
    $dir->mkpath unless -d $dir;

    if ( -d $pkgdir ) {
        chdir $pkgdir;
        system "mgarepo up >&2";
    } else {
        chdir $dir;
        system "mgarepo co $pkg >&2";
        chdir $pkgdir;
    }

}

1;
__END__


=head1 SYNOPSIS

    $ magpie checkout perl-Foo-Bar
    $ magpie checkout -d ~/rpm/cauldron perl-Foo-Bar

    # to get list of available options
    $ magpie help checkout

=head1 DESCRIPTION

This command will check out a package from Mageia repository, or update
a local check-out if it already exists.

It uses the C<mgarepo> command underneath, so you might want to look at
this command for more information.
