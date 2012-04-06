use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command::missing;
# ABSTRACT: List modules shipped by Mageia not present locally

use App::Magpie::App -command;


# -- public methods

sub description {
'This command lists Perl modules shipped by Mageia but not present on
the local system. This is especially useful if one wants to run "magpie
old" afterwards.'
}

sub opt_spec {
    my $self = shift;
    return (
        [],
        $self->verbose_options,
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    $self->log_init($opts);
    require App::Magpie::Action::Missing;
    App::Magpie::Action::Missing->new->run($opts);
}

1;
__END__


=head1 DESCRIPTION

This command lists Perl modules shipped by Mageia but not present on the
local system. This is especially useful if one wants to run "magpie old"
afterwards.

