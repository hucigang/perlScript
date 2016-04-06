#!/usr/bin/perl -w
package App::TestWeblogic;
use vars qw($VERSION);
use LWP::Simple;
use Shell;
BEGIN {
	$App::TestWeblogic::VERSION = "1.01";
}

sub check {
	my $class = shift;
	my $prop = shift;

	my @result;
	my $ccc = get($prop->{TESTPAGE});

	my @c = split/\n/, $ccc;
	my $err = 1;	
	my $count = 0;
	open (FIL, "$prop->{FILE}") || return (FILE_NOT_FOUND, "$prop->{FILE} not found");
	while (<FIL>){
		chomp;
		
		my $src = $c[$count++];
		s/\s//g;
		$src =~ s/\s//g;
		if ($_ eq $src){
		}else{
			$err = -1;
			last;
		}
	};
    close(FIL);
	print ".$err.\n";
	push @result, $err;
	
	return (CHECK_FINISH_STATE, \@result);
}

1;
