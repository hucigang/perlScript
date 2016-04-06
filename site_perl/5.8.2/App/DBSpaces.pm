#!/usr/bin/perl -w
package App::DBSpaces;
use Config::IniFiles;
use Data::Dumper;
use vars qw($VERSION);

BEGIN {
	$App::DBSpaces::VERSION = "1.01";
}

sub check {
	my $class = shift;
	my $prop = shift;

	my $result;

	my $sql = <<END
SELECT A.TABLESPACE_NAME,A.BYTES TOTAL,B.BYTES USED, C.BYTES FREE,
ROUND((B.BYTES*100)/A.BYTES) USEDP
FROM SYS.SM\$TS_AVAIL A,SYS.SM\$TS_USED B,SYS.SM\$TS_FREE C
WHERE A.TABLESPACE_NAME=B.TABLESPACE_NAME AND A.TABLESPACE_NAME=C.TABLESPACE_NAME
END
;


	my %hash = ();
	my $cfg = new Config::IniFiles (-file => "$ENV{HOME}/etc/auto.cfg");
    $hash{url} = $cfg->val($prop->{DBNAME}, "url");
    $hash{user} = $cfg->val($prop->{DBNAME}, "user");
    $hash{passwd} = $cfg->val($prop->{DBNAME}, "passwd");
    $hash{encoding} = $cfg->val($prop->{DBNAME}, "encoding");


	$alti_select = "ORA_SELECT";
    chomp($sql);

    my $val = length($alti_select)+length($hash{url})+length($hash{user})+length($hash{passwd})+length($hash{encoding})+length($sql)+5;

    my $realval = sprintf ("%06d%s^%s^%s^%s^%s^%s", $val, $alti_select, $hash{url}, $hash{user}, $hash{passwd}, $hash{encoding}, $sql);
	my ($st, $res) = MySocket->do($realval);

	my @arr = split/\|/, $res;

	my @result;
	foreach my $cccc (@arr){
		my @vvvv = split/\#/, $cccc;
		if ($vvvv[$#vvvv] gt $prop->{PRE}){
			push @result, \@{[1, \@vvvv]};
		}else{
			push @result, \@{[0, \@vvvv]};
		}
	}

#	my $db;	

#	eval{
#	$db = Utils::Oracle->connect(dbname=>$prop->{DBNAME}, user=>$prop->{USER}, passwd=>$prop->{PASSWD});
#	$result = $db->{dbhandle}->{Active};
#	$result = 1;
	
#	$db->disconnect();	
#	};
#	if ($@){
#		$result= -1;
#	}

	$st = "CHECK_DB_FINISH_STATE" if ($st eq 1);

    return ($st, \@result);
}

1;
