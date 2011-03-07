use 5.012;
use strict;
use warnings;

package App::Magpie::Action::Old;
# ABSTRACT: old command implementation

use Moose;

with 'App::Magpie::Role::Logging';


=method run

    my @old = $old->run;

Return the list of Perl modules with a new version available on CPAN.

=cut

sub run {
    my ($self) = @_;
}



1;
__END__

=head1 SYNOPSIS

    my $old = App::Magpie::Action::Old->new;
    $old->run;


=head1 DESCRIPTION

This module implements the C<old> action. It's in a module of its own
to be able to be C<require>-d without loading all other actions.

