use 5.012;
use strict;
use warnings;

package App::Magpie;
# ABSTRACT: Mageia Perl Integration Easy

use Log::Dispatchouli;
use Moose;
use MooseX::Has::Sugar;
use Path::Class;

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

# -- private methods

sub _run_command {
    my ($self, $cmd) = @_;
    my $logger   = $self->logger;
    my $redirect = ($logger->get_debug && !$logger->get_muted) ? "&2" : "/dev/null";
    $self->log_debug( "running: $cmd" );
    system "$cmd >$redirect";
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


