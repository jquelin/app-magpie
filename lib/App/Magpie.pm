use 5.012;
use strict;
use warnings;

package App::Magpie;
# ABSTRACT: Mageia Perl Integration Easy

use CPAN::Mini;
use File::Copy;
use LWP::UserAgent;
use Log::Dispatchouli;
use Moose;
use MooseX::Has::Sugar;
use Parse::CPAN::Meta   1.4401; # load_file
use Parse::CPAN::Packages;
use Path::Class         0.22;   # dir->basename
use Text::Padding;
use version;


# -- public attributes

=attr logger

The L<Log::Dispatchouli> object used for logging.

=method log

=method log_debug

=method log_fatal

    $magpie->log( ... );
    $magpie->log_debug( ... );
    $magpie->log_fatal( ... );

Log stuff at various verbose levels. Uses L<Log::Dispatchouli>
underneath - refer to this module for more information.

=cut

has logger => (
    ro, lazy,
    isa     => "Log::Dispatchouli",
    handles => [ qw{ log log_debug log_fatal } ],
    default => sub {
        Log::Dispatchouli->new({
            ident     => "magpie",
            to_stderr => 1,
            log_pid   => 0,
            prefix    => '[magpie] ',
        });
    },
);



# -- public methods

=method bswait

    my $sleep = $magpie->bswait( $opts );

Check Mageia build-system and fetch the wait hint. Sleep according to
this hint, unless $opts->{nosleep} is true.

Return the number of recommended number of seconds to sleep.

=cut

sub bswait {
    my ($self, $opts) = @_;
    $self->log( "checking bs wait hint" );

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my $response = $ua->head('http://pkgsubmit.mageia.org/');
    $self->log_fatal( $response->status_line ) unless $response->is_success;

    my $sleep = $response->header( "x-bs-throttle" );
    $self->log( "bs recommends to sleep $sleep seconds" );

    if ( !$opts->{nosleep} && $sleep ) {
        $self->log_debug( "sleeping $sleep seconds" );
        sleep($sleep);
    }

    return $sleep;
}


=method checkout

    my $pkgdir = $magpie->checkout( $pkg [, $directory] );

Check out C<$pkg> under C<$directory> (or current directory if no
directory specified). Refresh the checkout if it already exists.

Return the directory in which the checkout is located.

=cut

sub checkout {
    my ($self, $pkg, $directory) = @_;

    # check out the package, or update the local checkout
    my $dir    = defined($directory) ? dir( $directory ) : dir();
    my $pkgdir = $dir->subdir( $pkg );
    $dir->mkpath unless -d $dir;
    $self->log( "checking out $pkg in $pkgdir" );

    if ( -d $pkgdir ) {
        $self->log( "package already checked out, refreshing checkout");
        chdir $pkgdir;
        $self->_run_command( "mgarepo up" );
    } else {
        chdir $dir;
        $self->_run_command( "mgarepo co $pkg" );
    }

    return $pkgdir;
}


=method fixspec

    $magpie->fixspec;

Fix the spec file to match a set of rules. Make sure buildrequires are
correct.

=cut

sub fixspec {
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
    $self->log( "fixing $specfile" );

    # extracting tarball
    $self->log_debug( "removing previous BUILD directory" );
    dir( "BUILD" )->rmtree;
    $self->_run_command( "bm -lp" );
    my $distdir  = dir( glob "BUILD/*" );
    my $metafile = -e $distdir->file("META.json")
        ? $distdir->file("META.json")
        : -e $distdir->file("META.yml")
            ? $distdir->file("META.yml") : undef;

    # cleaning spec file
    $self->log_debug( "removing mandriva macros" );
    $spec =~ s/^%if %{mdkversion}.*?^%endif$//msi;

    $self->log_debug( "removing buildroot, not needed anymore" );
    $spec =~ s/^buildroot:.*\n//mi;

    $self->log_debug( "trimming empty end lines" );
    $spec =~ s/\n+\z//;

    # splitting up build-/requires
    $self->log_debug( "splitting (build-)requires one per line" );
    $spec =~ s{^((?:build)?requires):\s*(.*)$}{
        my $key = $1; my $value = $2; my $str;
        $str .= $key . ": $1\n" while $value =~ m{(\S+(\s*[>=<]+\s*\S+)?)\s*}g;
        $str;
    }mgie;

    # fetching buildrequires from meta file
    if ( defined $metafile ) {
        $self->log_debug( "using META file to get buildrequires" );
        $spec =~ s{^buildrequires:\s*perl\(.*\).*$}{}mgi;
        my $meta = Parse::CPAN::Meta->load_file( $metafile );
        my %br_from_meta;
        if ( $meta->{"meta-spec"}{version} < 2 ) {
            %br_from_meta = (
                %{ $meta->{configure_requires} // {} },
                %{ $meta->{build_requires}     // {} },
                %{ $meta->{requires}           // {} },
            );
        } else {
            my $prereqs = $meta->{prereqs};
            %br_from_meta = (
                %{ $prereqs->{configure}{requires} // {} },
                %{ $prereqs->{build}{requires}     // {} },
                %{ $prereqs->{test}{requires}      // {} },
                %{ $prereqs->{runtime}{requires}   // {} },
            );
        }

        my $rpmbr;
        foreach my $br ( sort keys %br_from_meta ) {
            next if $br eq 'perl';
            my $version = $br_from_meta{$br};
            $rpmbr .= "BuildRequires: perl($br)";
            if ( $version != 0 ) {
                my $rpmvers = qx{ rpm -E "%perl_convert_version $version" };
                $rpmbr .= " >= $rpmvers";
            }
            $rpmbr .= "\n";
        }

        if ( $spec =~ /buildrequires/i ) {
            $spec =~ s{^(buildrequires:.*)$}{$rpmbr$1}mi;
        } else {
            $spec =~ s{^(buildarch.*)$}{$rpmbr$1}mi;
        }
    }

    $spec =~ s{^((?:build)?requires:.*)\n+}{$1\n}mgi;

    # lining up / padding
    my $pad = Text::Padding->new;
    $self->log_debug( "lining up categories" );
    $spec =~
        s{^(Name|Version|Release|Epoch|Summary|License|Group|Url|Source\d*|Patch\d*|BuildArch|Requires|Obsoletes|Provides):\s*}
         { $pad->left( ucfirst(lc($1)) . ":", 12 ) }mgie;
    $spec =~ s{^source:}{Source0:}mgi;
    $spec =~ s{^patch:}{Patch0:}mgi;
    $spec =~ s{^buildrequires:}{BuildRequires:}mgi;
    $spec =~ s{^buildarch:}{BuildArch:}mgi;

    # updating %doc
    $self->log_debug( "fetching documentation files" );
    my @docfiles =
        sort
        grep { ! /^MANIFEST/ }
        grep { /^[A-Z]+$/ || m{^(Change(s|log)|META.(json|yml)|eg|examples)$}i }
        map  { $_->basename }
        $distdir->children;
    if ( @docfiles ) {
        $self->log_debug( "found: @docfiles" );
        if ( $spec =~ /^%doc (.*)/m ) {
            $self->log_debug( "updating %doc" );
            $spec =~ s/^(%doc .*)$/%doc @docfiles/m;
        } else {
            $self->log_debug( "adding a %doc" );
            $spec =~ s/^%files$/%files\n%doc @docfiles/m;
        }
    } else {
        $self->log_debug( "no documentation found" );
    }

    # other things that might be worth checking...
        # perl-version instead of perl(version)
        # url before source
        # source:  http://www.cpan.org/modules/by-module/Algorithm/
        #  Url:        http://search.cpan.org/dist/%{upstream_name}
        # license
        # rpmlint ?
        # sorting buildrequires
        # %description\n\n
        # $RPM_BUILD_ROOT
        #  %{upstream_name} module for perl within summary
        # "perl module" within summary
        # "module for perl" within summary
        # %{upstream_name}  within description
        # requires with buildrequires
        # requires perl
        # no %check
        # %upstream instead of %{upstream
        # perl-devel alongside noarch
        # within %install et %clean: [ "%{buildroot}" != "/" ] && rm -rf %{buildroot}
        # "no summary found"
        # "no description found"
        # make test without %check
        # %modprefix


    # removing extra newlines
    $spec =~ s{\n{3,}}{\n\n}g;

    # writing down new spec file
    $self->log_debug( "writing updated spec file" );
    my $fh = $specfile->openw;
    $fh->print($spec);
    $fh->close;
}


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
    my $p       = Parse::CPAN::Packages->new( $modgz->stringify );
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

    # fix spec file, update buildrequires
    $self->fixspec;

    # create script
    my $script  = file( "refresh" );
    my $fh = $script->openw;
    $fh->print(<<EOF);
#!/bin/bash
bm -l                          && \\
mgarepo sync -c                && \\
svn ci -m "update to $newvers" && \\
mgarepo submit                 && \\
rm \$0
EOF
    $fh->close;
    chmod 0755, $script;

    # local dry-run
    $self->log( "trying to build package locally" );
    $self->_run_command( "bm -l" );

    # push changes
    $self->log( "committing changes" );
    $self->_run_command( "mgarepo sync -c" );
    $self->_run_command( "svn ci -m 'update to $newvers'" );

    # submit
    $self->bswait;
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
    $logger->log_debug( "running: $cmd" );

    my $stderr = ($logger->get_debug && !$logger->get_muted) ? "" : "2>/dev/null";

    # run the command
    system("$cmd $stderr >&2") == 0
        or $logger->log_fatal( [ "command [$cmd] exited with value %d", $?>>8] );
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


