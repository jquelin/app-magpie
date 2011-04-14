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

package App::Magpie::Action::FixSpec;
BEGIN {
  $App::Magpie::Action::FixSpec::VERSION = '1.111040';
}
# ABSTRACT: fixspec command implementation

use Moose;
use Parse::CPAN::Meta   1.4401; # load_file
use Path::Class         0.22;   # dir->basename
use Text::Padding;

with 'App::Magpie::Role::Logging';
with 'App::Magpie::Role::RunningCommand';



sub run {
    my ($self) = @_;

    # check if there's a spec file to update...
    my $specdir = dir("SPECS");
    -e $specdir or $self->log_fatal("cannot find a SPECS directory, aborting");
    my @specfiles =
        grep { /\.spec$/ }
        $specdir->children;
    scalar(@specfiles) > 0
        or $self->log_fatal("could not find a spec file, aborting");
    scalar(@specfiles) < 2
        or $self->log_fatal("more than one spec file found, aborting");
    my $specfile = shift @specfiles;
    my $spec = $specfile->slurp;
    $self->log( "fixing $specfile" );

    # extracting tarball
    $self->log_debug( "removing previous BUILD directory" );
    dir( "BUILD" )->rmtree;
    $self->run_command( "bm -lp" );
    my $distdir  = dir( glob "BUILD/*" );
    my $metafile = -e $distdir->file("META.json")
        ? $distdir->file("META.json")
        : -e $distdir->file("META.yml")
            ? $distdir->file("META.yml") : undef;

    # cleaning spec file
    $self->log_debug( "removing mandriva macros" );
    $spec =~ s/^%if %{mdkversion}.*?^%endif$//msi;

    $self->log_debug( "removing buildroot, not needed anymore" );
    $spec =~ s/^buildroot:.*\n//mi;

    $self->log_debug( "trimming empty end lines" );
    $spec =~ s/\n+\z//;

    # splitting up build-/requires
    $self->log_debug( "splitting (build-)requires one per line" );
    $spec =~ s{^((?:build)?requires):\s*(.*)$}{
        my $key = $1; my $value = $2; my $str;
        $str .= $key . ": $1\n" while $value =~ m{(\S+(\s*[>=<]+\s*\S+)?)\s*}g;
        $str;
    }mgie;

    # fetching buildrequires from meta file
    if ( defined $metafile ) {
        $self->log_debug( "using META file to get buildrequires" );
        $spec =~ s{^buildrequires:\s*perl\(.*\).*$}{}mgi;
        my $meta = Parse::CPAN::Meta->load_file( $metafile );
        my %br_from_meta;
        if ( $meta->{"meta-spec"}{version} < 2 ) {
            %br_from_meta = (
                %{ $meta->{configure_requires} // {} },
                %{ $meta->{build_requires}     // {} },
                %{ $meta->{test_requires}      // {} },
                %{ $meta->{requires}           // {} },
            );
        } else {
            my $prereqs = $meta->{prereqs};
            %br_from_meta = (
                %{ $prereqs->{configure}{requires} // {} },
                %{ $prereqs->{build}{requires}     // {} },
                %{ $prereqs->{test}{requires}      // {} },
                %{ $prereqs->{runtime}{requires}   // {} },
            );
        }

        my $rpmbr;
        foreach my $br ( sort keys %br_from_meta ) {
            next if $br eq 'perl';
            my $version = $br_from_meta{$br};
            $rpmbr .= "BuildRequires: perl($br)";
            if ( $version != 0 ) {
                my $rpmvers = qx{ rpm -E "%perl_convert_version $version" };
                $rpmbr .= " >= $rpmvers";
            }
            $rpmbr .= "\n";
        }

        if ( $spec =~ /buildrequires/i ) {
            $spec =~ s{^(buildrequires:.*)$}{$rpmbr$1}mi;
        } elsif ( $spec =~ /buildarch/i ) {
            $spec =~ s{^(buildarch.*)$}{$rpmbr$1}mi;
        } else {
            $spec =~ s{^(source.*)$}{$1\n\n$rpmbr}mi;
        }
    }

    $spec =~ s{^((?:build)?requires:.*)\n+}{$1\n}mgi;

    # lining up / padding
    my $pad = Text::Padding->new;
    $self->log_debug( "lining up categories" );
    $spec =~
        s{^(Name|Version|Release|Epoch|Summary|License|Group|Url|Source\d*|Patch\d*|BuildArch|Requires|Obsoletes|Provides):\s*}
         { $pad->left( ucfirst(lc($1)) . ":", 12 ) }mgie;
    $spec =~ s{^source:}{Source0:}mgi;
    $spec =~ s{^patch:}{Patch0:}mgi;
    $spec =~ s{^buildrequires:}{BuildRequires:}mgi;
    $spec =~ s{^buildarch:}{BuildArch:}mgi;

    # updating %doc
    $self->log_debug( "fetching documentation files" );
    my @docfiles =
        sort
        grep { ! /^MANIFEST/ }
        grep { /^[A-Z]+$/ || m{^(Change(s|log)|META.(json|yml)|eg|examples)$}i }
        map  { $_->basename }
        $distdir->children;
    if ( @docfiles ) {
        $self->log_debug( "found: @docfiles" );
        if ( $spec =~ /^%doc (.*)/m ) {
            $self->log_debug( "updating %doc" );
            $spec =~ s/^(%doc .*)$/%doc @docfiles/m;
        } else {
            $self->log_debug( "adding a %doc" );
            $spec =~ s/^%files$/%files\n%doc @docfiles/m;
        }
    } else {
        $self->log_debug( "no documentation found" );
    }

    # other things that might be worth checking...
        # perl-version instead of perl(version)
        # url before source
        # source:  http://www.cpan.org/modules/by-module/Algorithm/
        #  Url:        http://search.cpan.org/dist/%{upstream_name}
        # license
        # rpmlint ?
        # sorting buildrequires
        # %description\n\n
        # $RPM_BUILD_ROOT
        #  %{upstream_name} module for perl within summary
        # "perl module" within summary
        # "module for perl" within summary
        # %{upstream_name}  within description
        # requires with buildrequires
        # requires perl
        # no %check
        # %upstream instead of %{upstream...}
        # perl-devel alongside noarch
        # within %install et %clean: [ "%{buildroot}" != "/" ] && rm -rf %{buildroot}
        # "no summary found"
        # "no description found"
        # make test without %check
        # %modprefix


    # removing extra newlines
    $spec =~ s{\n{3,}}{\n\n}g;

    # writing down new spec file
    $self->log_debug( "writing updated spec file" );
    my $fh = $specfile->openw;
    $fh->print($spec);
    $fh->close;
}



1;


=pod

=head1 NAME

App::Magpie::Action::FixSpec - fixspec command implementation

=head1 VERSION

version 1.111040

=head1 SYNOPSIS

    my $fixspec = App::Magpie::Action::FixSpec->new;
    $fixspec->run;

=head1 DESCRIPTION

This module implements the C<fixspec> action. It's in a module of its
own to be able to be C<require>-d without loading all other actions.

=head1 METHODS

=head2 run

    $fixspec->run;

Fix the spec file to match a set of rules. Make sure buildrequires are
correct.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

