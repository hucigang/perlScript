#!/usr/bin/perl -w
use strict;
use CrmDef;
use DBTable;

package CrmState;
our @ISA = qw(Exporter);
use vars qw($VERSION);
BEGIN {
	$CrmState::VERSION = "1.01";
	
}
my ($write_db_log); 

%CrmState::CrmFuncs = (
	START_STATE => ['mine'],
	FINISH_STATE => ['mine'],
	LOGFILE_FINISH_STATE => ['color', 'print'],
	CHECK_FINISH_STATE => ['color', 'print'],
	CHECK_DISK_FINISH_STATE => ['color', 'print'],
	CHECK_DB_FINISH_STATE => ['print'],
	CHECK_PATH_FINISH_STATE => ['print'],
	FILE_NOT_FOUND => ['mine'],
	CHECK_FILE_NOT_FOUND => ['mine'],
	CHECK_FILE_FOUND => ['mine'],
	FUNC_ERR_STATE => ['mine'],
	PARAM_DATA_NOT_NAMES => ['mine'],
	PARAM_DATA_NOT_FOUND => ['mine'],
	PARAM_DATA_NOTEQ_NAMES => ['mine'],
	PARAM_SUB_ERROR_UNKOWN => ['mine'],
	CHECK_DBLOCK_FINISH_STATE => ['print'],
	CHECK_DBLOCK_WARNNING_STATE => ['warn', 'print'],
	CHECK_DBLOCK_KILL_STATE => ['kill', 'warn', 'print'],
	ST_FINISH_STATE => ['print'],
);

sub start{
	my $class = shift;

#	print "Start In $CrmZBPlan::pos\n";	
	$write_db_log = DBTable->auto_inspect_step_result(0);
}

sub end{
	my $class = shift;

	$write_db_log = DBTable->auto_inspect_step_result(1);
	$write_db_log = DBTable->auto_inspect_case_result(1);
}

sub process{
	my $class = shift;
	my ($rebless_class, $st1, $res) = @_;

	my ($st);
	print "Return In $CrmZBPlan::pos  $rebless_class\n" if ($CrmDef::debug);
	if ($st1 eq "PARAM_DATA_NOT_NAMES" 
		|| $st1 eq "PARAM_DATA_NOT_FOUND" 
		|| $st1 eq "PARAM_DATA_NOTEQ_NAMES" 
		|| $st1 eq "PARAM_SUB_ERROR_UNKOWN") {
		$write_db_log = DBTable->auto_inspect_step_result(0);
	}

	$res = $res || "";
	if ($rebless_class){
		no strict 'refs';
		foreach (@{$CrmState::CrmFuncs{$st1}}){
			printf "Get %s %s [$_]\n", $st1, &{"CrmDef::$st1"} if ($CrmDef::debug);
			($st, $res) = $rebless_class->process(&{"CrmDef::$st1"}, $res, $_);
		}
		#($st, $res) = $rebless_class->process(&{"CrmDef::$st"}, $res, $CrmState: Exp $st});
	}

	return ($st, $res);
}

sub color{
	my $class = shift;
	my $res = shift;

	print "Color .....$res\n";
	return $res;
	#<span style="background-color: rgb(255, 255, 0);">����</span>	
}

sub mine{
	my $class = shift;
	my $res = shift;

	return $res;
}

package CrmState::UnInfo;
our @ISA = qw(Exporter CrmState);
sub process{
	my $class = shift;
	my ($st, $res, $func) = @_;

	no strict "refs";
	$res = $class->$func($res);
	return $st, $res;
}

sub finish{
	my $class = shift;
	my $res = shift;

	#print "Enter UnInfo CrmState Finish\n";	
	return $res;
}

package CrmState::STInfo;
our @ISA = qw(Exporter CrmState);
sub process{
	my $class = shift;
	my ($st, $res, $func) = @_;

	if ($func eq "print"){
		print "STInfo  CrmState\n";
		$st = 1 if ($res->[0] eq 'Y');
		$st = -1 if ($res->[0] eq 'N');
	}
	no strict "refs";
	$res = $class->$func($res);
	
	return ($st, $res);
}

sub print{
	my $class = shift;
	my $res1 = shift;	
	my $count = 0;
	my $res = "";
	foreach (@{$res1}){
		$res .= $_."<BR>" if ($count > 0);
		$count++;
	}
	return $res;
}

package CrmState::LogInfo::File;
our @ISA = qw(Exporter CrmState);
sub process{
	my $class = shift;
	my ($st, $res, $func) = @_;

	my $find = 0;
	if ($func eq "print"){
		if (ref($res->[0]) eq "ARRAY"){
			$find = 1;
		}
		$st = -1;
		$st = 1 if ($find eq $CrmZBPlan::attr->[$CrmZBPlan::pos]->{EXPSTATUS});
		print "Get Last Status $st\n";
	}
	no strict "refs";
	$res = $class->$func($res);
	
	if ($func eq "print"){
		if ($find eq 0 &&  $CrmZBPlan::attr->[$CrmZBPlan::pos]->{DISPLAY} eq "N"){
			$res = "δ�ҵ��ؼ���";
			foreach (@{$CrmZBPlan::attr->[$CrmZBPlan::pos]->{ATTR}}){
				$res .= "[".$_->{KEY}."]" if (length($_->{KEY}) > 0);
			}
		}
	}

	return ($st, $res);
}

sub color{
	my $class = shift;
	my $res = shift;

	if (ref($res->[0]) eq "ARRAY"){
		foreach (@{$res}){
			$_->[1] = '<span style="background-color: rgb(255, 255, 0);">'.$_->[1].'</span>' if ($_->[0]);
		}
	}
	return $res;
}

sub print {
	my $class = shift;
	my $res = shift;
	
	if (ref($res->[0]) eq "ARRAY"){
		my $tmp = "";
		for my $i (0 .. scalar(@{$res})){
			$tmp .= defined($res->[$i]->[1]) ? $res->[$i]->[1] : "";
			$tmp .= "<BR>";
		}
		return "��־�ж�����Ϊ$CrmZBPlan::attr->[$CrmZBPlan::pos]->{ATTR}->[0]\n".
		$tmp;	
	}else{
		my $tmp = "";
		for my $i (0 .. scalar(@{$res})){
			$tmp .= pop @{$res} || "";
			$tmp .= "<BR>";
		}
		return "��־�ж�����Ϊ$CrmZBPlan::attr->[$CrmZBPlan::pos]->{ATTR}->[0]\n".
		$tmp;	
	}
}

package CrmState::LogInfo::WebLogic;
our @ISA = qw(Exporter CrmState);
sub process{
	my $class = shift;
	my ($st, $res, $func) = @_;

	no strict "refs";
	$res = $class->$func($res);
	
	return ($st, $res);
}

package CrmState::DBInfo;
our @ISA = qw(Exporter CrmState);
sub process{
	my $class = shift;
	my ($st, $res, $func) = @_;
	
	no strict "refs";
	$res = $class->$func($res);
	
	return ($st, $res);
}

package CrmState::DiskInfoCheck;
our @ISA = qw(Exporter CrmState);
sub process{
	my $class = shift;
	my ($st, $res, $func) = @_;

	if ($func eq "print"){
		my $find = 0;

		if (ref($res->[0]) eq "ARRAY"){
			foreach (@{$res}){
				$find |= $_->[0];
			}
		}
		$st = 1;
		$st = -1 if ($find);
		print "Get Last Status $st\n";
	}
	print "Now Last Status $st\n";
		
	no strict "refs";
	$res = $class->$func($res);

	return ($st, $res);
}

sub color{
	my $class = shift;
	my $res = shift;

	for my $i (0 .. scalar(@{$res})){
		#print $res->[$i][0]."\n";
		$res->[$i][1] = '<span style="background-color: rgb(255, 255, 0);">'.
			$res->[$i][1].'</span>' if ($res->[$i][0]);
		#print "...".$res->[$i][1]."\n" if ($res->[$i][0]);
	}
	
	return $res;
}
	
sub print {
	my $class = shift;
	my $res = shift;

	for my $i (0 .. scalar(@{$res})){
		$res->[$i] = join " ", $res->[$i][1] || "";
	}
	#shift @{$res};
	return "���̼���ж�����Ϊ�ٷֱ�(PERCENT) > $CrmZBPlan::attr->[$CrmZBPlan::pos]->{PERCENT}% Ϊ��<BR>".
		join "<BR>", @{$res};
}

package CrmState::FileStatus;
our @ISA = qw(Exporter CrmState);
sub process{
	my $class = shift;
	my ($st, $res, $func) = @_;

	$res = "�ļ�$CrmZBPlan::attr->[$CrmZBPlan::pos]->{FILENAME}����," if ($st eq 2);
	$res = "�ļ�$CrmZBPlan::attr->[$CrmZBPlan::pos]->{FILENAME}������," if ($st eq -2);

	if ($CrmZBPlan::attr->[$CrmZBPlan::pos]->{EXPSTATUS} && $st eq 2){
		$st = 1;
	}

	if (!($CrmZBPlan::attr->[$CrmZBPlan::pos]->{EXPSTATUS}) && $st eq -2){
		$st = 1;
	}
	if ($st eq 1){
		$res .= "��Ԥ�����";
	}else{
		$st = -1;
		$res .= "��Ԥ�ڲ����";
	}

=pod
	if ($st eq 2){
		$res = "�ļ�����";
		return ($st, $res);
	} 
	if ($st eq -2){
		$res = "�ļ�������";
		return ($st, $res);
	} 
=cut
	print "****Call CrmState ok\n" if ($CrmDef::debug);	
	no strict "refs";
	$res = $class->$func($res);

	return ($st, $res);
}
	
sub print {
	my $class = shift;
	my $res = shift;

	if (!defined(@{$res->[0]})){
		return "FileStatus���쳣";
	}
	for my $i (1 .. scalar(@{$res->[0]})){
		$res->[$i] = join " ", @{$res->[$i]};
	}
	shift @{$res};
	return join "<BR>", @{$res};
}

package CrmState::FileCount;
our @ISA = qw(Exporter CrmState);
sub process{
	my $class = shift;
	my ($st, $res, $func) = @_;

	if ($func eq "print"){
		$st = 1;
		$st = -1 if ($res->[0] > $CrmZBPlan::attr->[$CrmZBPlan::pos]->{THRESHOLD});
	}
	no strict "refs";
	$res = $class->$func($res);

	return ($st, $res);
}

sub print {
	my $class = shift;
	my $res = shift;

	return "�� $CrmZBPlan::attr->[$CrmZBPlan::pos]->{PATH} ��ƥ�� $CrmZBPlan::attr->[$CrmZBPlan::pos]->{REGEX} ���ļ��� ".$res->[0]." ��";
}

package CrmState::DBStatus;
our @ISA = qw(Exporter CrmState);
sub process{
	my $class = shift;
	my ($st, $res, $func) = @_;

	if ($func eq "print"){
		$st = -1;
		$st = 1 if ($res eq 1);
	}
#	print "St $st, Res $res\n";
	no strict "refs";
	$res = $class->$func($res);

	return ($st, $res);
}
	
sub print {
	my $class = shift;
	my $res = shift;
	
	if ($res eq 1) {
		return "$CrmZBPlan::attr->[$CrmZBPlan::pos]->{DBNAME}���ݿ���������";
	}else{
		return "$CrmZBPlan::attr->[$CrmZBPlan::pos]->{DBNAME}���ݿ��޷�����";
	}
}

package CrmState::DBSpaces;
use Data::Dumper;
our @ISA = qw(Exporter CrmState);
sub process{
	my $class = shift;
	my ($st, $res, $func) = @_;

	my $tres = 0;
	foreach (@{$res}){
		$tres |= $_->[0];
	}
	if ($func eq "print"){
		$st = 1;
		$st = -1 if ($tres eq 1);
	}
#	print "St $st, Res $res\n";
	no strict "refs";
	$res = $class->$func($res);

	return ($st, $res);
}
	
sub print {
	my $class = shift;
	my $res = shift;

	my $real_res;
	for my $i (0 .. scalar(@{$res})-1){
		my $cccc = join " ", @{$res->[$i][1]};
		if ($res->[$i][0]){
			$real_res .= '<span style="background-color: rgb(255, 255, 0);">'.
				$cccc.'</span>\n';
		}else{
			$real_res .= $cccc."\n";
		}
		#print "...".$res->[$i][1]."\n" if ($res->[$i][0]);
	}
	print $real_res;
}

package CrmState::UpdateLogFile;
our @ISA = qw(Exporter CrmState);
sub process{
	my $class = shift;
	my ($st, $res, $func) = @_;

	if ($func eq "print"){
		$st = -1;
		$st = 1 if ($res->[0] eq 1);
	}
	no strict "refs";
	$res = $class->$func($res);

	return ($st, $res);
}
	
sub print {
	my $class = shift;
	my $res = shift;
	
	if ($res->[0] eq 1) {
		return "$CrmZBPlan::attr->[$CrmZBPlan::pos]->{FILENAME}��־�ļ���������<BR>$res->[1]";
	}else{
		return "$CrmZBPlan::attr->[$CrmZBPlan::pos]->{FILENAME}��־�ļ������쳣<BR>$res->[1]";
	}
}

package CrmState::processDBLocks;
our @ISA = qw(Exporter CrmState);
sub process{
	my $class = shift;
	my ($st, $res, $func) = @_;

	print "$st\n";
	no strict "refs";
	$res = $class->$func($res);

	return ($st, $res);
}
	
sub print {
	my $class = shift;
	my $res1 = shift;

	my ($res);
	my ($wait, $dead, $killsql) = @{$res1};
	my ($waitsql, $deadsql) = @{$killsql} if (defined ($killsql) && scalar(@{$killsql}) > 0);
	
	my $l1 = scalar(@{$wait});
	my $l2 = scalar(@{$dead});
	my $l3 = scalar(@{$killsql}) if (defined ($killsql) && scalar(@{$killsql}) > 0);
	
	my $tmp = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{AMOUNT_LOCK};
	my ($m_w, $m_k) = split(/,/, $tmp);
	
	if (defined($l3) && $l3 >= $m_k){
		$res = "���ݿ������� $l3 ���� $m_k<BR>";
	}else{
		$res = "���ݿ������� Wait: $l1, Lock : $l2<BR>";
		$res .= "�ȴ���(����, KILL) Param : ($CrmZBPlan::attr->[$CrmZBPlan::pos]->{WAIT_LOCK})<BR>";
		$res .= "����  (����, KILL) Param : ($CrmZBPlan::attr->[$CrmZBPlan::pos]->{DEAD_LOCK})<BR>";
	}
	if ($l1 <= 0 && $l2 <= 0){
		$res .= "���������<BR>";
		return $res;
	} 
	
	foreach my $i (0 .. scalar(@{$wait})-1){
		my ($k, $w, $v) = @{$wait->[$i]};
		my ($status, $username, $machine, $sid, $serial, $seconds, $id1, $sql, $program) = @{$v};
		
		my $m = int($seconds / 60);
		my $s = $seconds % 60;
		$sql = substr($sql, 0, length($sql)-1);
		$machine = substr($machine, 0, length($machine)-1);
		$res .= '<span style="background-color: rgb(255, 255, 0);">' if ($w);
		$res .= "״̬: $status, ����: $machine, �û�: $username, ʱ��: $m �� $s ��, ����: $program, SQL���: $sql";
		$res .= ',<font color=\"#ff0000\">��ɱ����</font>' if ($k);
		$res .= '</span>' if ($w);
		$res .= '<BR>'; 
	}

	foreach my $i (0 .. scalar(@{$dead})-1){
		my ($k, $w, $v) = @{$dead->[$i]};
		my ($status, $username, $machine, $sid, $serial, $seconds, $id1, $sql, $program) = @{$v};
		my $m = int($seconds / 60);
		my $s = $seconds % 60;
		$sql = substr($sql, 0, length($sql)-1);
		$machine = substr($machine, 0, length($machine)-1);
		$res .= '<span style="background-color: rgb(255, 255, 0);">' if ($w);
		$res .= "״̬: $status, ����: $machine, �û�: $username, ʱ��: $m �� $s ��, ����: $program, SQL���: $sql";
		$res .= ',<font color=\"#ff0000\">��ɱ����</font>' if ($k);
		$res .= '</span>' if ($w);
		$res .= '<BR>'; 
	}
	return $res;
}

sub warn{
	my $class = shift;
	my $res = shift;

	return $res;
}

sub kill {
	my $class = shift;
	my $res = shift;

	my (@waitkills, @deadkills);
	for my $i (0 .. scalar(@{$res})-1){
		foreach (@{$res->[$i]}){
			my ($k, undef, $v) = @{$_};
			my ($status, $username, $machine, $sid, $serial, $seconds, $id1, $sql, $program) = @{$v};
			if ($k){
				push @waitkills, "alter system kill session '".$sid.",".$serial."'" if ($status eq "Wait"); 
				push @deadkills, "alter system kill session '".$sid.",".$serial."'" if ($status eq "Lock"); 
			}
		}
	}
	# ɱ���̵����ݿ��� �� App/DBLock.pm �ж���  δ���� �̶�дΪdbasuper  ִ�����ݿ�Ϊ���
	foreach (@waitkills){
		if (defined($_)){
			print "do $_\n" if ($CrmDef::debug);
			#my ($state, $value) =  $CrmZBPlan::attr->[0]->_sql(name=>"dbasuper", sqlstring => $_);
			my ($state, $value) =  DBTable->send_sql_to_agent($_, 1);
		}
	}
	foreach (@deadkills){
		if (defined($_)){
			print "do $_\n" if ($CrmDef::debug);
			#my ($state, $value) =  $CrmZBPlan::attr->[0]->_sql(name=>"dbasuper", sqlstring => $_);
			my ($state, $value) =  DBTable->send_sql_to_agent($_, 1);
		}
	}

	push @{$res}, \@{[\@waitkills, \@deadkills]};
	
	return $res;
}

package CrmState::TestWeblogic;
our @ISA = qw(Exporter CrmState);
sub process{
	my $class = shift;
	my ($st, $res, $func) = @_;

	if ($func eq "print"){
		$st = $res->[0];
	}
	no strict "refs";
	$res = $class->$func($res);

	return ($st, $res);
}

sub color{
	my $class = shift;
	return shift;
}	

sub print {
	my $class = shift;
	my $res = shift;
	
	my $script = $CrmZBPlan::attr->[$CrmZBPlan::pos]->{SCRIPT};
	printf "..............%s\n", $res->[0];
	if ($res->[0] eq -1) {
		if ($CrmZBPlan::attr->[$CrmZBPlan::pos]->{RESTART}){
			system("sh $script");
		}
	}
	return "����ҳ��$CrmZBPlan::attr->[$CrmZBPlan::pos]->{TESTPAGE}��$CrmZBPlan::attr->[$CrmZBPlan::pos]->{FILE}�Ƚ�,".(($res->[0] eq 1) ? "����<BR>" : "�쳣<BR>").(($res->[0] eq -1) ? "ִ��" : "��ִ��").$script;
}

1;
