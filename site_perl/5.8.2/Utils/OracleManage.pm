#!/usr/bin/perl -w
package Utils::OracleManage;
use vars qw($VERSION);

BEGIN {
	$Utils::OracleManage::VERSION = "1.01";
}

use strict;
use Utils::Oracle;

%Utils::OracleManage::dbs = (
    "lyy" => "lyy",
);

=head1 NAME

	Oracle数据库管理基本功能

=head1 SYNOPSIS

	Oracle数据库管理基本功能

=head1 DESCRIPTION

	register, cancel, 

=head1 USAGE

my $dbs = Util::OracleManage->register(name=>"example", dbname=>"dbi:Oracle:example", user=>"user", passwd=>"pass");

my ($state, $value) = $dbs->{example}->sql(sqlstring => 'select * from table where rownum = 1');

$dbs->{example}->disconnect();


my $dbs = Util::OracleManage->cancel(name=>"example");

=head1 METHODS

=head2 connect( [-option=>value ...] )

connect连接, 参数如下:

=over 10 

=item I<name> 自定义名

数据库名如: "example"

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

sub new{
    my ($proto) = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    bless($self, $class);
    return $self;
}

sub register{
	my $class = shift;
	my (undef, $name, undef, $type, @params) = @_;
	
	$class->{$name} = Utils::Oracle->connect(@params) if ($type =~ m/oracle/i);
	$class->{$name} = \@params if ($type =~ m/alti/i);
}

sub test{
	my $class = shift;
	my (undef, $name, undef, $type, @params) = @_;

	$class->{$name} = $type;
	$class->{$name} = \@params if ($type =~ m/alti/i);
}

=head2 cancel( [-option=>value ...] )

断开并注销此数据库

=over 10

=item i<> 数据库名

数据库自定义名 name=>"example"

=back

=cut

sub cancel{
	my $class = shift;
	my (undef, $name) = @_;
	
	if (defined ($class->{$name}->{alive}) 
		&& $class->{$name}) {
		$class->{$name}->disconnect();
	} 

	delete $class->{$name};
}

=head2 _sql( [-option=>value ...] )

调用sql语句

=over 10

=item I<> 数据库名

数据库自定义名 name=>"example"

=item I<> sql语句

实际执行的SQL语句

=back 

=cut

sub _sql{
	my $class = shift;
	my (undef, $name, $tsql, $sql) = @_;

	print $name;
	if (not exists $class->{$name}){
		return -701, "";
	}
	
	my ($st, $res) = $class->{$name}->sql($tsql, $sql);

	# 需对$st进行处理
	return ($st, $res);
}

=head1 AUTHOR and ACKNOWLEDGEMENTS

        hucg@asiainfo-linkage.com

=cut

1;
