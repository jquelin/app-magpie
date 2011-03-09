use 5.012;
use strict;
use warnings;

package App::Magpie::Action::Old;
# ABSTRACT: old command implementation

use Moose;

use App::Magpie::Action::Old::Module;
use App::Magpie::Action::Old::Set;

with 'App::Magpie::Role::Logging';


=method run

    my @old = $old->run;

Return the list of Perl modules with a new version available on CPAN.

=cut

sub run {
    my ($self) = @_;
    my %category;

    $self->log( "running cpanplus" );
    my @lines = qx{ cpanp o };

    # analyze "cpanp o" output - meaningful lines are of the form:
    #  row  newver        oldver      module name        author
    #   60   Unparsable      1.60     SVN::Core          MSCHWERN
    #   68   2011.00      2011.03     Unicode::GCString  NEZUMI
    LINE:
    foreach my $line ( @lines ) {
        next unless $line =~ s/^\s+\d+\s+//; # re
        chomp $line;

        my ($oldver, $newver, $modname) = split /\s+/, $line;
        my $module = App::Magpie::Action::Old::Module->new(
            name => $modname, oldver => $oldver, newver => $newver );

        my $category = $module->category;
        $category{ $category } //= App::Magpie::Action::Old::Set->new(name=>$category);
        $category{ $category }->add_module( $module );
    }

    return values %category;
}



1;
__END__

=head1 SYNOPSIS

    my $old = App::Magpie::Action::Old->new;
    my @old = $old->run;


=head1 DESCRIPTION

This module implements the C<old> action. It's in a module of its own
to be able to be C<require>-d without loading all other actions.

