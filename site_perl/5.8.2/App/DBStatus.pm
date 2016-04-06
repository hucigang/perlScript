#!/usr/bin/perl -w
package App::DBStatus;
use vars qw($VERSION);

BEGIN {
	$App::DBStatus::VERSION = "1.02";
}

sub check {
	my $class = shift;
	my $prop = shift;

	my $result;

	my $sql = "select 0 from dual";


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
    ($st, $res) = MySocket->do($realval);

	$result = -1;
	$result = 1 if ($st eq 1);	
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

	return (CHECK_DB_FINISH_STATE, $result);
}

1;
