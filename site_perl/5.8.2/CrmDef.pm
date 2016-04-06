#!/usr/bin/perl -w
package CrmDef;
use vars qw($VERSION);

BEGIN {
	$CrmDef::VERSION = "1.01";
}

use constant START_POS => 1;

use constant START_STATE => 1000;

use constant PARAM_DATA_NOT_FOUND => -400;
use constant PARAM_DATA_NOT_NAMES => -401;
use constant PARAM_DATA_NOTEQ_NAMES => -402;
use constant FILE_NOT_FOUND => -450;
use constant FINISH_STATE => 0;
use constant LOGFILE_FINISH_STATE => 1;
use constant CHECK_FINISH_STATE => 1;
use constant CHECK_FILE_FOUND => 2;
use constant CHECK_DISK_FINISH_STATE => 3;
use constant CHECK_DB_FINISH_STATE => 4;
use constant CHECK_PATH_FINISH_STATE => 5;
use constant CHECK_FILE_NOT_FOUND => -2;
use constant FUNC_ERR_STATE => (-1000);

use constant CHECK_DBLOCK_FINISH_STATE => 200;
use constant CHECK_DBLOCK_WARNNING_STATE => -200;
use constant CHECK_DBLOCK_KILL_STATE => -201;
use constant ST_FINISH_STATE => 250;

# using in State
use constant STATE_NOT_RETURN => (-599);   # 状态未返回或返回值与要求值数量不匹配
use constant PARAM_SUB_ERROR_UNKOWN => (-900); # 子参数异常.


$CrmDef::DefaultattrName = ["FUNCSTATE", "FUNCINFO"];

# FileLogInfo 相关参数
$CrmDef::FLIAttrName  = ["TIMEOUT", "FILENAME", "LINES", "DISPLAY", "EXPSTATUS", "ATTR", "TASKINFO"];

# 5|1 5 表示 $CrmDef::FLIAttrName 中第5个元素 1 表示参数的级别为2级,目前最高支持2级别 数组类型
# 6|0 6 表示 $CrmDef::FLIAttrName 中第6个元素 0 表示参数的级别为1级, 与FLIAttrName中元素同级 Hash类型
$CrmDef::FLIAttrName::Type = 2;
$CrmDef::FLIAttrName::Component = ["5|1", "6|0"];

$CrmDef::FLIAttrName::ComponentName5 = ["KEY", "UP", "DOWN"];
$CrmDef::FLIAttrName::ComponentName6 = ["TASK_ID", "PLAN_ID", "TEST_NO", "SEQ_ID", "STEP_NAME"];

# FileLogInfo 相关参数
$CrmDef::UnAttrName = ["string", "value"];

$CrmDef::STAttrName::Type = 1;
$CrmDef::STAttrName = ["TIMEOUT", "CMD", "RECORDNUMBER", "DBNICK", "TASKINFO"];
$CrmDef::STAttrName::Component = ["3|0", "4|0"];
$CrmDef::STAttrName::ComponentName3 = ["NICK", "DBNAME", "USER", "PASSWD"];
$CrmDef::STAttrName::ComponentName4 = ["TASK_ID", "PLAN_ID", "TEST_NO", "SEQ_ID", "STEP_NAME"];

$CrmDef::SelinumAttrName::Type = 1;
$CrmDef::SelinumAttrName = ["TIMEOUT", "CMD", "RECORDNUMBER", "PLANBLATCHID", "MACHINEID", "TASKINFO"];
$CrmDef::SelinumAttrName::Component = ["5|0"];
$CrmDef::SelinumAttrName::ComponentName5 = ["TASK_ID", "PLAN_ID", "TEST_NO", "SEQ_ID", "STEP_NAME"];

# 定义字段  辅助DiskInfoCheck 与下列属性无直接联系
$CrmDef::DiskInfo = ["LVS", "UNIT", "FREE", "USED", "IUSED", "PERCENT", "PATH"];
$CrmDef::DiskInfoType = 1;

# 主字段
$CrmDef::DiskInfoCheck = ["TIMEOUT", "PERCENT", "TASKINFO"];
$CrmDef::DiskInfoCheck::Component = ["2|0"];
$CrmDef::DiskInfoCheck::ComponentName2 = ["TASK_ID", "PLAN_ID", "TEST_NO", "SEQ_ID", "STEP_NAME"];
$CrmDef::DiskInfoCheck::Type = 5;

$CrmDef::FileStatus::Type = 5;
$CrmDef::FileStatus = ["TIMEOUT", "FILENAME", "EXPSTATUS", "TASKINFO"];
$CrmDef::FileStatus::Component = ["3|0"];
$CrmDef::FileStatus::ComponentName3 = ["TASK_ID", "PLAN_ID", "TEST_NO", "SEQ_ID", "STEP_NAME"];

$CrmDef::FileCount::Type = 5;
#$CrmDef::FileCount = ["TIMEOUT", "PATH", "DEPTH", "REGEX", "THRESHOLD", "TASKINFO"];
$CrmDef::FileCount = ["TIMEOUT", "PATH", "REGEX", "THRESHOLD", "TASKINFO"];
$CrmDef::FileCount::Component = ["4|0"];
$CrmDef::FileCount::ComponentName4 = ["TASK_ID", "PLAN_ID", "TEST_NO", "SEQ_ID", "STEP_NAME"];

$CrmDef::DBStatus::Type = 3;
$CrmDef::DBStatus = ["TIMEOUT", "DBNAME", "USER", "PASSWD", "TASKINFO"];
$CrmDef::DBStatus::Component = ["4|0"];
$CrmDef::DBStatus::ComponentName4 = ["TASK_ID", "PLAN_ID", "TEST_NO", "SEQ_ID", "STEP_NAME"];

$CrmDef::UpdateLogFile::Type = 2;
$CrmDef::UpdateLogFile = ["TIMEOUT", "FILENAME", "START", "END", "FMT", "SECOND", "TASKINFO"];
$CrmDef::UpdateLogFile::Component = ["6|0"];
$CrmDef::UpdateLogFile::ComponentName6 = ["TASK_ID", "PLAN_ID", "TEST_NO", "SEQ_ID", "STEP_NAME"];

$CrmDef::processDBLocks::Type = 3;
$CrmDef::processDBLocks = ["TIMEOUT", "WAIT_LOCK", "DEAD_LOCK", "AMOUNT_LOCK", "DBNICK", "EXCEPTION", "TASKINFO"];
$CrmDef::processDBLocks::Component = ["4|0", "6|0"];
$CrmDef::processDBLocks::ComponentName4 = ["DBNAME", "USER", "PASSWD"];
$CrmDef::processDBLocks::ComponentName6 = ["TASK_ID", "PLAN_ID", "TEST_NO", "SEQ_ID", "STEP_NAME"];

$CrmDef::TestWeblogic::Type = 4;
$CrmDef::TestWeblogic = ["TIMEOUT", "TESTPAGE", "FILE", "RESTART", "SCRIPT", "TASKINFO"];
$CrmDef::TestWeblogic::Component = ["5|0"];
$CrmDef::TestWeblogic::ComponentName5 = ["TASK_ID", "PLAN_ID", "TEST_NO", "SEQ_ID", "STEP_NAME"];

$CrmDef::DBSpaces::Type = 3;
$CrmDef::DBSpaces = ["TIMEOUT", "DBNAME", "USER", "PASSWD", "PRE", "TASKINFO"];
$CrmDef::DBSpaces::Component = ["5|0"];
$CrmDef::DBSpaces::ComponentName5 = ["TASK_ID", "PLAN_ID", "TEST_NO", "SEQ_ID", "STEP_NAME"];

%CrmDef::name2Func = (
    "look_STInfo" => "App::STInfo",
    "look_Selinum" => "App::Selinum",
    "look_UnInfo" => "App::UnInfo",
    "look_DBInfo" => "App::DBInfo",
    "look_FileLogInfo" => "App::LogInfo::File",
    "look_WebLogInfo" => "App::LogInfo::WebLogic",
    "look_DiskInfo" => "App::DiskInfoCheck",
	"look_FileStatus" => "App::FileStatus",
	"look_FileCount" => "App::FileCount",
	"look_DBStatus" => "App::DBStatus",
	"look_UpdateLogFile" => "App::UpdateLogFile",
	"look_TestWeblogic" => "App::TestWeblogic",
	"processDBLocks" => "App::processDBLocks",
	"look_DBSpaces" => "App::DBSpaces",
);

%CrmDef::name2State = (
    "look_STInfo" => "CrmState::STInfo",
    "look_Selinum" => "CrmState::STInfo",
    "look_UnInfo" => "CrmState::UnInfo",
    "look_DBInfo" => "CrmState::DBInfo",
    "look_FileLogInfo" => "CrmState::LogInfo::File",
    "look_WebLogInfo" => "CrmState::LogInfo::WebLogic",
    "look_DiskInfo" => "CrmState::DiskInfoCheck",
	"look_FileStatus" => "CrmState::FileStatus",
	"look_FileCount" => "CrmState::FileCount",
	"look_UpdateLogFile" => "CrmState::UpdateLogFile",
	"look_DBStatus" => "CrmState::DBStatus",
	"look_TestWeblogic" => "CrmState::TestWeblogic",
	"processDBLocks" => "CrmState::processDBLocks",
	"look_DBSpaces" => "CrmState::DBSpaces",
);

$CrmDef::debug = 1;
1;

__DATA__
# 未使用
sub getArray{
	my $class = shift;
	my @array = [1, 2];
	
	return \@array;
}

sub create_mask	{
	my $class = shift;
	my $string = shift;
	
	my %hash = ();
	print $class->getArray($string);	

	foreach ($class->getArray($string)) {
		print "$_\n";
		my ($key, $up, $down) = split(/,/, $_);
		$hash{$key}{up} = $up;
		$hash{$key}{down} = $down;
	}

	return \%hash;
}
