#!/usr/bin/perl -w
package App::DiskInfoCheck;
use vars qw($VERSION);
use Shell;
BEGIN {
	$App::DiskInfoCheck::VERSION = "1.01";
}

sub check {
	my $class = shift;
	my $prop = shift;

	my $sh = Shell->new;
   	my @arr = $sh->df();

	shift @arr if ($CrmDef::DiskInfoType);
	my ($number, $j) = (0, 0);
	map {
		my ($line) = $_;
		map {
			my $real = $_;
			$real =~ s/[ \t\n\r\f%]//g;
			if (length($real) > 0){
				push @{$values[$number]}, $real;
				$j++;
				if ($j eq scalar(@{$CrmDef::DiskInfo})){
					$number++;
					$j = 0;
				}
			}
		} split(/ /, $line);
	}@arr;	
if ($CrmDef::debug) {
	print "====================\n";
	for my $c (0 .. $number){
		for my $v (0 .. scalar(@{$CrmDef::DiskInfo})-1){
			print $values[$c][$v]." ";
		}
		print "\n";
	}
	print "====================\n";
}
	my @result;
	my $p = 0;
	foreach (@{$CrmDef::DiskInfoCheck}){
		next if ($_ eq "TASKINFO" || $_ eq "TIMEOUT");
		my $pos;
		for my $c (0 .. scalar(@{$CrmDef::DiskInfo})-1){
			if ($CrmDef::DiskInfo->[$c] eq $_){
				$pos = $c;
			}
		}
		for my $c (1 .. $number){
			if ($prop->{$_} =~ /[0-9]+/ && $values[$c][$pos] =~ /[0-9]+/ 
				&& length($values[$c][$pos]) > 0){	
				my $temp = ($prop->{$_} <= $values[$c][$pos]) ? 1 : 0;
				print "Compare $temp \n";
				$values[$c][$pos] .= "%";
				push @{$result[$c-1]}, 
					($temp, join "\t", @{$values[$c]});
			}else{
				print "Give 0\n";
				push @{$result[$c-1]}, (0, join "\t", @{$values[$c]});
			}
			print "Check $prop->{$_} <= $values[$c][$pos] | $result[$c-1]\n" if ($CrmDef::debug);
		}
	}
	#@{$values[0]} = @result;
if ($CrmDef::debug) {
	print "====================\n";
	#print join " ", @{$values[0]};
	print join " ", @result;
	print "====================\n";
}
	#return (CHECK_FINISH_STATE, \@values);
	return (CHECK_DISK_FINISH_STATE, \@result);
}

1;
