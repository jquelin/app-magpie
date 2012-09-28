#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package App::Magpie::Constants;
{
  $App::Magpie::Constants::VERSION = '1.122721';
}
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

=pod

=head1 NAME

App::Magpie::Constants - Various constants

=head1 VERSION

version 1.122721

=head1 DESCRIPTION

This module provides some helper variables, to be used on various
occasions throughout the code. Available constants:

=over 4

=item * C<$SHAREDIR>

=back

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
