use 5.012;
use strict;
use warnings;

package App::Magpie::Logger;
# ABSTRACT: magpie logging facility

use Log::Dispatchouli;
use MooseX::Singleton;
use MooseX::Has::Sugar;


# -- private attributes

=method log

=method log_debug

=method log_fatal

    $magpie->log( ... );
    $magpie->log_debug( ... );
    $magpie->log_fatal( ... );

Log stuff at various verbose levels. Uses L<Log::Dispatchouli>
underneath - refer to this module for more information.

=cut

has _logger => (
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

1;
__END__

=head1 SYNOPSIS

    my $log = App::Magpie::Logger->instance;
    $log->log_fatal( "die!" );


=head1 DESCRIPTION

This module holds a singleton used to log stuff throughout various
magpie commands. Logging itself is done with L<Log::Dispatchouli>.

