#!/usr/bin/perl -w
use strict;
package Utils::String;
use vars qw($VERSION);

BEGIN {
	$Utils::String::VERSION = "1.01";
}

=head1 NAME

    String��������

=head1 SYNOPSIS

    String��������

=head1 DESCRIPTION

    ����ָ����ʽ�����ַ��� specStr ��{}Ϊһ����λ���н���

=head1 USAGE

my @arr = Util::String->specStr($string, $hashead);


my ($string, @arr) = Util::String->getOnce($string, $hashead);


=head1 METHODS

=head2 specStr( [-option=>value ...] )

connect����, ��������:

=over 10 

=item I<> �ַ���

��Ҫ�������ַ���

=item I<> �Ƿ�����ʼλ���ַ�

�Ƿ�����ʼλ���ַ�

=head2 getOnce( [-option=>value ...] )

ȡһ����λ��{}

=over 10

=item I<> �ַ���

��Ҫ�������ַ���

=item I<> �Ƿ�ȡ��ʼλ��

�Ƿ���ʼ���ַ���

=item I<> ����ֵ

1. ����ʣ��δ�������ַ���
2. ���ؽ����õ��ַ�������

=back

=cut

sub getOnce{
    my $class = shift;
	my $str = shift || "1";
	my $hashead = shift || "";
    my ($mask, $pos, @data);
    $pos = 0;
	$mask = 0;

    my (@p1arr, @p2arr);
    $_ = $str;
    my ($start, $end) = (undef, undef);
	return unless ($_);	
    while (/[{}]/g){
		if ($mask eq 1 && $#p1arr eq 0){
			last;
            $mask = pop @p2arr;
		}
        if ($& eq '{'){
            push @p1arr, pos()-length($&);
			$mask = 1;
        }
        if ($& eq '}'){
            push @p2arr, pos()-length($&);
            if ($#p1arr > 0) {
                pop @p1arr;
                pop @p2arr;
            }else{
                $start = pop @p1arr;
                $end = pop @p2arr;
            }
        }
		if (defined($start) && defined($end)){
            push @data, length(substr($_, $pos, $start-$pos)) eq 0 ? undef : substr($_, $pos, $start-$pos) unless ($hashead);
            push @data, substr($_, $start+1, $end-$start-1);
            $pos = $end+1;
            ($start, $end) = (undef, undef);
        }
    }
    return (substr($str, $mask-1), @data);
}

sub specStr{
    my $class = shift;
	my $str = shift || "1";
	my $hashead = shift || "";
    my ($pos, @data);

    $pos = 0;
    my (@p1arr, @p2arr);
    $_ = $str;
    my ($start, $end) = (undef, undef);
	return unless ($_);	
    while (/[{}]/g){
        if ($& eq '{'){
            push @p1arr, pos()-length($&);
        }
        if ($& eq '}'){
            push @p2arr, pos()-length($&);
            if ($#p1arr > 0) {
                pop @p1arr;
                pop @p2arr;
            }else{
                $start = pop @p1arr;
                $end = pop @p2arr;
            }
        }
		if (defined($start) && defined($end)){
            push @data, length(substr($_, $pos, $start-$pos)) eq 0 ? undef : substr($_, $pos, $start-$pos) unless ($hashead);
            push @data, substr($_, $start+1, $end-$start-1);
            $pos = $end+1;
            ($start, $end) = (undef, undef);
        }
    }
    return (@data);
}


=head1 AUTHOR and ACKNOWLEDGEMENTS

        hucg@asiainfo-linkage.com

=cut

1;
