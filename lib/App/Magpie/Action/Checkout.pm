use 5.012;
use strict;
use warnings;

package App::Magpie::Action::Checkout;
# ABSTRACT: checkout command implementation

use Moose;
use Path::Class;

with 'App::Magpie::Role::Logging';
with 'App::Magpie::Role::RunningCommand';


=method run

    my $pkgdir = $checkout->run( $pkg [, $directory] );

Check out C<$pkg> under C<$directory> (or current directory if no
directory specified). Refresh the checkout if it already exists.

Return the directory in which the checkout is located.

=cut

sub run {
    my ($self, $pkg, $directory) = @_;

    # check out the package, or update the local checkout
    my $dir    = defined($directory) ? dir( $directory ) : dir();
    my $pkgdir = $dir->subdir( $pkg );
    $dir->mkpath unless -d $dir;
    $self->log( "checking out $pkg in $pkgdir" );

    if ( -d $pkgdir ) {
        $self->log( "package already checked out, refreshing checkout");
        chdir $pkgdir;
        $self->run_command( "mgarepo up" );
    } else {
        chdir $dir;
        $self->run_command( "mgarepo co $pkg" );
    }

    return $pkgdir;
}



1;
__END__

=head1 SYNOPSIS

    my $checkout = App::Magpie::Action::Checkout->new;
    $checkout->run( $pkg );


=head1 DESCRIPTION

This module implements the C<checkout> action. It's in a module of its
own to be able to be C<require>-d without loading all other actions.

