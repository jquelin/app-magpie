use 5.012;
use strict;
use warnings;

package App::Magpie::Action::Sort::Package;
# ABSTRACT: package in need of a rebuild

use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use App::Magpie::URPM;


# -- public attributes

=attr name

The name of the package.

=cut

has name => ( ro, isa => "Str", required );


# -- private attributes

=attr provides

The list of provides for the package.

=method nb_provides

    my $nb = $pkg->nb_provides;

Return the number of provides for C<$pkg>.

=method  add_provides

    $pkg->add_provides( @provides );

Add C<@provides> to the list of provides for C<$pkg>.

=cut

has provides => (
    ro, auto_deref,
    isa     => "ArrayRef[Str]",
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        nb_provides  => 'count',
        add_provides => 'push',
    },
);


=method has_no_requires

    my $bool = $pkg->has_no_requires;

Return true if C<$pkg> doesn't have any more requirements.

=method nb_requires

    my $nb = $pkg->nb_requires;

Return the number of C<$pkg> requirements.

=method rm_requires

    $pkg->rm_requires( @reqs );

Remove a given list of requirements for C<$pkg>.

=cut

has _requires => (
    ro,
    isa     => "HashRef[Str]",
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        has_no_requires => 'is_empty',
        nb_requires     => 'count',
        rm_requires     => 'delete',
        _set_requires   => 'set',
    },
);


# -- public methods

=method add_requires

    $pkg->add_requires( @reqs );

Add a given list of requires to C<$pkg>.

=cut

sub add_requires {
    my ($self, @reqs) = @_;
    $self->_set_requires($_=>1) for @reqs;
}


__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 DESCRIPTION

This class represents a package to be rebuild, providing some
requirements and requiring some others.

