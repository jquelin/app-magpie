use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command::dwim;
# ABSTRACT: automagically update Mageia packages

use App::Magpie::App -command;


# -- public methods

sub description {
"Automatically update Perl modules which aren't up to date in Mageia."
}

sub opt_spec {
    my $self = shift;
    return (
        [ 'directory|d=s' => "directory where update will be done" ],
        [],
        $self->verbose_options,
    );
}

sub execute {
    my ($self, $opts, $args) = @_;

    $self->log_init($opts);
    require App::Magpie::Action::DWIM;
    App::Magpie::Action::DWIM->new->run( $opts->{directory} );
}

1;
__END__


=head1 SYNOPSIS

    $ magpie dwim

    # to get list of available options
    $ magpie help olddwim


=head1 DESCRIPTION

This command will check all installed Perl modules, and update the
Mageia packages that have a new version available on CPAN.

