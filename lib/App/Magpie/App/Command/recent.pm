use 5.016;
use strict;
use warnings;

package App::Magpie::App::Command::recent;
# ABSTRACT: Recent uploads on PAUSE not available in Mageia

use App::Magpie::App -command;


# -- public methods

sub description {
"This command checks what has been recently (1 day) uploaded on PAUSE
which is not available in Mageia."
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
    require App::Magpie::Action::Recent;
    App::Magpie::Action::Recent->new->run($opts);
}

1;
__END__


=head1 DESCRIPTION

This command checks what has been recently (1 day) uploaded on PAUSE
which is not available in Mageia. Interesting to see what could be done
to extend Perl support in Mageia.
