use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command::update;
# ABSTRACT: update a perl module to its latest version

use App::Magpie::App -command;


# -- public methods

sub command_names { qw{ update refresh }; }

sub description {

"Update a perl module package to its latest version, try to rebuild it,
commit and submit if successful."

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
    require App::Magpie::Action::Update;
    App::Magpie::Action::Update->new->run;
}

1;
__END__


=head1 SYNOPSIS

    $ eval $( magpie co -s perl-Foo-Bar )
    $ magpie update

    # to get list of available options
    $ magpie help update


=head1 DESCRIPTION

This command will update a perl module package to its latest version,
try to build it locally, commit and submit if successful.

Note that this command will abort if it finds that the spec is too much
outdated (eg, not using C<%define upstream_version>).

This command requires a C<CPAN::Mini> installation on the computer.

