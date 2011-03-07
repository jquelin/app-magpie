use 5.012;
use strict;
use warnings;

package App::Magpie;
# ABSTRACT: Mageia Perl Integration Easy

use CPAN::Mini;
use File::Copy;
use Log::Dispatchouli;
use Moose;
use MooseX::Has::Sugar;
use Parse::CPAN::Packages::Fast;
use Path::Class         0.22;   # dir->basename
use version;

with 'App::Magpie::Role::Logging';


# -- public methods


=method update

    $magpie->update;

Try to update the current checked-out package to its latest version, if
there's one available.

=cut

sub update {
    my ($self) = @_;

    # check if there's a spec file to update...
    my $specdir = dir("SPECS");
    -e $specdir or $self->log_fatal("cannot find a SPECS directory, aborting");
    my @specfiles =
        grep { /\.spec$/ }
        $specdir->children;
    scalar(@specfiles) > 0
        or $self->log_fatal("could not find a spec file, aborting");
    scalar(@specfiles) < 2
        or $self->log_fatal("more than one spec file found, aborting");
    my $specfile = shift @specfiles;
    my $spec = $specfile->slurp;
    my $pkgname = $specfile->basename; $pkgname =~ s/\.spec$//;
    $self->log( "updating $pkgname" );

    # check if package uses %upstream_{name|version}
    my ($distname) = ( $spec =~ /^%define\s+upstream_name\s+(.*)$/m );
    my ($distvers) = ( $spec =~ /^%define\s+upstream_version\s+(.*)$/m );
    defined($distname) or $self->log_fatal( "package does not use %upstream_name" );
    defined($distvers) or $self->log_fatal( "package does not use %upstream_version" );
    $self->log_debug( "perl distribution to update: $distname v$distvers" );

    # check if we have a minicpan at hand
    my $cpanmconf = CPAN::Mini->config_file;
    defined($cpanmconf)
        or $self->log_fatal("no minicpan installation found, aborting");
    my %config   = CPAN::Mini->read_config( {quiet=>1} );
    my $cpanmdir = dir( $config{local} );
    $self->log_debug( "found a minicpan installation in $cpanmdir" );

    # try to find a newer version
    $self->log_debug( "parsing 02packages.details.txt.gz" );
    my $modgz   = $cpanmdir->file("modules", "02packages.details.txt.gz");
    my $p       = Parse::CPAN::Packages::Fast->new( $modgz->stringify );
    my $dist    = $p->latest_distribution( $distname );
    my $newvers = $dist->version;
    version->new( $newvers ) > version->new( $distvers )
        or $self->log_fatal( "no new version found" );
    $self->log( "new version found: $newvers" );

    # copy tarball
    my $cpantarball = $cpanmdir->file( "authors", "id", $dist->prefix );
    my $tarball     = $dist->filename;
    $self->log_debug( "copying $tarball to SOURCES" );
    copy( $cpantarball->stringify, "SOURCES" )
        or $self->log_fatal( "could not copy $cpantarball to SOURCES: $!" );

    # update spec file
    $self->log_debug( "updating spec file $specfile" );
    $spec =~ s/%mkrel \d+/%mkrel 1/;
    $spec =~ s/^(%define upstream_version) .*/$1 $newvers/m;
    my $specfh = $specfile->openw;
    $specfh->print( $spec );
    $specfh->close;

    # create script
    my $script  = file( "refresh" );
    my $fh = $script->openw;
    $fh->print(<<EOF);
#!/bin/bash
magpie fix -v                  && \\
bm -l                          && \\
mgarepo sync -c                && \\
svn ci -m "update to $newvers" && \\
mgarepo submit                 && \\
rm \$0
EOF
    $fh->close;
    chmod 0755, $script;

    # fix spec file, update buildrequires
    $self->fixspec;

    # local dry-run
    $self->log( "trying to build package locally" );
    $self->_run_command( "bm -l" );

    # push changes
    $self->log( "committing changes" );
    $self->_run_command( "mgarepo sync -c" );
    $self->_run_command( "svn ci -m 'update to $newvers'" );

    # submit
    require App::Magpie::Action::BSWait;
    App::Magpie::Action::BSWait->new->run;
    $self->_run_command( "mgarepo submit" );
    $script->remove;
}


# -- private methods

#
# $magpie->_run_command( $cmd );
#
# Run a command, spicing some debug comments here and there.
# Die if the command encountered a problem.
#
sub _run_command {
    my ($self, $cmd) = @_;
    my $logger = $self->logger;
    $self->log_debug( "running: $cmd" );

    my $stderr = $logger->log_level >= 2 ? "" : "2>/dev/null";

    # run the command
    system("$cmd $stderr >&2") == 0
        or $self->log_fatal( [ "command [$cmd] exited with value %d", $?>>8] );
}

1;
__END__

=head1 DESCRIPTION

CPAN holds a lot of great modules - but it can be difficult for the user
to install if she's not familiar with the process. Therefore, Linux
distribution usually package quite a lot of them, for them to be easily
installable.

Mageia Linux is no exception, and ships more than 2500 packages holding
Perl distributions (at the time of writing). Maintaining those packages
is a daunting task - and cannot be done only by hand.

This distribution is therefore a set of scripts helping maintaining Perl
packages within Mageia. They can be somehow coupled or used
independently.

Even if they are Mageia-centered, and Perl-centered, some of those tools
can be used also by to maintain non-Perl packages, or by other Linux
distributions than Mageia. I'd like to hear from you in this case! :-)


=head1 SEE ALSO

You can find more information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/App-Magpie>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Magpie>

=item * Git repository

L<http://github.com/jquelin/app-magpie>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Magpie>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Magpie>

=back


