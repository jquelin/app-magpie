#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command::old;
{
  $App::Magpie::App::Command::old::VERSION = '1.113123';
}
# ABSTRACT: report installed perl modules with new version available 

use Encode;
use Text::Padding;

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
    my @oldsets =
        sort { $a->name cmp $b->name }
        App::Magpie::Action::Old->new->run;

    my $pad = Text::Padding->new;
    my @ignored;
    foreach my $set ( @oldsets ) {
        if ( $set->name eq "ignored" ) {
            @ignored = $set->all_modules;
            next;
        }

        my $label = $set->name;
        say "** $label packages: " . $set->nb_modules;
        say '';

        foreach my $module ( sort $set->all_modules ) {
            my @pkgs = $module->packages;
            given ( scalar(@pkgs) ) {
                when (0) {
                    say encode( 'utf-8',
                        $pad->left ( $module->name, 40 )   .
                        $pad->right( $module->oldver, 14 ) .
                        $pad->right( $module->newver, 14 )
                    );
                }
                when (1) {
                    my $pkg = shift @pkgs;
                    say encode( 'utf-8',
                        $pad->left ( $module->name, 40 )   .
                        $pad->right( $module->oldver, 14 ) .
                        $pad->right( $module->newver, 14 ) .
                        " " x 5                            .
                        $pad->left ( $pkg->name, 50 )      .
                        $pad->right( $pkg->version, 14 )
                    );
                }
                default {
                    my @details =
                        map { $_->name . "(" . $_->version . ")" }
                        @pkgs;
                    say encode( 'utf-8',
                        $pad->left ( $module->name, 40 )   .
                        $pad->right( $module->oldver, 14 ) .
                        $pad->right( $module->newver, 14 ) .
                        " " x 5                            .
                        join( ",", @details )
                    );
                 }
             }
        }
        say '';
    }

    if ( @ignored ) {
        say "** ignored modules: " . scalar(@ignored) . "\n";
        print join ", ", map { $_->name ."(" . $_->newver . ")" } @ignored;
        say '';
    }
}

1;


=pod

=head1 NAME

App::Magpie::App::Command::old - report installed perl modules with new version available 

=head1 VERSION

version 1.113123

=head1 SYNOPSIS

    $ magpie old

    # to get list of available options
    $ magpie help old

=head1 DESCRIPTION

This command will check all installed Perl modules, and report the ones
that have a new version available on CPAN. It will also provides the
Mageia package which said module belongs.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


