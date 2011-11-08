#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::Action::Checkout;
{
  $App::Magpie::Action::Checkout::VERSION = '1.113123';
}
# ABSTRACT: checkout command implementation

use File::pushd;
use Moose;
use Path::Class;

with 'App::Magpie::Role::Logging';
with 'App::Magpie::Role::RunningCommand';



sub run {
    my ($self, $pkg, $directory) = @_;

    # check out the package, or update the local checkout
    my $dir    = defined($directory) ? dir( $directory ) : dir();
    my $pkgdir = $dir->subdir( $pkg );
    $dir->mkpath unless -d $dir;
    $self->log( "checking out $pkg in $pkgdir" );

    if ( -d $pkgdir ) {
        $self->log( "package already checked out, refreshing checkout");
        my $old = pushd( $pkgdir );
        $self->run_command( "mgarepo up" );
    } else {
        my $old = pushd( $dir );
        $self->run_command( "mgarepo co $pkg" );
    }

    return $pkgdir;
}



1;


=pod

=head1 NAME

App::Magpie::Action::Checkout - checkout command implementation

=head1 VERSION

version 1.113123

=head1 SYNOPSIS

    my $checkout = App::Magpie::Action::Checkout->new;
    $checkout->run( $pkg );

=head1 DESCRIPTION

This module implements the C<checkout> action. It's in a module of its
own to be able to be C<require>-d without loading all other actions.

=head1 METHODS

=head2 run

    my $pkgdir = $checkout->run( $pkg [, $directory] );

Check out C<$pkg> under C<$directory> (or current directory if no
directory specified). Refresh the checkout if it already exists.

Return the directory in which the checkout is located.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

