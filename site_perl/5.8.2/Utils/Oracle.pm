#!/usr/bin/perl -w
package Utils::Oracle;
use vars qw($VERSION);

BEGIN {
$Utils::Oracle::VERSION = "1.01";
}

use strict;
use DBI;

=head1 NAME

	Oracle��������

=head1 SYNOPSIS

	Oracle��������

=head1 DESCRIPTION

	Oracle������(connect), �Ͽ�(disconnect), ִ��SQL(sql), ִ�д洢����(produce)

=head1 USAGE

my $db = Util::Oracle->connect(dbname=>"dbi:Oracle:example", user=>"user", passwd=>"pass");

my ($state, $value) = $db->sql(sql => 'select * from table where rownum = 1');

$db->disconnect();

=head1 METHODS

=head2 connect( [-option=>value ...] )

connect����, ��������:

=over 10 

=item I<dbname> ���ݿ���

���ݿ�����: "dbi:Oracle:example"

=item I<user> �û��� 

�û���

=item I<passwd> �û�����Ӧ�Ŀ���

�û�������

=item I<-options>  ��ӦDBI::Oracle�е��������

��ӦDBI::Oracle�е��������

=item I<return> ����ֵ

���ݿ������

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

�Ͽ�����

=cut

sub disconnect{
	my $class = shift;
	
	$class->{dbhandle}->rollback();
	$class->{dbhandle}->disconnect();

	$class->{alive} = 0;	
}

=head2 sql( [-option=>value ...] )

=item I<sql> ִ�е���� 

ʵ��ִ�е�SQL���, ִ�е����ķ��ؼ�¼ֻ��һ��

=item I<return> ����ֵ 0 | 1 | -1 | -2

0 ִ�гɹ� ��SELECT��� 

1 ִ�гɹ� SELECT��� �з���ֵ

-1 ���Ӷ�ʧ

-2 ִ�����ʧ��

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

=item I<prodstring> ִ�еĴ洢���̵������

�洢���̵��÷�ʽ ��: 

	begin

  	-- Call the procedure

  	test_procedure(in_param => :in_param,

                 out_param => :out_param);
	
	end;

ʹ��ʱ �����·�ʽд��

example:
	
	my $db = Util::Oracle->connect(dbname=>"dbi:Oracle:cuqcs", user=>"autotest", passwd=>"autotest");

	# aaa��ֵΪ134  ccc, dddΪ����ֵ, �����@array��, ˳��Ϊddd, ccc 
	
	my ($state, @array) = $db->produce(prodname=> "ex_procedure", order => "aaa, ccc, ddd", out=>"ddd, ccc", value =>"134");

	print join "#", @array;

	$db->disconnect();

=item I<order>  �洢������Ҫ�Ĳ�����

�ַ�����ʽ, [param] or [param1, param2..., ]

����˳��д��,����in���ͺ�out����, �������Զ�ȥ���հ׷�

in��������ֵ��˳����valueֵ��˳��Ӧ��Ӧ

out����Ϊ����ֵ, ˳����out��˳�򷵻س�������ʽ

=item I<out>  �洢���̷��صĲ�����

�ַ�����ʽ, [param] or [outparam1, outparam2..., ]

����˳��д��, ֻ��out���͵�˳��, �������Զ�ȥ���հ׷�

=item I<vlaue>  �洢�������������ֵ

�������ֵ, ��,�ָ�, ������ֵ�����κ��޸Ĵ���

=item I<return> 0|1

0 �޷���, ��ʧ��

1 �з���, ���ؽ��Ϊ������ʽ

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
