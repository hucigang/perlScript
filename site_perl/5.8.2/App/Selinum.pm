#!/usr/bin/perl -w
package App::Selinum;
use DBTable;
use Data::Dumper;
use Encode;
use vars qw($VERSION);

BEGIN {
    $App::Selinum::VERSION = "1.01";
}

sub process {
    my $class = shift;
    my $prop = shift;
    
    my @result;
    #my $dbname = $prop->{DBNICK}->{NICK};
    my $cmd = $prop->{CMD};
    my $count = $prop->{RECORDNUMBER}; # not vailed
  	my $planBatchId = $prop->{PLANBLATCHID};
  	my $execId = $prop->{MACHINEID};
    #my $cfg = new Config::IniFiles (-file => "$ENV{HOME}/etc/auto.cfg");
    #my $planBatchId = $cfg->val("crmdata", "planBatchId");
    #$cmd = $cfg->val("crmdata", "cmd");
    #my $execId = $cfg->val("crmdata", "execMachineId");
    
    #$cmd="dir";
    my $procid = fork();
    if ($procid == 0) {
        exec($cmd);
        # this is the child process
        exit(0);
    } else {
        # this is the parent process
        waitpid ($procid, 0);
        
        my $sql = <<END
SELECT
  step_index AS seq,
  case when (LOCATE("【 ", step_desc) > 0) then SUBSTRING(step_desc, LOCATE("【 ", step_desc)+1, LOCATE("】", step_desc)-LOCATE("【 ", step_desc)-1) 
  else step_desc end AS info,
  DATE_FORMAT(begin_time, '%Y-%m-%d %H:%i:%s') AS CREATE_DATE,
  CASE
      WHEN input_desc LIKE '%失败%' THEN 'N' ELSE 'Y'
    END AS result_flag
FROM tbl_fk_weblogs
WHERE batch_id IN (select batch_id from tbl_auto_dataresult where plan_batch_id = '$planBatchId' AND exec_machine='$execId') AND step_desc LIKE '点击%' 
  AND step_desc not LIKE '%点击隐藏菜单%';
END
;
        $sql= encode("gbk", decode("utf8", $sql));
        my $err = 0;
        #my ($state, $value) =  $CrmZBPlan::attr->[0]->_sql(name=>$dbname, sqlstring => $sql);
        my ($state, $value) =  DBTable->send_selectsql_to_agent($sql, "1");
        #print "111 \n";
        if (ref($value) eq ""){
            #print "dddd\n";
            $value = substr($value, 0, length($value)-1);
            my @aaa;
            push @aaa, $value;
            $value = \@aaa;
        }
        #print "[".ref($value)."]";
        $sql = <<END
        update tbl_plan_exec set status = 1 where plan_batch_id = '$planBatchId'
END
;
        DBTable->send_sql_to_agent($sql, "1");
        
        #处理菜单级别
        
        
        #$count = scalar(@{$value}); #if (scalar(@{$value}) < $count);
        my ($info, $flag) = ("", "");
        my ($menuLevel1, $menuLevel2, $numLevel1, $numLevel2) = (undef, undef, 0, 0);
        my $menuMark1 = "一级菜单";
        my $menuMark2 = "二级菜单";
        my $spliMenu = "：";
				$menuMark1= encode("gbk", decode("utf8", $menuMark1));
				$menuMark2= encode("gbk", decode("utf8", $menuMark2));
				$spliMenu= encode("gbk", decode("utf8", $spliMenu));
				my $minErr = 1;
				my $waitCount = undef;
				my $succes = encode("gbk", decode("utf8", "成功"));
				my $faile = encode("gbk", decode("utf8", "错误"));
				my $subMenuMark = encode("gbk", decode("utf8", "【巡检菜单】："));
				$count = 1;
				my $subRCount = 0;
				my $subECount = 0;
				#print "Start Count $count\n";
        foreach my $cccc (@{$value}){
        	
					my $hasErr = 0;
          #next if (length($cccc) < 5);
          #print "\nProcess: [".$cccc."]\n";
          #last if ($count eq );
          #	(undef, $info, undef, $flag) = @{$cccc};
            
          if ($cccc =~ s/^[^\#]+\#(.*)\#[0-9\-\:\.\ ]{10,21}\#([a-zA-Z]+)$/$1$2/){
                $flag = $2;
            		$info = $1;
            		if ($info =~ m/$menuMark1/){
            			
            			# 判断一级菜单时， 如果发现waitCount有值 表示 当前大类 没有最终结果
            			# 切换大类时为上一个大类写最终结果
            			# 循环结束也需要写一次 如果最后为二级菜单 可能导致重复填写一次最后一个二级菜单
            			
            			if (defined($waitCount)){
            				#print "warte menu1 [$waitCount] $menuLevel1\n";
            				my $minErrInfo = "";
            				#minErr 1为成功  
            				if ($minErr){
            					$minErrInfo = "<font color=\"#0000ff\">".$succes.": ".$subRCount."</font>";
            				}else{
            					$minErrInfo = "<font color=\"#0000ff\">".$succes.": ".$subRCount."; </font>" if ($subRCount > 0);
            					$minErrInfo .= "<font color=\"#ff0000\">".$faile.": ".$subECount."</font>";
            				}
            				
            				$result[$waitCount] = "<font size=\"3\"><strong>$numLevel1".encode("gbk", decode("utf8", "、")).$menuLevel1." (".$minErrInfo.")</strong></font>" if (defined($menuLevel1));
            				$subRCount = 0;
            				$subECount = 0;
            			}
            			$menuLevel1 = substr($info, index($info, $spliMenu)+length(encode("gbk", decode("utf8", $spliMenu))));
            			
            			$numLevel1++;
            			$info = "<BR>";
            			
            			$minErr = 1;
            			$waitCount = $count;
            			$count++;
            			next;
            		} elsif ($info =~ m/$menuMark2/){
            			$menuLevel2 = substr($info, index($info, $spliMenu));
            			$numLevel2++;
            			$menuLevel2 = $menuLevel1.$menuLevel2;
            			next;
            		}else{
            			#print "Enter Sub 3 Menu\n";
            			if (defined($flag) && ($flag eq "N" || $flag eq "n")){
            				$minErr &= 0;
            				$hasErr = 1;
            				$subECount++;
            				$info = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;".$subMenuMark.$info."  <font color=\"#ff0000\">".$faile."</font><BR></BR>";
            			}else{
            				$subRCount++;
            				
        						$info = "";
            				#$info = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;".$subMenuMark.$info."  <font color=\"#0000ff\">".$succes."</font><BR></BR>";
            			}
            		}
            		
            		
            		#print "Flag: $flag ,Info: ".$info."\n";
            		#print "\nFlag: ".$flag."\n";
            		 #(undef,$info1,$info, undef, $flag) = split(/\#/, $cccc);
        	#print "Get : Flag $flag count $count waitErr $waitErr\n";
        	#$result[$count--] = $info1."\#".$info;
        	#print "Write waitErr $waitErr Info: $info\n";
        		if ($hasErr){
        			#print "[$count] $count";
        			$result[$count++] = $info;
        		}else{
        			$waitCount = $count;
        		}
        
        		$err |= 1 if (defined($flag) && ($flag eq "N" || $flag eq "n"));
    		
        	}
		     }
		     if (defined($waitCount)){
            				print "warte menu1 $menuLevel1\n";
            				my $minErrInfo = "";
            				#minErr 1为成功  
            				if ($minErr){
            					$minErrInfo = "<font color=\"#0000ff\">".$succes.": ".$subRCount."</font>";
            				}else{
            					$minErrInfo = "<font color=\"#0000ff\">".$succes.": ".$subRCount."; </font>" if ($subRCount > 0);
            					$minErrInfo .= "<font color=\"#ff0000\">".$faile.": ".$subECount."</font>";
            				}
            				$result[$waitCount] = "<font size=\"3\"><strong>".$numLevel1.encode("gbk", decode("utf8", "、")).$menuLevel1." (".$minErrInfo.")</strong></font><BR></BR>";
            				#$result[$waitCount] = $menuLevel1." (".$minErrInfo.")<BR></BR>";
            				$subRCount = 0;
            				$subECount = 0;
          }
    $result[0] = "Y";
    $result[0] = "N" if ($err);
}

return (ST_FINISH_STATE, \@result);	
}

1;
