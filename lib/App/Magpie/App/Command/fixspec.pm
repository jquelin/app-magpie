use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command::fixspec;
# ABSTRACT: update a spec file to match some policies

use App::Magpie::App -command;


# -- public methods

sub description {
"Update a spec file from a perl module package, and make sure it follows
a list of various policies. Also update the list of build prereqs."
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
    require App::Magpie::Action::FixSpec;
    App::Magpie::Action::FixSpec->new->run;
}

1;
__END__


=head1 SYNOPSIS

    $ eval $( magpie co -s perl-Foo-Bar )
    $ magpie fixspec

    # to get list of available options
    $ magpie help fixspec


=head1 DESCRIPTION

This command will update a spec file from a perl module package, and
make sure it follows a list of various policies. It will also update the
list of build prereqs, according to F<META.yml> (or F<META.json>)
shipped with the distribution.

Note that this command will abort if it finds that the spec is too much
outdated (eg, not using C<%perl_convert_version>)

