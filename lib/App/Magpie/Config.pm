use 5.012;
use strict;
use warnings;

package App::Magpie::Config;
# ABSTRACT: magpie configuration storage & retrieval

use Config::Tiny;
use File::HomeDir::PathClass;
use MooseX::Singleton;
use MooseX::Has::Sugar;

my $CONFIGDIR   = File::HomeDir::PathClass->my_dist_config( "App-Magpie", {create=>1} );
my $config_file = $CONFIGDIR->file( "config.ini" );

has _config => ( ro, isa => "Config::Tiny", lazy_build );

sub _build__config {
    my $self = shift;
    my $config = Config::Tiny->read( $config_file );
    $config  //= Config::Tiny->new;
    return $config;
}

# -- public methods

=method dump

    my $str = $config->dump;

Return the whole content of the configuration file.

=cut

sub dump {
    my $self = shift;
    return $config_file->slurp;
}


=method get

    my $value = $config->get( $section, $key );

Return the value associated to C<$key> in the wanted C<$section>.

=cut

sub get {
    my ($self, $section, $key) = @_;
    return $self->_config->{ $section }->{ $key };
}


=method set

    $config->set( $section, $key, $value );

Store the C<$value> associated to C<$key> in the wanted C<$section>.

=cut

sub set {
    my ($self, $section, $key, $value) = @_;
    my $config = $self->_config;
    $config->{ $section }->{ $key } = $value;
    $config->write( $config_file );
}


1;
__END__

=head1 SYNOPSIS

    my $config = App::Magpie::Config->instance;
    my $value  = $config->get( $section, $key );
    $config->set( $section, $key, $value );


=head1 DESCRIPTION

This module allows to store some configuration for magpie.

It implements a singleton responsible for automatic retrieving & saving
of the various information. No check is done on sections and keys, so
it's up to the caller to implement a proper config hierarchy.

