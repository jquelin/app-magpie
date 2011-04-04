use 5.012;
use strict;
use warnings;

package App::Magpie::Action::DWIM;
# ABSTRACT: dwim command implementation

use Moose;

use App::Magpie::Action::Old;

with 'App::Magpie::Role::Logging';


=method run

    $dwim->run;

Update Mageia packages of Perl modules with a new version available on
CPAN.

=cut

sub run {
    my ($self) = @_;
    
    my ($set) =
        grep { $_->name eq "normal" }
        App::Magpie::Action::Old->new->run;

    foreach my $module ( sort $set->all_modules ) {
        my $pkg = ( $module->packages )[0];
        $self->log( "updating " . $module->name
            . " from " .  $module->oldver
            . " to "   . $module->newver
            . " in "   . $pkg->name );
    }
}



1;
__END__

=head1 SYNOPSIS

    my $old = App::Magpie::Action::Old->new;
    my @old = $old->run;


=head1 DESCRIPTION

This module implements the C<old> action. It's in a module of its own
to be able to be C<require>-d without loading all other actions.

