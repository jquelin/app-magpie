use 5.012;
use strict;
use warnings;

package App::Magpie::Action::Old::Set;
# ABSTRACT: a set of AM::Old::Modules objects

use Moose;
use MooseX::Has::Sugar;


# -- public attributes

=attr name

The name of the set.

=cut

has name     => ( ro, isa=>"Str", required );

=method all_modules

    my @modules = $set->all_modules;

Return all the modules currently in the C<$set>.

=method add_module

    $set->add_module( $module );

Add C<$module> to the C<$set>.

=method nb_modules

    my $nb = $set->nb_modules;

Return the number of modules the set is holding.

=cut

has _modules => (
    ro,
    traits  => ['Array'],
    isa     => 'ArrayRef[App::Magpie::Action::Old::Module]',
    default => sub { [] },
    handles => {
        all_modules    => 'elements',
        add_module     => 'push',
        nb_modules     => 'count',
    },
);

#--

=method nb_packages

    my $nb = $set->nb_packages;

Return the nimber of Mageia packages the set is holding.

=cut

sub nb_packages {
    my $self = shift;
    my %seen;
    @seen{
        map { $_->packages->[0] }
        $self->all_modules
    }++;
    return scalar keys %seen;
}


1;
__END__

=head1 SYNOPSIS

This class holds a set of modules that have been updated on CPAN. There
can be multiple sets - eg: core, dual, ...

