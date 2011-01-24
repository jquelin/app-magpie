use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command;
# ABSTRACT: base class for sub-commands

use App::Cmd::Setup -command;

# -- public methods


1;
__END__

=for Pod::Coverage::TrustPod
    description
    opt_spec
    execute

=head1 DESCRIPTION

This module is the base class for all sub-commands. It doesn't do
anything special currently but trusting methods for pod coverage.

