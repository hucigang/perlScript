#!/usr/bin/perl -w
package App::processDBLocks;
use DBTable;
use vars qw($VERSION);

BEGIN {
	$App::DBLocks::VERSION = "1.01";
}

sub check {
	my $class = shift;
	my $prop = shift;

	my ($warning_wait, $kill_wait) = split(/,/, $prop->{WAIT_LOCK});
	my ($warning_dead, $kill_dead) = split(/,/, $prop->{DEAD_LOCK});
	my ($warning_amount, $kill_warning) = split(/,/, $prop->{AMOUNT_LOCK});
	my @exception = split(/,/, $prop->{EXCEPTION});

	# name 值  在对应的State 中需要用到
#	$CrmZBPlan::attr->[0]->register(
#                name    =>  "dbasuper",
#                type    =>  "oracle",
#                dbname  =>  $prop->{DBNICK}->{DBNAME},
#                user    =>  $prop->{DBNICK}->{USER},
#                passwd  =>  $prop->{DBNICK}->{PASSWD},
#            );
	print "$warning_wait, $kill_wait, $warning_dead, $kill_dead, $warning_amount, $kill_warning\n";
	my @result;
	my $dbname;
	my $sql = <<END 
select 'Wait' "Status", a.username, a.machine, a.sid, a.serial#, a.last_call_et "Seconds", b.id1, c.sql_text "SQL", a.program
from v\$session a, v\$lock b, v\$sqltext c where a.username is not null and a.lockwait = b.kaddr and c.hash_value =a.sql_hash_value union select 'Lock' "Status", a.username, a.machine, a.sid, a.serial#, a.last_call_et "Seconds", b.id1, c.sql_text "SQL", a.program from v\$session a, v\$lock b, v\$sqltext c where b.id1 in (select distinct e.id1 from v\$session d, v\$lock e where d.lockwait = e.kaddr) and a.username is not null and a.sid = b.sid and b.request=0 and c.hash_value =a.sql_hash_value
END
;
	
#	my ($state, $value) =  $CrmZBPlan::attr->[0]->_sql(name=>"dbasuper", sqlstring => $sql);
	my ($state, $value) =  DBTable->send_selectsql_to_agent($sql);
	my (@waits, @locks);
	my $st = undef;
	if ($kill_warning != 0 && scalar(@{$value}) >= $kill_warning){
		print "Eneter All\n" if ($CrmDef::debug);
		foreach (@{$value}){
			my ($status, $username, $machine, $sid, $serial, $seconds, $id1, $sql, $program) = @{$_};
			push @waits, \@{[1, 1, $_]} if ($status eq "Wait");
			push @locks, \@{[1, 1, $_]} if ($status eq "Lock");
		}
		$st = "CHECK_DBLOCK_KILL_STATE" if (!defined($st));
	}elsif ($warning_amount != 0 && scalar(@{$value}) >= $warning_amount){
		print "Eneter Waring All\n" if ($CrmDef::debug);
		foreach (@{$value}){
			my ($status, $username, $machine, $sid, $serial, $seconds, $id1, $sql, $program) = @{$_};
			push @waits, \@{[0, 1, $_]} if ($status eq "Wait");
			push @locks, \@{[0, 1, $_]} if ($status eq "Lock");
		}
		$st = "CHECK_DBLOCK_WARNNING_STATE" if (!defined($st));
	}else{
		foreach (@{$value}){
			my ($status, $username, $machine, $sid, $serial, $seconds, $id1, $sql, $program) = @{$_};
			my ($k, $w) = (0, 0);
			if ($status eq "Wait"){
				if ($kill_wait != 0 && $seconds >= $kill_wait*60){
					($k, $w) = (1, 1);
					$st = "CHECK_DBLOCK_KILL_STATE" if (!defined($st));
				}elsif ($warning_wait != 0 && $seconds >= $warning_wait*60){
					($k, $w) = (0, 1);
					$st = "CHECK_DBLOCK_WARNNING_STATE" if (!defined($st));
				}
				$k = 0 if ($kill_dead eq 0);
				$w = 0 if ($warning_dead eq 0);
				print "Get State $k, $w\n" if ($CrmDef::debug);
				push @waits, \@{[$k, $w, $_]};
			}	

			if ($status eq "Lock") {
				if ($kill_dead != 0 && $seconds >= $kill_dead*60){
					($k, $w) = (1, 1);
					$st = "CHECK_DBLOCK_KILL_STATE" if (!defined($st));
				}elsif ($warning_dead != 0 && $seconds >= $warning_dead*60){
					($k, $w) = (0, 1);
					$st = "CHECK_DBLOCK_WARNNING_STATE" if (!defined($st));
				}
				$k = 0 if ($kill_dead eq 0);
				$w = 0 if ($warning_dead eq 0);
				print "Get State $k, $w\n" if ($CrmDef::debug);
				push @locks, \@{[$k, $w, $_]};
			}
		}
		
	}	

	for my $i (0 .. $#waits){
		my ($k, $w, $v) = @{$waits[$i]};
		my ($status, $username, $machine, $sid, $serial, $seconds, $id1, $sql, $program) = @{$v};

		foreach (@exception){
			if ($program =~ m/$_/i){
				$waits[$i][0] = 0;
				
			}
		}
	}
	for my $i (0 .. $#locks){
		my ($k, $w, $v) = @{$locks[$i]};
		my ($status, $username, $machine, $sid, $serial, $seconds, $id1, $sql, $program) = @{$v};

		foreach (@exception){
			if ($program =~ m/$_/i){
				$locks[$i][0] = 0;
			}
		}
	}

	push @result, (\@waits, \@locks);

if ($CrmDef::debug > 2) {
	print "====================\n";
	foreach my $waiddt (@result){
		foreach (@{$waiddt}){
			print "----------------------\n";
			print @{$_->[2]};
			print "\n----------------------\n";
		}
	}
	print "====================\n";
}	
	$st = "CHECK_DBLOCK_FINISH_STATE" if (!defined($st));	

	return ($st, \@result);
}

1;
