use 5.012;
use strict;
use warnings;

package App::Magpie::Action::Missing;
# ABSTRACT: Missing command implementation

use Moose;
use ORDB::CPAN::Mageia;
use URPM;

with 'App::Magpie::Role::Logging';


=method run

    App::Magpie::Action::Missing->new->run( $opts );

List Perl modules available in Mageia but not installed locally.

=cut

sub run {
    my ($self, $opts) = @_;

    # read local rpm database
    my $db = URPM::DB::open();
    my @local;
    $db->traverse( sub { my ($pkg) = @_; push @local, $pkg->name; } );

    # see perl rpms available in mageia
    my %mageia;
    my $mgadists = ORDB::CPAN::Mageia->selectcol_arrayref(
        'SELECT DISTINCT pkgname FROM module ORDER BY dist'
    );
    @mageia{ @$mgadists } = ();

    # list available rpms not installed locally
    delete @mageia{ @local };
    say $_ for sort keys %mageia;
}

1;
__END__

=head1 DESCRIPTION

This module implements the C<missing> action. It's in a module of its
own to be able to be C<require>-d without loading all other actions.

