package EvalServer::Config;

use v5.20.0;

use strict;
use warnings;
use TOML;
use FindBin;
use File::Slurper qw/read_text/;
use Data::Dumper;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/config/;

our $config;

sub load_config {
  my $file = $FindBin::Bin."/../etc/config.toml";

  my $data = read_text($file, "utf-8", "auto");

  my $makemagic = sub {
    my $value = shift;

    if (ref $value eq 'HASH') {
      my $nv = +{map {; $_ => __SUB__->($value->{$_})} keys %$value};
      return bless $nv, "EvalServer::Config::_magichash";
    } elsif (ref $value eq 'ARRAY') {
      return [map {__SUB__->($_)} @$value];
    } else {
      return $value;
    }
  };
  
  $config = $makemagic->(TOML::from_toml($data));
}

sub config {
  my ($section) = @_;
  if (!defined $config) {
    load_config();
  };

  return $config;
}

package
  EvalServer::Config::_magichash;
use Carp qw/croak/;

sub DESTROY {}

our $AUTOLOAD;
sub AUTOLOAD {
  my ($self) = @_;
  my $pack = __PACKAGE__;
  my $meth = $AUTOLOAD;
  $meth =~ s/^${pack}:://;

  if (exists $self->{$meth}) {
      return $self->{$meth};
  } else {
    croak "Config key [$meth] not found" if ($ENV{DEBUG});
    return undef;
  }
}

1;
