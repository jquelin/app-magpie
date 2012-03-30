use 5.010;
use strict;
use warnings;

package App::Magpie::Constants;
# ABSTRACT: Various constants

use Exporter::Lite;
use File::ShareDir::PathClass;
use Path::Class;
 
our @EXPORT_OK = qw{ $SHAREDIR };

our $SHAREDIR = -e file("dist.ini")
    ? dir ("share")
    : File::ShareDir::PathClass->dist_dir("App-Magpie");


1;
__END__

=head1 DESCRIPTION

This module provides some helper variables, to be used on various
occasions throughout the code. Available constants:

=over 4

=item * C<$SHAREDIR>

=back

=cut

