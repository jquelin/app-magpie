use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command;
# ABSTRACT: base class for sub-commands

use App::Cmd::Setup -command;
use Moose;
use MooseX::Has::Sugar;

use App::Magpie;
use App::Magpie::Config;


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

    my $config =App::Magpie::Config->instance;
    my $log_level = ( $config->get( "log", "level" ) // 1 ) + $opts->{verbose} - $opts->{quiet};
    $self->magpie->logger->set_muted(1) if $log_level == 0;
    $self->magpie->logger->set_debug(1) if $log_level == 2;
}


=method verbose_options

    my @opts = $self->verbose_options;

Return an array of verbose options to be used in a command's C<opt_spec>
method. Those options can then be used by C<log_init()>.

=cut

sub verbose_options {
    my $config =App::Magpie::Config->instance;
    my $log_level = ( qw{ quiet normal debug } )[ $config->get( "log", "level" ) // 1 ];
    return (
        [ "Logging options (default log level: $log_level)" ],
        [ 'verbose|v+' => "be more verbose (can be repeated)",  {default=>0} ],
        [ 'quiet|q+'   => "be less versbose (can be repeated)", {default=>0} ],
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

