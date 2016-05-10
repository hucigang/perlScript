#!/usr/bin/perl -w
package App::STInfo;
use DBTable;
use Data::Dumper;
use Encode;
use vars qw($VERSION);

BEGIN {
    $App::STInfo::VERSION = "1.01";
}

sub process {
    my $class = shift;
    my $prop = shift;
    
    my @result;
    my $dbname = $prop->{DBNICK}->{NICK};
    my $cmd = $prop->{CMD};
    my $count = $prop->{RECORDNUMBER};
    
    my $cfg = new Config::IniFiles (-file => "$ENV{HOME}/etc/auto.cfg");
    
    my $procid = fork();
    if ($procid == 0) {
        exec($cmd);
        # this is the child process
        exit(0);
    } else {
        # this is the parent process
        waitpid ($procid, 0);
        
        my $sql = <<END
        SELECT SEQ, INFO, CREATE_DATE, RESULT_FLAG FROM AUTO_INSPECT_SILKTEST where rownum < $count ORDER BY SEQ DESC
END
;
        
        my $err = 0;
        #my ($state, $value) =  $CrmZBPlan::attr->[0]->_sql(name=>$dbname, sqlstring => $sql);
        my ($state, $value) =  DBTable->send_selectsql_to_agent($sql);
        
        if (ref($value) eq ""){
            print "dddd\n";
            $value = substr($value, 0, length($value)-1);
            my @aaa;
            push @aaa, $value;
            $value = \@aaa;
        }
        print "[".ref($value)."]";
        
        $count = scalar(@{$value}) if (scalar(@{$value}) < $count);
        my ($info, $flag) = ("", "");
        foreach my $cccc (@{$value}){
            next if (length($cccc) < 5);
            print "\nProcess: [".$cccc."]";
            last if ($count eq 0);
            #	(undef, $info, undef, $flag) = @{$cccc};
            
            if ($cccc =~ s/^[^\#]+\#(.*)\#[0-9\-\:\.\ ]{10,21}\#([a-zA-Z]+)$/$1$2/){
                $flag = $2;
            $info = $1;
            print "\nInfo: ".$info."\n";
            print "\nFlag: ".$flag."\n";
        
		      #(undef,$info1,$info, undef, $flag) = split(/\#/, $cccc);
        print "Get : Flag $flag\n";
        #$result[$count--] = $info1."\#".$info;
        $result[$count--] = $info;
        
        
        $err |= 1 if (defined($flag) && ($flag eq "N" || $flag eq "n"));
    		}
    }
    $result[0] = "Y";
    $result[0] = "N" if ($err);
}

return (ST_FINISH_STATE, \@result);	
}

1;
