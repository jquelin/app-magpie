use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command::config;
# ABSTRACT: update a spec file to match some policies

use App::Magpie::App -command;

use App::Magpie::Config;


# -- public methods

sub description {
"Store some configuration items, to avoid repeating them over and over
as command-line options."
}

sub opt_spec {
    my $self = shift;
    return (
        [],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $config = App::Magpie::Config->instance;

}

1;
__END__


=head1 SYNOPSIS

    # to always be verbose
    $ magpie config -l 2

    # to get list of available options
    $ magpie help config


=head1 DESCRIPTION

This command allows to store some general configuration items to change
the behaviour of magpie, instead of having to repeat them over & over
again as command-line arguments. Classical example: log level.

