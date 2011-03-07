use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command::old;
# ABSTRACT: report installed perl modules with new version available 

use App::Magpie::App -command;


# -- public methods

sub description {
"Report installed Perl modules with new version available on CPAN."
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
    require App::Magpie::Action::Old;
    App::Magpie::Action::Old->new->run;
}

1;
__END__


=head1 SYNOPSIS

    $ magpie old

    # to get list of available options
    $ magpie help old


=head1 DESCRIPTION

This command will check all installed Perl modules, and report the ones
that have a new version available on CPAN. It will also provides the
Mageia package which said module belongs.

