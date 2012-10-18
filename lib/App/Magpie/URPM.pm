use 5.012;
use strict;
use warnings;

package App::Magpie::URPM;
# ABSTRACT: magpie interface to L<URPM>

use MooseX::Singleton;
use MooseX::Has::Sugar;
use URPM;

with "App::Magpie::Role::Logging";


# -- private attributes

has _urpm => ( ro, isa=>"URPM", lazy_build );

sub _build__urpm {
    my ($self) = @_;

    my $urpm = URPM->new;
    my @hdlists = glob "/var/lib/urpmi/*/synthesis.hdlist.cz";

    foreach my $hdlist ( @hdlists ) {
        $self->log_debug( "parsing $hdlist" );
        $urpm->parse_synthesis( $hdlist );
    }

    return $urpm;
}

# -- public methods

=method packages_providing

    my @pkgs = $urpm->packages_providing( $module );

Return the list of Mageia packages providing a given Perl C<$module>.

=cut

sub packages_providing {
    my ($self, $module) = @_;
    return $self->_urpm->packages_providing("perl($module)");
}

1;
__END__

=head1 SYNOPSIS

    my $urpm = App::Magpie::URPM->instance;


=head1 DESCRIPTION

This module is a wrapper around URPM, and allows to query it for Perl
modules requires & provides.

