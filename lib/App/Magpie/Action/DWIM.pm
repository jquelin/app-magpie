use 5.012;
use strict;
use warnings;

package App::Magpie::Action::DWIM;
# ABSTRACT: dwim command implementation

use File::pushd;
use List::MoreUtils qw{ each_array };
use Moose;
use Proc::ParallelLoop;

use App::Magpie::Action::Checkout;
use App::Magpie::Action::Old;
use App::Magpie::Action::Update;

with 'App::Magpie::Role::Logging';


=method run

    $dwim->run;

Update Mageia packages of Perl modules with a new version available on
CPAN.

=cut

sub run {
    my ($self, $directory) = @_;
    
    my ($set) =
        grep { $_->name eq "normal" }
        App::Magpie::Action::Old->new->run;
    my @modules = $set->all_modules;

    if ( not defined $set ) {
        $self->log( "no package to update" );
        return;
    }

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
__END__

=head1 SYNOPSIS

    my $old = App::Magpie::Action::Old->new;
    my @old = $old->run;


=head1 DESCRIPTION

This module implements the C<old> action. It's in a module of its own
to be able to be C<require>-d without loading all other actions.

