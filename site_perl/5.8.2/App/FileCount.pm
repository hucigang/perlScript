#!/usr/bin/perl -w
package App::FileCount;
use vars qw($VERSION);

BEGIN {
	$App::FileCount::VERSION = "1.01";
}

sub count {
	my $class = shift;
	my $prop = shift;

	my (@result);
	if (substr($prop->{PATH}, length($prop->{PATH})-1) eq '/') {
		$prop->{PATH}[length($prop->{PATH})-1] = '';
	}

	opendir(DIR, $prop->{PATH}) || 
			return (CHECK_FILE_NOT_FOUND, "can¡¯t opendir $some_dir: $!");
	@dots = grep { /^$prop->{REGEX}/ && -f "$prop->{PATH}/$_" } readdir(DIR);

    closedir DIR;	
	push @result, scalar(@dots);

	return (CHECK_PATH_FINISH_STATE, \@result);
}

1;
