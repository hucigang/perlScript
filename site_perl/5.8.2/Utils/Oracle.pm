#!/usr/bin/perl -w
package Utils::Oracle;
use vars qw($VERSION);

BEGIN {
$Utils::Oracle::VERSION = "1.01";
}

use strict;
use DBI;

=head1 NAME

	Oracle基本功能

=head1 SYNOPSIS

	Oracle基本功能

=head1 DESCRIPTION

	Oracle的连接(connect), 断开(disconnect), 执行SQL(sql), 执行存储过程(produce)

=head1 USAGE

my $db = Util::Oracle->connect(dbname=>"dbi:Oracle:example", user=>"user", passwd=>"pass");

my ($state, $value) = $db->sql(sql => 'select * from table where rownum = 1');

$db->disconnect();

=head1 METHODS

=head2 connect( [-option=>value ...] )

connect连接, 参数如下:

=over 10 

=item I<dbname> 数据库名

数据库名如: "dbi:Oracle:example"

=item I<user> 用户名 

用户名

=item I<passwd> 用户名相应的口令

用户名口令

=item I<-options>  对应DBI::Oracle中的相关设置

对应DBI::Oracle中的相关设置

=item I<return> 返回值

数据库操作符

=back

=cut

sub connect{
	my $class = shift;
	my %params = @_;
	
	my $self = bless {
    	default => $params{dbname},
    	alive => 1,
		dbhandle => '',
  	}, $class;
	#if ($params{dbname}) 
	my $dsn;
if ( $^O =~ /MSWin32/ ){
	$dsn = $params{dbname};
}else{
	$dsn = "dbi:Oracle:".$params{dbname};
}
	$self->{dbhandle} = DBI->connect( 
		"dbi:Oracle:".$params{dbname},
		$params{user},
		$params{passwd},
        {
            RaiseError => 1,
            AutoCommit => 0
        }
    ) || die "Database connection not made: $DBI::errstr";

	return $self;
}

=head2 disconnect( [-option=>value ...] )

断开连接

=cut

sub disconnect{
	my $class = shift;
	
	$class->{dbhandle}->rollback();
	$class->{dbhandle}->disconnect();

	$class->{alive} = 0;	
}

=head2 sql( [-option=>value ...] )

=item I<sql> 执行的语句 

实际执行的SQL语句, 执行的语句的返回记录只有一条

=item I<return> 返回值 0 | 1 | -1 | -2

0 执行成功 非SELECT语句 

1 执行成功 SELECT语句 有返回值

-1 连接丢失

-2 执行语句失败

=cut

sub sql{
	my $class = shift;

	my %params = @_;

	my $err = 0;
	return ($err-1, "connect lost") if (!$class->{alive});
	my ($sth, $rv);
	eval{
        $sth = $class->{dbhandle}->prepare($params{sqlstring});
        $rv = $sth->execute();
    };
    if ($@){
        $class->{dbhandle}->rollback();
		eval { $sth->finish();};
		return ($err-2, $@); 
    }else{
		#sleep(100);
        $class->{dbhandle}->commit();
        if ($params{sqlstring} =~ m/^SELECT/i) {
			my @temp;
			while (my @cc = $sth->fetchrow_array) {
				push @temp, \@cc;
			}
			return ($err+1, \@temp);
#            return ($err+1, join "#", $sth->fetchrow_array);
        }
    }
	eval{
    	$sth->finish();
	};
		
	return ($err, "finished");
}

=head2 produce( [-option=>value ...] )

=cut

=item I<prodstring> 执行的存储过程调用语句

存储过程调用方式 如: 

	begin

  	-- Call the procedure

  	test_procedure(in_param => :in_param,

                 out_param => :out_param);
	
	end;

使用时 按如下方式写入

example:
	
	my $db = Util::Oracle->connect(dbname=>"dbi:Oracle:cuqcs", user=>"autotest", passwd=>"autotest");

	# aaa的值为134  ccc, ddd为返回值, 存放在@array中, 顺序为ddd, ccc 
	
	my ($state, @array) = $db->produce(prodname=> "ex_procedure", order => "aaa, ccc, ddd", out=>"ddd, ccc", value =>"134");

	print join "#", @array;

	$db->disconnect();

=item I<order>  存储过程需要的参数名

字符串形式, [param] or [param1, param2..., ]

按照顺序写入,包含in类型和out类型, 传入后会自动去掉空白符

in类型输入值的顺序与value值的顺序应对应

out类型为返回值, 顺序按照out的顺序返回成数组形式

=item I<out>  存储过程返回的参数名

字符串形式, [param] or [outparam1, outparam2..., ]

按照顺序写入, 只有out类型的顺序, 传入后会自动去掉空白符

=item I<vlaue>  存储过程输入参数的值

输入参数值, 以,分割, 以输入值不作任何修改传入

=item I<return> 0|1

0 无返回, 或失败

1 有返回, 返回结果为数组形式

=cut

sub produce{
	my $class = shift;
	
	my %params = @_;
	
	my $err = 0;

	return ($err-1, "connect lost") if (!$class->{alive});
	
	$params{prodname} =~ s/\s+//g;
	$params{order} =~ s/\s+//g;
	$params{out} =~ s/\s+//g;
	my ($i, %outs, @in, @outtemp, @out);
	$i = 0;
	map {$outs{$_} = 1, $outtemp[$i++] = $_} split(/,/, $params{out});

	if (not exists($params{prodstring})){
		$params{prodstring} = q{
begin
};

		$params{prodstring} .= $params{prodname}."(";

		my ($cc, $j) = (0, 0);
		foreach (split(/,/, $params{order})){
			$in[$j++] = $_ if (!$outs{$_});
			$params{prodstring} .= ', ' if ($cc);
			$params{prodstring} .= "$_ => :$_";
			$cc = 1;
		}

		$params{prodstring} .= q{);
end;
};
	}
	#print $params{prodstring};	
	my ($sth);
	eval{
		$sth = $class->{dbhandle}->prepare($params{prodstring});
		my $count = 0;
		foreach (split(/,/, $params{value})){
			$sth->bind_param(":$in[$count++]", $_);
		}
		$count = 0;
		foreach (@outtemp){
			$sth->bind_param_inout(":$_", \($out[$count++]), 1);
		}
		$sth->execute();
	};
	if ($@){
        $class->{dbhandle}->rollback();
        $sth->finish();
		return 0;
	}else{
		$class->{dbhandle}->commit();
		return ($err, @out);
	}
}

=head1 AUTHOR and ACKNOWLEDGEMENTS

        hucg@asiainfo-linkage.com

=cut

1;
