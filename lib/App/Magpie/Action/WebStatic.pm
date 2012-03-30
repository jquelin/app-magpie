use 5.012;
use strict;
use warnings;

package App::Magpie::Action::WebStatic;
# ABSTRACT: webstatic command implementation

use File::HomeDir::PathClass qw{ my_dist_data };
use Moose;
use Path::Class;
use RRDTool::OO;

with 'App::Magpie::Role::Logging';


=method run

    App::Magpie::Action::WebStatic->new->run( $opts );

Update the count of available modules in Mageia, and create a static
website with some information on them.

=cut

sub run {
    my ($self, $opts) = @_;

    my $dir = dir( $opts->{directory} );
    $dir->rmtree; $dir->mkpath;

    my $datadir = my_dist_data( "App-Magpie", { create=>1 } );
    my $rrdfile = $datadir->file( "modules.rrd" );

    my $rrd = RRDTool::OO->new( file=>$rrdfile );
    if ( ! -f $rrdfile ) {
        $rrd->create(
            step        => 60*60*24,            # 1 measure per day
            data_source => {
                name => "nbmodules",
                type => "GAUGE",
            },
            archive => { rows => 365 * 100 },   # data kept for 100 years
        );
    }

    #$rrd->update( );
}


1;
__END__

=head1 SYNOPSIS

    my $webstatic = App::Magpie::Action::WebStatic->new;
    $webstatic->run;


=head1 DESCRIPTION

This module implements the C<webstatic> action. It's in a module of its
own to be able to be C<require>-d without loading all other actions.

