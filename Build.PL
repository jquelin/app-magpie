
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Mageia Perl Integration Easy",
  "dist_author" => [
    "Jerome Quelin <jquelin\@gmail.com>"
  ],
  "dist_name" => "App-Magpie",
  "dist_version" => "1.113120",
  "license" => "perl",
  "module_name" => "App::Magpie",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "App::Cmd::Setup" => 0,
    "CPAN::Mini" => 0,
    "Config::Tiny" => 0,
    "Encode" => 0,
    "File::Copy" => 0,
    "File::HomeDir::PathClass" => 0,
    "File::ShareDir::PathClass" => 0,
    "File::pushd" => 0,
    "FindBin" => 0,
    "LWP::UserAgent" => 0,
    "List::MoreUtils" => 0,
    "Log::Dispatchouli" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::Has::Sugar" => 0,
    "MooseX::SemiAffordanceAccessor" => 0,
    "MooseX::Singleton" => 0,
    "Parse::CPAN::Meta" => "1.4401",
    "Parse::CPAN::Packages::Fast" => 0,
    "Path::Class" => "0.22",
    "Proc::ParallelLoop" => 0,
    "Text::Padding" => 0,
    "URPM" => 0,
    "perl" => "5.012",
    "strict" => 0,
    "version" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/magpie"
  ],
  "share_dir" => {
    "dist" => "share"
  }
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
