use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command::webstatic;
# ABSTRACT: create a static web site

use App::Magpie::App -command;


# -- public methods

sub description {
"This command generates a static web site with some statistics &
information on Perl modules available in Mageia Linux."
}

sub opt_spec {
    my $self = shift;
    return (
        [],
        [ 'directory|d=s' => "directory where website will be created"
=>{required=>1} ],
        [],
        $self->verbose_options,
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    $self->log_init($opts);
    require App::Magpie::Action::WebStatic;
    App::Magpie::Action::WebStatic->new->run($opts);
}

1;
__END__


=head1 DESCRIPTION

This command generates a static web site with some statistics &
information on Perl modules available in Mageia Linux.
