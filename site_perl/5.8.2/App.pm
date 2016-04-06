#!/usr/bin/perl -w
package App;
use vars qw($VERSION);

BEGIN {
	$App::VERSION = "1.01";
	%App::dics = (
		"App::STInfo" => 0,
		"App::Selinum" => 0,
		"App::LogInfo::File" => 0,
		"App::LogInfo::WebLogic" => 0,
		"App::DBInfo" => 0,
		"App::UnInfo" => 0,
		"App::DiskInfoCheck" => 0,
		"App::FileStatus" => 0,
		"App::FileCount" => 0,
		"App::DBStatus" => 0,
		"App::UpdateLogFile" => 0,
		"App::processDBLocks" => 0,
		"App::TestWeblogic" => 0,
		"App::DBSpaces" => 0,
	);

	if ( $^O =~ /MSWin32/ ) {
		$App::dics{App::STInfo} = 1;
		$App::dics{App::Selinum} = 1;
	}else{
		$App::dics{App::UnInfo} = 1;
		$App::dics{App::DBInfo} = 1;
		$App::dics{App::LogInfo::File} = 1;
		$App::dics{App::LogInfo::WebLogic} = 1;
		$App::dics{App::DiskInfoCheck} = 1;
		$App::dics{App::FileStatus} = 1;
		$App::dics{App::FileCount} = 1;
		$App::dics{App::DBStatus} = 1;
		$App::dics{App::UpdateLogFile} = 1;
		$App::dics{App::TestWeblogic} = 1;
		$App::dics{App::processDBLocks} = 1;
		$App::dics{App::DBSpaces} = 1;
	}
}

require App::STInfo;
require App::Selinum;
require App::LogInfo::File;
require App::LogInfo::WebLogic;
require App::DBInfo;
require App::UnInfo;
require App::DiskInfoCheck;
require App::FileStatus;
require App::FileCount;
require App::DBStatus;
require App::UpdateLogFile;
require App::processDBLocks;
require App::TestWeblogic;
require App::DBSpaces;

sub call{
	my $class = shift;
	my ($rebless_class, $prop, $sprule) = @_;
	
	print "**Call : $rebless_class $sprule \n" if ($CrmDef::debug);	
	return FUNC_ERR_STATE unless defined($prop) || defined($sprule);
	
	print "***Call : $rebless_class $sprule \n" if ($CrmDef::debug);	
	return FUNC_ERR_STATE unless ($rebless_class);

	print "****Call : $rebless_class $sprule \n" if ($CrmDef::debug);	
	return FUNC_ERR_STATE if (not exists $App::dics{$rebless_class} || $App::dics{$rebless_class});

	print "**Call OK\n" if ($CrmDef::debug);	
	no strict 'refs';	
	return $rebless_class->$sprule($prop);
}

1;
