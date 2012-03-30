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

package App::Magpie::Action::DWIM;
{
  $App::Magpie::Action::DWIM::VERSION = '1.120900';
}
# ABSTRACT: dwim command implementation

use File::pushd;
use List::MoreUtils qw{ each_array };
use Moose;
use Proc::ParallelLoop;

use App::Magpie::Action::Checkout;
use App::Magpie::Action::Old;
use App::Magpie::Action::Update;

with 'App::Magpie::Role::Logging';



sub run {
    my ($self, $directory) = @_;
    
    my @sets = App::Magpie::Action::Old->new->run;
    my ($normal) = grep { $_->name eq "normal" } @sets;
    if ( not defined $normal ) {
        $self->log( "no package to update" );
        return;
    }
    my @modules = $normal->all_modules;

    # loop around the modules
    my @status = pareach [ @modules ], sub {
        my $module = shift;
        my $pkg = ( $module->packages )[0];
        $self->log( "updating " . $module->name
            . " from " .  $module->oldver
            . " to "   . $module->newver
            . " in "   . $pkg->name );

        # check out the package
        my $pkgdir = App::Magpie::Action::Checkout->new->run( $pkg->name, $directory );
        my $old = pushd( $pkgdir );

        # update the package
        eval { App::Magpie::Action::Update->new->run; };
        exit ( $@ ? 1 : 0 );
    }, { Max_Workers => 5 };

    my $ea = each_array(@modules, @status);
    while ( my ($m, $s) = $ea->() ) {
        next if $s == 0;
        my $pkg = ( $m->packages )[0];
        $self->log( "error while updating: " . $pkg->name );
    }
}



1;


=pod

=head1 NAME

App::Magpie::Action::DWIM - dwim command implementation

=head1 VERSION

version 1.120900

=head1 SYNOPSIS

    my $old = App::Magpie::Action::Old->new;
    my @old = $old->run;

=head1 DESCRIPTION

This module implements the C<old> action. It's in a module of its own
to be able to be C<require>-d without loading all other actions.

=head1 METHODS

=head2 run

    $dwim->run;

Update Mageia packages of Perl modules with a new version available on
CPAN.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

