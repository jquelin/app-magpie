use 5.012;
use strict;
use warnings;

package App::Magpie::Role::RunningCommand;
# ABSTRACT: sthg that can run an external command

use Moose::Role;
use MooseX::Has::Sugar;

with 'App::Magpie::Role::Logging';


# -- public methods

=method run_command

    $obj->run_command( $cmd );

Run a command, spicing some debug comments here and there. Die if the
command encountered a problem.

=cut

sub run_command {
    my ($self, $cmd) = @_;
    my $logger = $self->logger;
    $self->log_debug( "running: $cmd" );

    my $stderr = $logger->log_level >= 2 ? "" : "2>/dev/null";

    # run the command
    system("$cmd $stderr >&2") == 0
        or $self->log_fatal( "command [$cmd] exited with value " . ($?>>8) );
}


 
1;
__END__

=head1 SYNOPSIS

    with 'App::Magpie::Role::RunningCommand';
    $self->run_command( "sleep 10" );


=head1 DESCRIPTION

This role is meant to provide easy way of running a command for classes
consuming it. Standard output & standard errors are redirected depending
on the log level.

