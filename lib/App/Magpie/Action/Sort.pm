use 5.012;
use strict;
use warnings;

package App::Magpie::Action::Sort;
# ABSTRACT: sort command implementation

use List::AllUtils qw{ part uniq };
use Moose;
use Path::Tiny;

use App::Magpie::Action::Sort::Package;
use App::Magpie::URPM;

with 'App::Magpie::Role::Logging';


# -- public methods

=method run

    $sort->run;

Re-order a list of packages to be rebuilt.

=cut

sub run {
    my ($self, $opts) = @_;

    # default input/output files
    my $in  = $opts->{input} eq "-"  ? *STDIN  : path($opts->{input})->openr;
    my $out = $opts->{output} eq "-" ? *STDOUT : path($opts->{output})->openw;

    # get list of packages to sort
    my @unsorted = $in->getlines;
    chomp( @unsorted );
    $self->log( scalar(@unsorted) . " packages to sort" );
    @unsorted = uniq @unsorted;
    $self->log( scalar(@unsorted) . " unique packages to sort" );

    # fetch list of all provides for the packages to be sorted
    my $urpm = App::Magpie::URPM->instance;
    my %provides;
    @provides{
        map { $_->provides_nosense }
        map { $urpm->packages($_) }
        @unsorted
    } = ();

    # create the package list
    $self->log( "fetching packages requires & provides" );
    my @packages;
    my %seen;
    foreach my $name ( @unsorted ) {
        next if $seen{$name}++;
        # create and store the package
        my @pkgs = $urpm->packages($name);
        my $pkg  = App::Magpie::Action::Sort::Package->new(name=>$name);
        push @packages, $pkg;

        # fetch package provides
        my %pkg_provides;
        @pkg_provides{ map { $_->provides_nosense } @pkgs } = ();
        $pkg->add_provides( keys %pkg_provides );
#        $self->log_debug( "$name provides: @{$pkg->provides}" );

        # fetch package requires
        my @requires = 
            grep { ! exists $pkg_provides{$_} }
            grep { exists $provides{$_} }
            map  { $_->requires_nosense }
            @pkgs;
#        $self->log_debug( "$name requires: @requires" );
        $pkg->add_requires(@requires);
    }

    # really sort the list by requires/provides this time
    my $iteration = 1;
    @packages = sort { $a->name cmp $b->name } @packages;
    while ( scalar(@packages) ) {
        # extract packages with no requires
        my ($remaining, $this_round) = part { $_->has_no_requires } @packages;

        # check if we're in a dead-lock
        if ( not defined $this_round ) {
            $self->log( "remaining packages: " . join ",", map {$_->name} @$remaining );
            $self->log_fatal(
                "no package available this round - aborting " .
                "(remaining: ". scalar(@$remaining) . ")"
            );
        }
        $self->log( "iteration $iteration: " .scalar(@$this_round) . " packages" );
        $out->print( "$_\n" ) for map { $_->name } @$this_round;

        $remaining //= [];
        @packages = @$remaining;
        $_->rm_requires( map { $_->provides } @$this_round ) for @$remaining;
        $iteration++;
    }
}



1;
__END__

=head1 SYNOPSIS

    my $sort = App::Magpie::Action::Sort->new;
    $sort->run;


=head1 DESCRIPTION

This module implements the C<sort> action. It's in a module of its own
to be able to be C<require>-d without loading all other actions.

