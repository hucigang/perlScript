package App::UpdateLogFile;
use vars qw($VERSION);
use Calendar;
use Date::Format;
use Time::Simple;

BEGIN {
	$App::UpdateLogFile::VERSION = "1.01";
}

sub create_hash{
	my $class = shift;
	my ($fmt, $value) = @_;

	my %rel = (
    'y' => 0,
    'm' => 0,
    'd' => 0,
    'h' => 0,
    'M' => 0,
    's' => 0);

	my $c = substr($fmt, 0, 1);

	my ($start, $end) = (0, 0);
	for my $i (1 .. length($fmt)){
		my $tmp = substr($fmt, $i, 1);
		if ($tmp eq $c) {
			$end++;
			next;
		}else{
			$rel{$c} = substr($value, $start, $end-$start+1) if (exists $rel{$c});
			$end++;
			$start = $end;
			$c = $tmp;
		}
		if ($i eq length($fmt)-1){
			$rel{$c} = substr($value, $start, $end-$start+1) if (exists $rel{$c});
		}
	}
	$rel{y}  = "20".$rel{y} if (length($rel{y}) eq 2);;	
	return \%rel;
}

sub compare{
	my $class = shift;
	my ($log, $now, $se) = @_;

	my ($st, $res);	
	my $log_date = Calendar->new_from_Gregorian($log->{m}, $log->{d}, $log->{y});
	my $now_date = Calendar->new_from_Gregorian($now->{m}, $now->{d}, $now->{y});
	my $log_time = Time::Simple->new("$log->{h}:$log->{M}:$log->{s}");
    my $now_time = Time::Simple->new("$now->{h}:$now->{M}:$now->{s}");
	
	my $diff = $now_date-$log_date;
	my $second = $now_time - $log_time;
	my ($p) = -1;
	if ($diff >= 0) {
		if ($now->{h} > $log->{h}){
			$p = 1;
		}elsif ($now->{h} eq $log->{h} && $now->{M} > $log->{M}){
			$p = 1;
		}elsif ($now->{h} eq $log->{h} && $now->{M} eq $log->{M} && $now->{s} > $log->{s}){
			$p = 1;
		}
		# 当前日期比日志日期晚, 当前时间 > 日志时间  $p = 1
		# 						当前时间 < 日志时间  $p = -1
		if ($p eq -1){
			$diff = $diff - 1;
			$second = 86400-$second;
		}
	}else{
		if ($now->{h} < $log->{h}){
			$p = 1;
		}elsif ($now->{h} eq $log->{h} && $now->{M} < $log->{M}){
			$p = 1;
		}elsif ($now->{h} eq $log->{h} && $now->{M} eq $log->{M} && $now->{s} < $log->{s}){
			$p = 1;
		}
		# 当前日期比日志日期早, 当前时间 < 日志时间  $p = 1
		# 						当前时间 > 日志时间  $p = -1
		$second = -$second;
		if ($p eq -1){
			$diff = $diff + 1;
			$second = -86400 - $second;
		}
	}
	
	$diff = $diff + 1 if ($second eq 86400);

	$res = "There is $diff day $second second between [LOG]".
 		$log_date->date_string("%D")." ".$log_time->format("%H-%M-%S")." and [NOW]".
		$now_date->date_string("%D")." ".$now_time->format("%H-%M-%S").
		" Exp :$se \n";

	$st = 1;
	$st = -1 if ($diff*86400+$second > $se);
	
	return ($st, $res);
	
}

sub check {
	my $class = shift;
	my $prop = shift;


	my @result;
	
	tie *BW, 'File::ReadBackwards', $prop->{FILENAME} or
                        return (FILE_NOT_FOUND, "can't read $prop->{FILENAME} $!");

	my ($value);
	while (<BW>){ $value = $_; last if (defined($value) && length($value) > $prop->{END} - $prop->{START});}

	$value = substr($value, $prop->{START}-1, $prop->{END}-1);

	my $fmt = $prop->{FMT};
	$fmt =~ s/[^ymdhMs]//g;
	$value =~ s/[^0-9a-zA-Z]//g;

	my $log = $class->create_hash($fmt, $value);

	my $now = $class->create_hash("mm/dd/yyyy hh:MM:ss", time2str("%m/%d/%Y %T", time));
	
	my ($st, $res) = $class->compare($log, $now, $prop->{SECOND});	
	push @result, ($st, $res);
	#print $fmt."\n";
	return (CHECK_FINISH_STATE, \@result);
}

1;
