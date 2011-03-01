use 5.012;
use strict;
use warnings;

package App::Magpie::URPM;
# ABSTRACT: magpie interface to urpm

use MooseX::Singleton;
use MooseX::Has::Sugar;
use URPM;


# -- private attributes

has _urpm => ( ro, isa=>"URPM", lazy_build );

sub _build__urpm {
    my $urpm = URPM->new;
    $urpm->parse_synthesis($_) for glob "/var/lib/urpmi/*/synthesis.hdlist.cz";
    return $urpm;
}


1;
__END__

=head1 SYNOPSIS

    my $urpm = App::Magpie::URPM->instance;


=head1 DESCRIPTION

This module is a wrapper around URPM, and allows to query it for Perl
modules requires & provides.

