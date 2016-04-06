#!/usr/bin/perl -w
package App::LogInfo::WebLogic;
use vars qw($VERSION);

BEGIN {
	$App::LogInfo::WebLogic::VERSION = "1.01";
}

sub search {
	my $class = shift;
	my $prop = shift;
	
	return FINISH_STATE;	
}

1;
