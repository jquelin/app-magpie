use 5.012;
use strict;
use warnings;

package App::Magpie;
# ABSTRACT: Mageia Perl Integration Easy

use Log::Dispatchouli;
use Moose;
use MooseX::Has::Sugar;
use Path::Class 0.22; # dir->basename
use Text::Padding;


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
        });
    },
);


# -- public methods

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
    my $distdir = dir( glob "BUILD/*" );

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
    $spec =~ s{^((?:build)?requires:.*)\n+}{$1\n}mgi;

    # lining up / padding
    my $pad = Text::Padding->new;
    $self->log_debug( "lining up categories" );
    $spec =~
        s{^(Name|Version|Release|Epoch|Summary|License|Group|Url|Source\d*|Requires|Obsoletes|Provides):\s*}
         { $pad->left( ucfirst(lc($1)) . ":", 12 ) }mgie;
    $spec =~ s{^(buildrequires):\s*}{BuildRequires: }mgi;

    # updating %doc
    $self->log_debug( "fetching documentation files" );
    my @docfiles =
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

    # writing down new spec file
    $self->log_debug( "writing updated spec file" );
    my $fh = $specfile->openw;
    $fh->print($spec);
    $fh->close;
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


