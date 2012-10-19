use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command::sort;
# ABSTRACT: sort packages needing a rebuild according to their requires

use App::Magpie::App -command;


# -- public methods

sub description {
"This command will sort a list of packages to be rebuilt so that
dependencies are followed."
}

sub opt_spec {
    my $self = shift;
    return (
        [],
        [ 'input|i=s'
            => "file with list of packages to be sorted (default: STDIN)"
            => { default => "-" } ],
        [ 'output|o=s'
            => "file with list of sorted packages (default: STDOUT)"
            => { default => "-" } ],
        [],
        $self->verbose_options,
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    $self->log_init($opts);
    require App::Magpie::Action::Sort;
    App::Magpie::Action::Sort->new->run( $opts );
}

1;
__END__


=head1 SYNOPSIS

    $ urpmf --requires :perlapi-5.16 | perl -pi -E 's/:.*//' | magpie sort

    # to get list of available options
    $ magpie help sort


=head1 DESCRIPTION

This command will sort a list of packages to be rebuilt so that
dependencies are followed.

