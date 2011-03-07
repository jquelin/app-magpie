use 5.012;
use strict;
use warnings;

package App::Magpie::Action::Old::Module;
# ABSTRACT: module that has a newer version available

use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;


# -- public attributes

=attr name

The name of the module.

=attr oldver

The version of the module as currently installed.

=attr newver

The module version, as available on CPAN.

=attr package

The package holding the module.

=cut

has name    => ( ro, isa => "Str", required );
has oldver  => ( ro, isa => "Str" );
has newver  => ( ro, isa => "Str" );
has package => ( ro, isa => "Str" );

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 DESCRIPTION

This class represents an installed Perl module that has a newer version
available on CPAN.

