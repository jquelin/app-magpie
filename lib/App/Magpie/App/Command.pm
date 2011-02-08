use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command;
# ABSTRACT: base class for sub-commands

use App::Cmd::Setup -command;
use Moose;
use MooseX::Has::Sugar;

use App::Magpie;


# -- public attributes

=attr magpie

The L<App::Magpie> object responsible for the real operations.

=cut

has magpie => (
    ro, lazy,
    isa     => "App::Magpie",
    default => sub { App::Magpie->new; }
);


# -- public methods

=method log_init

    $cmd->log_init($opts);

Initializes the C<logger> attribute of C<magpie> depending on the
value of verbose options.

=cut

sub log_init {
    my ($self, $opts) = @_;
    $self->magpie->logger->set_muted(1) if $opts->{quiet};
    $self->magpie->logger->set_debug(1) if $opts->{verbose};
}


=method verbose_options

    my @opts = $self->verbose_options;

Return an array of verbose options to be used in a command's C<opt_spec>
method. Those options can then be used by C<log_init()>.

=cut

sub verbose_options {
    return (
        [ "Logging options" ],
        [ 'verbose|v' => "display extra information" ],
        [ 'quiet|q'   => "be quiet unless error"     ],
    );
}

1;
__END__

=for Pod::Coverage::TrustPod
    description
    opt_spec
    execute

=head1 DESCRIPTION

This module is the base class for all sub-commands. It provides some
methods to control logging.

