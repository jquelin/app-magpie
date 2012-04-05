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

package App::Magpie::Logger;
{
  $App::Magpie::Logger::VERSION = '1.120960';
}
# ABSTRACT: magpie logging facility

use Log::Dispatchouli;
use MooseX::Singleton;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use App::Magpie::Config;


# -- private attributes


has _logger => (
    ro, lazy,
    isa     => "Log::Dispatchouli",
    handles => [ qw{ log log_debug log_fatal } ],
    default => sub {
        Log::Dispatchouli->new({
            ident     => "magpie",
            to_stderr => 1,
            log_pid   => 1,
            prefix    => '[magpie] ',
        });
    },
);


# -- public attributes


has log_level => (
    ro, lazy_build,
    isa     => "Int",
    traits  => ['Counter'],
    handles => {
        more_verbose => 'inc',
        less_verbose => 'dec',
    },
    trigger => \&_trigger_log_level,
);

sub _build_log_level {
    my $config = App::Magpie::Config->instance;
    return $config->get( "log", "level" ) // 1;
}

sub _trigger_log_level {
    my ($self, $new, $old) = @_;

    my $logger = $self->_logger;
    $logger->set_muted( ($new <= 0) );
    $logger->set_debug( ($new >= 2) );
}


1;


=pod

=head1 NAME

App::Magpie::Logger - magpie logging facility

=head1 VERSION

version 1.120960

=head1 SYNOPSIS

    my $log = App::Magpie::Logger->instance;
    $log->log_fatal( "die!" );

=head1 DESCRIPTION

This module holds a singleton used to log stuff throughout various
magpie commands. Logging itself is done with L<Log::Dispatchouli>.

=head1 ATTRIBUTES

=head2 log_level

The logging level is an integer. In reality, only 3 levels are
recognized:

=over 4

=item * 0 or less - Quiet: Nothing at all will be logged, except if
magpie aborts with an error.

=item * 1 - Normal: quiet level + regular information will be logged.

=item * 2 or more - Debug: normal level + all debug information will be
logged.

=back

=head1 METHODS

=head2 log

=head2 log_debug

=head2 log_fatal

    $magpie->log( ... );
    $magpie->log_debug( ... );
    $magpie->log_fatal( ... );

Log stuff at various verbose levels. Uses L<Log::Dispatchouli>
underneath - refer to this module for more information.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

