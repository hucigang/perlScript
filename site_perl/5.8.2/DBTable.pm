#!/usr/bin/perl -w
package DBTable;
#use Utils::OracleManage;
use MySocket;
use Config::IniFiles;
use vars qw($VERSION);

$DBTable::souce = "CrmZBPlan.pm";

BEGIN {
	$DBTable::VERSION = "1.01";
}

=head1 NAME

        数据表操作功能

=head1 SYNOPSIS

        数据表操作功能

=head1 DESCRIPTION

	auto_inspect_step_result的insert,update语句, 语句所需的信息均从CrmZBPlan中获取
	update修改字段为IS_RIGHT, INFO, END_TIME

=head1 USAGE

#insert 
DBTable->auto_inspect_step_result(0);

#update 
DBTable->auto_inspect_step_result(1);

=head1 METHODS 

=head2 auto_inspect_step_result ( [-option=>value ...] )

写入或修改auto_inspect_step_result

=over 10 

=item I<isupdate> 是否为update

0 为 insert
1 为 update

=back 

=cut

sub get_ora_from_config{
	my $class = shift;
	my $mask = shift;

	$mask = "crmdata";
	my %hash = ();

	my $cfg = new Config::IniFiles (-file => "$ENV{HOME}/etc/auto.cfg");

	$hash{url} = $cfg->val($mask, "url");
	$hash{user} = $cfg->val($mask, "user");
	$hash{passwd} = $cfg->val($mask, "passwd");
	$hash{encoding} = $cfg->val($mask, "encoding");
	$hash{sqlurl} = $cfg->val($mask, "sqlurl");
	$hash{sqluser} = $cfg->val($mask, "sqluser");
	$hash{sqlpasswd} = $cfg->val($mask, "sqlpasswd");
#	$hash{url} = "jdbc:oracle:thin:\@132.35.77.29:1521:oradev1";
#	$hash{user} = "AIBGAT";
#	$hash{passwd} = "AIBGAT";
#	$hash{encoding} = "A";
	
	return \%hash;	
}

sub send_selectsql_to_agent{
	my $class = shift;
	(my $sql,my $mark) = @_;
	my ($st, $res);
	
    my $orac = DBTable->get_ora_from_config();
	
	my ($alti_select);

	print " sql: $sql\n";
	$alti_select = "ORA_SELECT";
    if (defined($mark)&& $mark eq 1){
        $alti_select = "SQL_SELECT";
        $orac->{url} = $orac->{sqlurl};
        $orac->{user} = $orac->{sqluser};
        $orac->{passwd} = $orac->{sqlpasswd};
    }
	chomp($sql);

	my $val = length($alti_select)+length($orac->{url})+length($orac->{user})+length($orac->{passwd})+length($orac->{encoding})+length($sql)+5;

	my $realval = sprintf ("%06d%s^%s^%s^%s^%s^%s", $val, $alti_select, $orac->{url}, $orac->{user}, $orac->{passwd}, $orac->{encoding}, $sql);
	
	($st, $res) = MySocket->do($realval);

	print $res."\n";
	my @arr = split/\|/, $res;

     
	
	return ($st, $res) if ($#arr eq 0);

	return ($st, \@arr);
}

sub send_sql_to_agent{
	my $class = shift;
	my ($sql, $mark) = @_;
	my ($st, $res);

    my $orac = DBTable->get_ora_from_config();
    
	my ($alti_select);

    $alti_select = "ORA_UPDATE";
    if (defined($mark)&& $mark eq 1){
        $alti_select = "SQL_UPDATE";
        $orac->{url} = $orac->{sqlurl};
        $orac->{user} = $orac->{sqluser};
        $orac->{passwd} = $orac->{sqlpasswd};
    }
    
	chomp($sql);

	my $val = length($alti_select)+length($orac->{url})+length($orac->{user})+length($orac->{passwd})+length($orac->{encoding})+length($sql)+5;

	my $realval = sprintf ("%06d%s^%s^%s^%s^%s^%s", $val, $alti_select, $orac->{url}, $orac->{user}, $orac->{passwd}, $orac->{encoding}, $sql);
	($st, $res) = MySocket->do($realval);

	return ($st, $res);
}

sub auto_inspect_step_result{
	my $class = shift;
	my ($isupdate) = shift;
	my ($sql);

	require $DBTable::souce;

	my ($dbname, $task_id, $test_no, $seq_id, $step_name, $step_type);
#if ( $^O =~ /MSWin32/ ) {
#	$dbname    = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{DBNICK}->{NICK};
#}else{
	$dbname    = "config";
#}
	$task_id   = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{TASKINFO}->{TASK_ID};
	$test_no   = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{TASKINFO}->{TEST_NO};
	$seq_id    = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{TASKINFO}->{SEQ_ID};

	print "In write db log $CrmZBPlan::pos $task_id $test_no $seq_id \n" if ($CrmDef::debug);
	return -1 unless (defined($task_id) || defined($test_no) || defined($seq_id));

	$step_name = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{TASKINFO}->{STEP_NAME};
	$step_type = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{TASKINFO}->{STEP_TYPE};

	my ($is_right, $info);
	if ($isupdate eq 0){
		return -2 unless (defined($step_name) || defined($step_type)); 
		
		$sql = <<END 
INSERT INTO AUTO_INSPECT_STEP_RESULT ( TASK_ID, TEST_NO, SEQ_ID, IS_RIGHT, INFO, START_TIME, END_TIME, STEP_NAME, STEP_TYPE, STEP_RESULT_ID) VALUES ( $task_id, $test_no, $seq_id, 'N', '获取计划ID信息完成,未处理', sysdate, null, '$step_name', $step_type, AUTO_INSPECT_STEP_RESULT_SEQ.nextval)
END
;
	}else{

		$info      = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{FUNCINFO};
		print "Current $CrmZBPlan::attr->[$CrmZBPlan::pos]->{FUNCSTATE}\n" if ($CrmDef::debug);
		$is_right  = ($CrmZBPlan::attr->[$CrmZBPlan::pos]->{FUNCSTATE} gt 0) ? 'Y' : 'N';
		print "Convert $is_right\n" if ($CrmDef::debug);

		return -3 unless (defined($is_right)); 
		
		$info = "NULL" unless (defined($info));
		
		$info =~ s/'//g;
		$info =~ s/;//g;
		#$info =~ s/ where / wh ere /g;
		#$info =~ s/ from / form /g;
		print "===================\n";
		print $info;
		print "===================\n";
		
		if (length($info) > 4000){
			$class->auto_inspect_step_result_mult();
			return 0;	
		}

		$sql = <<END
UPDATE AUTO_INSPECT_STEP_RESULT SET    IS_RIGHT   = '$is_right', INFO       = '$info', END_TIME   = sysdate WHERE  TASK_ID    = $task_id AND    TEST_NO    = $test_no AND    SEQ_ID     = $seq_id
END
;
		}
		print $sql if ($CrmDef::debug);
		# 这里name为固定cfg 写入配置表 不需要指定数据库名
	no strict 'refs';
	#my ($state, $value) =  $CrmZBPlan::attr->[0]->_sql(name=>$dbname, sqlstring => $sql);	
	my ($state, $value) =  DBTable->send_sql_to_agent($sql);
	#print $state;
	return 0;	
}

sub auto_inspect_step_result_mult{
	my $class = shift;

	my $mask = "<BR>";
	my ($dbname, $task_id, $test_no, $seq_id, $step_name, $step_type);
	my ($is_right, $info);
	$dbname    = "config";
	$task_id   = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{TASKINFO}->{TASK_ID};
	$test_no   = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{TASKINFO}->{TEST_NO};
	$seq_id    = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{TASKINFO}->{SEQ_ID};
	$step_name = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{TASKINFO}->{STEP_NAME};
	$step_type = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{TASKINFO}->{STEP_TYPE};
	$info      = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{FUNCINFO};
	$is_right  = ($CrmZBPlan::attr->[$CrmZBPlan::pos]->{FUNCSTATE} gt 0) ? 'Y' : 'N';

	$info =~ s/'//g;
        $info =~ s/;//g;

	my ($tmp, $val, $sql);
	my ($start, $end, $pos) = (0, 0, 0);

	while (1){
		print "Start $start length info".length($info)."\n" if ($CrmDef::debug);
		last if ($start >= length($info));
		$tmp = substr($info, $start, 4000);
		$pos = rindex($tmp, $mask);
		if ($pos > 0) {
			$pos += length($mask);
			$val = substr($info, $start, $pos); 
			print "\n";
		}else{
			$val = substr($info, $start, 4000); 
			#$val = "数据异常";
			$pos = 4000;
		}
		print "Get [$val] $pos\n" if ($CrmDef::debug);
		if ($start eq 0) {
			$sql = <<END
UPDATE AUTO_INSPECT_STEP_RESULT SET    IS_RIGHT   = '$is_right', INFO       = '$val', END_TIME   = sysdate WHERE  TASK_ID    = $task_id AND    TEST_NO    = $test_no AND    SEQ_ID     = $seq_id
END
;
		}else{
			$sql = <<END
INSERT INTO AUTO_INSPECT_STEP_RESULT ( TASK_ID, TEST_NO, SEQ_ID, IS_RIGHT, INFO, START_TIME, END_TIME, STEP_NAME, STEP_TYPE, STEP_RESULT_ID) VALUES ( $task_id, $test_no, $seq_id, '$is_right', '$val', '', sysdate, '$step_name', $step_type, AUTO_INSPECT_STEP_RESULT_SEQ.nextval)
END
;
}
		no strict 'refs';
    #	my ($state, $value) =  $CrmZBPlan::attr->[0]->_sql(name=>$dbname, sqlstring => $sql);
	my ($state, $value) =  DBTable->send_sql_to_agent($sql);
		$start += $pos;
	};

}

sub auto_inspect_case_result{
	my $class = shift;
	my ($sql);

	require $DBTable::souce;

	my ($dbname, $task_id, $test_no, $seq_id);
	
	$dbname    = "config";
	$task_id   = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{TASKINFO}->{TASK_ID};
	$test_no   = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{TASKINFO}->{TEST_NO};

	print "In write db log $CrmZBPlan::pos $task_id $test_no \n" if ($CrmDef::debug);
	return -1 unless (defined($task_id) || defined($test_no));

		$sql = <<END
UPDATE AUTO_INSPECT_CASE_RESULT SET    OVER_STEP_NUM  = OVER_STEP_NUM+1 WHERE  TASK_ID        = $task_id AND    TEST_NO        = $test_no
END
;


	print $sql if ($CrmDef::debug);
	# 这里name为固定config 写入配置表 不需要指定数据库名
	no strict 'refs';
	#my ($state, $value) =  $CrmZBPlan::attr->[0]->_sql(name=>$dbname, sqlstring => $sql);	
	my ($state, $value) =  DBTable->send_sql_to_agent($sql);
	print "State : $state, Value: $value\n";


	return 0;
}

=head1 AUTHOR and ACKNOWLEDGEMENTS

        hucg@asiainfo-linkage.com

=cut

1;
