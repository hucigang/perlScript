#!/usr/bin/perl -w
package App::UnInfo;
use vars qw($VERSION);

BEGIN {
	$App::UnInfo::VERSION = "1.01";
}

sub search {
	my $class = shift;
	my $prop = shift;

	return FINISH_STATE;	
}

1;
