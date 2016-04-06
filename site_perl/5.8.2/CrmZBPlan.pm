#!/usr/bin/perl -w
package CrmZBPlan;
use vars qw($VERSION);

use App;
use CrmState;
use Utils::String;
use CrmDef;

BEGIN {
	$CrmZBPlan::VERSION = "1.01";
}

$CrmZBPlan::pos = CrmDef::START_POS();  # 计划当前位置  每个步骤都需要递加
$CrmZBPlan::state = START_STATE; # 计划当前位置的状态, 初始值为1000 正值为成功处理, 负值为失败处理. 
$CrmZBPlan::isload = 0;

$CrmZBPlan::attr = [];
# 此数据按数组进行对应 $CrmZBPlan::pos 写入数组放置到%CrmZBPlan::attr中
#	funcName => [],     # 功能标识  get
#	funcState => [],    # 记录此功能的状态  set
#	funcprop => '$',      # 功能输入的参数为hash引用  get 
#	funcinfo => [],     # 相应的输出信息   set
#	funccaseinfo => [],     # Case 相关信息  get
#	functimeout => [],     # Case 相关信息  get
#   此部分实现分别在getProperties, setProperties中
#   其中参数含2级参数的部分在get2Properties0, get2Properties1中
#     get2Properties1表示处于2级子参数
#     get2Properties0表示处于1级子参数 与funcName同级

sub getProperties{ 
	my $class = shift; 
	my ($props, $names) = @_;

	for my $i (0 .. $#{$names}){
		$CrmZBPlan::attr->[$CrmZBPlan::pos]{$names->[$i]} = $props->[$i];
	}
=pod	
	print "Get Prop: ".$CrmZBPlan::attr->[$CrmZBPlan::pos]."\n";
	print join " ", keys %{$CrmZBPlan::attr->[$CrmZBPlan::pos]};
	print "\n";
	print join " ", values %{$CrmZBPlan::attr->[$CrmZBPlan::pos]};
	print "\n==================\n";
=cut
}

sub get2Properties0{
	my $class = shift; 
	my ($pp, $props, $names) = @_;

	
	$CrmZBPlan::attr->[$CrmZBPlan::pos]{$pp} = ();
	
	for my $i (0 .. $#{$names}){
		$CrmZBPlan::attr->[$CrmZBPlan::pos]{$pp}{$names->[$i]} = $props->[$i];
	}

	if ($CrmDef::debug){
		print "Get 2 Prop: ".$CrmZBPlan::attr->[$CrmZBPlan::pos]{$pp}."\n";
		print join " ", keys %{$CrmZBPlan::attr->[$CrmZBPlan::pos]{$pp}};
		print "\n";
		print join " ", values %{$CrmZBPlan::attr->[$CrmZBPlan::pos]{$pp}};
		print "\n==================\n";
	}
}

sub get2Properties1{
	my $class = shift; 
	my ($pp, $props, $names) = @_;

	$CrmZBPlan::attr->[$CrmZBPlan::pos]{$pp} = ();
	for my $j (0 .. scalar(@{$props})-1){
		my @prop = Utils::String->specStr($props->[$j], 1);
		for my $i (0 .. $#{$names}){
			printf "Pro1   %s\n", $names->[$i];
			$CrmZBPlan::attr->[$CrmZBPlan::pos]{$pp}[$j]{$names->[$i]} = $prop[$i];
		}
	}

=pod
	print "Get 2 Prop: ".$CrmZBPlan::attr->[$CrmZBPlan::pos]{$pp}."\n";
	print join " ", keys %{$CrmZBPlan::attr->[$CrmZBPlan::pos]{$pp}};
	print "\n";
	print join " ", values %{$CrmZBPlan::attr->[$CrmZBPlan::pos]{$pp}};
	print "\n==================\n";
=cut
}

sub setProperties{ 
	my $class = shift; 
	my ($st, $res, $names) = @_;
	
	$CrmZBPlan::attr->[$CrmZBPlan::pos]{$names->[0]} = $st;
	$CrmZBPlan::attr->[$CrmZBPlan::pos]{$names->[1]} = $res;
	
=pod
	print "Get Prop: ".$CrmZBPlan::attr->[$CrmZBPlan::pos]."\n";
	print join " ", keys %{$CrmZBPlan::attr->[$CrmZBPlan::pos]};
	print "\n";
	print join " ", values %{$CrmZBPlan::attr->[$CrmZBPlan::pos]};
	print "\n==================\n";
=cut
}
=pod
sub load{
	my $class = shift;
	
#	$CrmZBPlan::attr->[0] = Utils::OracleManage->new();
	$CrmZBPlan::attr->[0] = '';
	require Config::IniFiles;
	my $cfg;

if ( $^O =~ /MSWin32/ ) {
	$cfg = new Config::IniFiles (-file => "$ENV{USERPROFILE}\\etc\\auto.cfg");
}else{	
	$cfg = new Config::IniFiles (-file => "$ENV{HOME}/etc/auto.cfg");
}
    foreach my $vv ($cfg->Sections()){
		if ($cfg->val($vv, "type") =~ m/oracle/i){
			$CrmZBPlan::attr->[0]->register(
				name 	=> 	$vv,
				type	=>  $cfg->val($vv, "type"),
				dbname	=>	$cfg->val($vv, "dbname"),
				user	=>	$cfg->val($vv, "user"),
				passwd	=>	$cfg->val($vv, "passwd"),
			);
		}
		if ($cfg->val($vv, "type") =~ m/alti/i){
			$CrmZBPlan::attr->[0]->register(
				name 		=> 	$vv,
				type		=>  $cfg->val($vv, "type"),
				url 		=>	$cfg->val($vv, "url"),
				UserName	=>	$cfg->val($vv, "UserName"),
				Password	=>	$cfg->val($vv, "Password"),
				encoding	=>	$cfg->val($vv, "encoding"),
			);
		}
    }
if ( $^O =~ /MSWin32/ ) {
	$CrmZBPlan::attr->[0]->register(
				name 	=> 	$CrmZBPlan::attr->[$CrmZBPlan::pos]->{DBNICK}->{NICK},
				type	=>  "oracle",
				dbname	=>	$CrmZBPlan::attr->[$CrmZBPlan::pos]->{DBNICK}->{DBNAME},
				user	=>	$CrmZBPlan::attr->[$CrmZBPlan::pos]->{DBNICK}->{USER},
				passwd	=>	$CrmZBPlan::attr->[$CrmZBPlan::pos]->{DBNICK}->{PASSWD},
			);
} 
	$CrmZBPlan::isload = 1;
}
END{
	print "cALL eND\n";
	foreach (keys %{$CrmZBPlan::attr->[0]}){
		#Utils::OracleManage->cancel(name => "$_");
	}
	$CrmZBPlan::isload = 0;
}
=cut
sub look {
	my $class = shift;
	my ($isstep, $type, $arrdata, $propname, $sprule) = @_;

	my (@arr, @arrname);
	foreach (@{${"$propname"}}){ push @arrname, $_; }
	foreach (@{$arrdata}){ push @arr, $_; }

	if ($CrmDef::debug){
		print  "====PROPERTIES=============\n";
		print join " ", @arrname;
		print  "\n---------------------------\n";
		print join " ", @arr;
		print  "\n====PROPERTIES=============\n";
	}
	my $propnames = \@arrname;
	my $propdatas = \@arr;
	
	my $over = 0;
	my ($st, $res);
	if (scalar(@{$propdatas}) <= 0){
		($st, $res) = (PARAM_DATA_NOT_FOUND, ""); 
		$over = 1;
	}
	if ($over eq 0 && scalar(@{$propnames}) <= 0){
		($st, $res) = (PARAM_DATA_NOT_NAMES, "");
		$over = 1;
	}
	if ($over eq 0 && !(scalar(@{$propnames}) eq scalar(@{$propdatas}))){
		($st, $res) = (PARAM_DATA_NOTEQ_NAMES, scalar(@{$propnames})." != ".scalar(@{$propdatas}));
		$over = 1;
	}
	if (!$over){
=pod
		print "Names $#{$propnames}\n";
		print join " ", @{$propnames};
		print "\n";
		print "Data $#{$propdatas}\n";
		print join " ", @{$propdatas};
		print "\n";
=cut
		$class->getProperties($propdatas, $propnames);

		print "ComponentName $propname\n" if ($CrmDef::debug);
		if (my $componentarray = ${"$propname\::Component"}){
			foreach my $cposs (@{$componentarray}){
				my ($cpos, $level) = split(/\|/, $cposs);
				my $component_props = ${"$propname\::ComponentName$cpos"};
				printf "Check $cpos, $level, %s\n", $CrmZBPlan::attr->[$CrmZBPlan::pos]{$propnames->[$cpos]} if ($CrmDef::debug);
				my @arr1 = Utils::String->specStr($CrmZBPlan::attr->[$CrmZBPlan::pos]{$propnames->[$cpos]}, 1);
				$class->get2Properties1($propnames->[$cpos], \@arr1, $component_props) if ($level eq 1);
				$class->get2Properties0($propnames->[$cpos], \@arr1, $component_props) if ($level eq 0);
			}
		}
		# 补齐 TASKINFO  ->  STEP_TYPE
		$CrmZBPlan::attr->[$CrmZBPlan::pos]->{TASKINFO}->{STEP_TYPE} = ${"$propname\::Type"};
#		$class->load() if ($CrmZBPlan::isload eq 0);
		
		print "Get Properties Finish\n" if ($CrmDef::debug);

	# 基本信息获取成功
		#$CrmZBPlan::pos = CrmDef::START_POS();
		CrmState->start();	
	# 
		print "** Using Call:  $type   $sprule \n" if ($CrmDef::debug);
		($st, $res) = App->call($CrmDef::name2Func{$type}, $CrmZBPlan::attr->[$CrmZBPlan::pos], $sprule);
		print "********After Call:  $st \n" if ($CrmDef::debug);
	}
	($st, $res) = $class->state($type, $st, $res);
	print "******After State:  $st \n" if ($CrmDef::debug);
	
	$class->setProperties($st, $res, $CrmDef::DefaultattrName);

	CrmState->end();	

	return ($st, $res);
}

sub state {
	my $class = shift;
	my ($type, $st, $res) = @_;

	print "State $type:$CrmDef::name2State{$type}\n" if ($CrmDef::debug);
	my ($state, $resource) = CrmState->process($CrmDef::name2State{$type}, $st, $res);
	
	return ($state, $resource);
}

sub look_STInfo{
	my $class = shift;
	my $string = shift;   

	# 解析参数
	my @arr = Utils::String->specStr($string, 1);
	
	my ($st, $res) = $class->look(1, "look_STInfo", \@arr, "CrmDef::STAttrName", "process");

	$CrmZBPlan::pos++;

	return ($st, $res);
}

sub look_Selinum{
	my $class = shift;
	my $string = shift;   

	# 解析参数
	my @arr = Utils::String->specStr($string, 1);
	
	my ($st, $res) = $class->look(1, "look_Selinum", \@arr, "CrmDef::SelinumAttrName", "process");

	$CrmZBPlan::pos++;

	return ($st, $res);
}

sub look_UnInfo{
	my $class = shift;
	my $string = shift;   

	my @arr = Utils::String->specStr($string, 1);

	my ($st, $res) = $class->look(1, "look_UnInfo", \@arr, "CrmDef::UnAttrName", "");

	$CrmZBPlan::pos++;

	return ($st, $res);
}

sub look_FileLogInfo{
	my $class = shift;
	my $string = shift;   

	my @arr = Utils::String->specStr($string, 1);

	my ($st, $res) = $class->look(1, "look_FileLogInfo", \@arr, "CrmDef::FLIAttrName", "search");
	
	$CrmZBPlan::pos++;

	return ($st, $res);
}

sub look_DiskInfo{
	my $class = shift;
	my $string = shift;

	my @arr = Utils::String->specStr($string, 1);
	print "Enter look DiskInfo\n" if ($CrmDef::debug);
	
	my ($st, $res) = $class->look(1, "look_DiskInfo", \@arr, "CrmDef::DiskInfoCheck", "check");
	$CrmZBPlan::pos++;
	
	print "Levae look DiskInfo\n" if ($CrmDef::debug);

	return ($st, $res);
}

sub look_FileStatus{
	my $class = shift;
	my $string = shift;

	my @arr = Utils::String->specStr($string, 1);
	print "Enter look FileStatus\n" if ($CrmDef::debug);
	
	my ($st, $res) = $class->look(1, "look_FileStatus", \@arr, "CrmDef::FileStatus", "check");
	$CrmZBPlan::pos++;
	
	print "Levae look FileStauts\n" if ($CrmDef::debug);

	return ($st, $res);
}

sub look_FileCount{
	my $class = shift;
	my $string = shift;

	my @arr = Utils::String->specStr($string, 1);
	print "Enter look FileCount\n" if ($CrmDef::debug);
	
	my ($st, $res) = $class->look(1, "look_FileCount", \@arr, "CrmDef::FileCount", "count");
	$CrmZBPlan::pos++;
	
	print "Levae look FileCount\n" if ($CrmDef::debug);

	return ($st, $res);
}

sub look_DBStatus{
	my $class = shift;
	my $string = shift;

	my @arr = Utils::String->specStr($string, 1);
	print "Enter look DBStatus\n" if ($CrmDef::debug);
	
	my ($st, $res) = $class->look(1, "look_DBStatus", \@arr, "CrmDef::DBStatus", "check");
	$CrmZBPlan::pos++;
	
	print "Levae look DBStatus\n" if ($CrmDef::debug);
}

sub look_DBSpaces{
	my $class = shift;
	my $string = shift;

	my @arr = Utils::String->specStr($string, 1);
	print "Enter look DBSpaces\n" if ($CrmDef::debug);
	
	my ($st, $res) = $class->look(1, "look_DBSpaces", \@arr, "CrmDef::DBSpaces", "check");
	$CrmZBPlan::pos++;
	
	print "Levae look DBSpaces\n" if ($CrmDef::debug);
}

sub look_UpdateLogFile{
	my $class = shift;
	my $string = shift;

	my @arr = Utils::String->specStr($string, 1);
	print "Enter look UpdateLogFile\n" if ($CrmDef::debug);
	
	my ($st, $res) = $class->look(1, "look_UpdateLogFile", \@arr, "CrmDef::UpdateLogFile", "check");
	$CrmZBPlan::pos++;
	
	print "Levae look UpdateLogFile\n" if ($CrmDef::debug);
}

sub process_DBLocks{
	my $class = shift;
    my $string = shift;

    my @arr = Utils::String->specStr($string, 1);
    print "Enter process_DBLocks\n" if ($CrmDef::debug);

    my ($st, $res) = $class->look(1, "processDBLocks", \@arr, "CrmDef::processDBLocks", "check");
    $CrmZBPlan::pos++;

    print "Levae process_DBLocks\n" if ($CrmDef::debug);
}

sub look_TestWeblogic{
	my $class = shift;
    my $string = shift;

    my @arr = Utils::String->specStr($string, 1);
    print "Enter TestWeblogic\n" if ($CrmDef::debug);

    my ($st, $res) = $class->look(1, "look_TestWeblogic", \@arr, "CrmDef::TestWeblogic", "check");
    $CrmZBPlan::pos++;

    print "Levae TestWeblogic\n" if ($CrmDef::debug);
}


1;
