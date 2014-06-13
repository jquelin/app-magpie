use 5.010;
use strict;
use warnings;

package App::Magpie::Constants;
# ABSTRACT: Various constants

use Exporter::Lite;
use File::ShareDir qw{ dist_dir };
use Path::Tiny;
 
our @EXPORT_OK = qw{ $SHAREDIR };

our $SHAREDIR = -e path("dist.ini")
    ? path("share")
    : path( dist_dir("App-Magpie") );


1;
__END__

=head1 DESCRIPTION

This module provides some helper variables, to be used on various
occasions throughout the code. Available constants:

=over 4

=item * C<$SHAREDIR>

=back

=cut

