use 5.012;
use strict;
use warnings;

package App::Magpie::Role::Logging;
# ABSTRACT: sthg that can log

use Moose::Role;
use MooseX::Has::Sugar;

use App::Magpie::Logger;


# -- public attributes

=attr logger

The C<App::Magpie::Logger> object used for logging.

=method log

=method log_debug

=method log_fatal

Those methods are provided by a L<App::Magpie::Logger> object. Refer to
the corresponding documentation for more information.

=cut
  
has logger => (
    ro, lazy,
    isa     => "App::Magpie::Logger",
    handles => [ qw{ log log_debug log_fatal } ],
    default => sub { App::Magpie::Logger->instance }
);

 
1;
__END__

=head1 SYNOPSIS

    with 'App::Magpie::Role::Logging';
    $self->log_fatal( "die!" );


=head1 DESCRIPTION

This role is meant to provide easy logging for classes consuming it.
Logging itself is done through L<App::Magpie::Logger>.

