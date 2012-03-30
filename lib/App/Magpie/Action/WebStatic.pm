#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::Action::WebStatic;
{
  $App::Magpie::Action::WebStatic::VERSION = '1.120901';
}
# ABSTRACT: webstatic command implementation

use DateTime;
use File::Copy                  qw{ move };
use File::HomeDir::PathClass    qw{ my_dist_data };
use Moose;
use ORDB::CPAN::Mageia;
use Path::Class;
use RRDTool::OO;
use Readonly;
use Template;

use App::Magpie::Constants qw{ $SHAREDIR };


with 'App::Magpie::Role::Logging';



sub run {
    my ($self, $opts) = @_;

    # first, update the rrd file with the number of available modules
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

    my $nbmodules = ORDB::CPAN::Mageia::Module->count;
    $rrd->update( $nbmodules );

    # create the web site
    my $dir = dir( $opts->{directory} . ".new" );
    $dir->rmtree; $dir->mkpath;
    my $imgdir = $dir->subdir( "images" );
    $imgdir->mkpath;
    $rrd->graph(
        image => $imgdir->file("nbmodules.png"),
        width => 800,
        title => 'Number of available Perl modules in Mageia Linux',
        start => DateTime->new(year=>2012)->epoch,
        draw  => {
            thickness => 2,
            color     => '0000FF',
        },
    );

    my $tt = Template->new({
        INCLUDE_PATH => $SHAREDIR->subdir("webstatic"),
        INTERPOLATE  => 1,
    }) or die "$Template::ERROR\n";

    my $vars = {
        nbmodules => $nbmodules,
        date      => scalar localtime,
    };
    $tt->process('index.tt2', $vars, $dir->file("index.html")->stringify)
        or die $tt->error(), "\n";


    # update website in one pass: remove previous version, replace it by new one
    my $olddir = dir( $opts->{directory} );
    $olddir->rmtree;
    move( $dir->stringify, $olddir->stringify );
}


1;


=pod

=head1 NAME

App::Magpie::Action::WebStatic - webstatic command implementation

=head1 VERSION

version 1.120901

=head1 SYNOPSIS

    my $webstatic = App::Magpie::Action::WebStatic->new;
    $webstatic->run;

=head1 DESCRIPTION

This module implements the C<webstatic> action. It's in a module of its
own to be able to be C<require>-d without loading all other actions.

=head1 METHODS

=head2 run

    App::Magpie::Action::WebStatic->new->run( $opts );

Update the count of available modules in Mageia, and create a static
website with some information on them.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

