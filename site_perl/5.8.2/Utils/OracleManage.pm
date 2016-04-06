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

	Oracle���ݿ�����������

=head1 SYNOPSIS

	Oracle���ݿ�����������

=head1 DESCRIPTION

	register, cancel, 

=head1 USAGE

my $dbs = Util::OracleManage->register(name=>"example", dbname=>"dbi:Oracle:example", user=>"user", passwd=>"pass");

my ($state, $value) = $dbs->{example}->sql(sqlstring => 'select * from table where rownum = 1');

$dbs->{example}->disconnect();


my $dbs = Util::OracleManage->cancel(name=>"example");

=head1 METHODS

=head2 connect( [-option=>value ...] )

connect����, ��������:

=over 10 

=item I<name> �Զ�����

���ݿ�����: "example"

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

�Ͽ���ע�������ݿ�

=over 10

=item i<> ���ݿ���

���ݿ��Զ����� name=>"example"

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

����sql���

=over 10

=item I<> ���ݿ���

���ݿ��Զ����� name=>"example"

=item I<> sql���

ʵ��ִ�е�SQL���

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

	# ���$st���д���
	return ($st, $res);
}

=head1 AUTHOR and ACKNOWLEDGEMENTS

        hucg@asiainfo-linkage.com

=cut

1;
