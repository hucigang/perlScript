#!/usr/bin/perl -w
package App::DBInfo;
use vars qw($VERSION);

BEGIN {
	$App::DBInfo::VERSION = "1.01";
}

sub search {
	my $class = shift;
	my $prop = shift;
	
	return FINISH_STATE;
}

1;
