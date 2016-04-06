#!/usr/bin/perl -w
package App::LogInfo::File;
use vars qw($VERSION);
use CrmDef;
use File::ReadBackwards;

BEGIN {
	$App::LogInfo::File::VERSION = "1.01";
}

sub search {
	my $class = shift;
	my $prop = shift;

	my $filename = $prop->{FILENAME};
	my $lines = $prop->{LINES};
	my $display = $prop->{DISPLAY};
	my @keys = @{$prop->{ATTR}};
	my $keyslen = @keys;

	tie *BW, 'File::ReadBackwards', $filename or
                        return (FILE_NOT_FOUND, "can't read $filename $!");
	
	my $max = 0;
	foreach my $v (@keys){
		next if (length($v->{UP}) <= 0);
		$max = $v->{UP} if ($max < $v->{UP});
	}

	my ($curline, @arr);
	$curline = 0;
	while(<BW>) {
		chomp;
		last if ($curline >= $lines+$max);
		push @arr, $_;
		$curline++;
	}
	
	if ($curline < $lines) {
		print "$filename only $curline lines\n";
		$lines = $curline;
	}
	my $llen = $#arr;

	$curline = 0;

	my (@ups, @result);

	my ($poss) = 0;
	my $search = 0;
	my $skip = 0;
	my (@temp);
	for my $c (0 .. scalar(@arr)-1){
		my $src = $arr[scalar(@arr)-1-$c];
if (CrmDef::debug){
		print "Look $src\n";
}
		if ($max eq $poss){
			$search = 1;
		}
		if ($search && $skip eq 0){
			foreach my $key (@keys){
				my $real = $key->{KEY};
				next if (length($real) <= 0);
				next if ($skip gt 0);
				if ($src =~ m/$real/){
if (CrmDef::debug){
					print "Find $poss+$max, $key->{UP}, $key->{DOWN}\n";
					print "Content $src\n";
}
					push @temp, [$poss, $key->{UP}, $key->{DOWN}];
					$skip = $key->{DOWN};
				}
			}			
		}else{
			$skip-- if (!($skip eq 0));
		}

		$poss++;
	}
if (CrmDef::debug){
	print "============Data\n";
	print join "\n", @arr;
	print "\n============Data\n";
}
	my ($cs, $ce) = (0, 0);
	foreach my $cur (@temp) {
		my $start = $cur->[0] - $cur->[1];
		my $end   = $cur->[0] + $cur->[2];
		$end = $poss-1 if ($end > $poss);
		print "Start $start End $end\n"; 
	
		for my $cc ($start .. $end) {
			next if ($cc <= $ce && !($cc eq 0));
			next if ($cc > $poss);
			my $sts = $cc eq $cur->[0] ? 1 : 0;
			my $rss = $arr[scalar(@arr)-1-$cc];
			print "If $cc $sts $rss\n";
			push @result, [
				$sts,
				$rss];
				#$cc eq $cur->[0] ? 1 : 0,
				#pop @arr];
			
		}
		($cs, $ce) = ($start, $end);
	}
	if (scalar(@temp) eq 0){
		for (0 .. $max-1){
			pop @arr;
		}
		@result = @arr;
	}

if (CrmDef::debug){
	#print "============Result\n";
	#print map {$_->[0]."-".$_->[1]."\n"} @result;
	#print "============Result\n";
}
	# 找到 返回数组的数组 [a,b] a为1表示为关键字行 b 为实际内容	
	# 未找到 返回原始数组
	return (LOGFILE_FINISH_STATE, \@result);
}

1;
