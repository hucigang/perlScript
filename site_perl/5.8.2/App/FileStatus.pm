#!/usr/bin/perl -w
package App::FileStatus;
use vars qw($VERSION);

BEGIN {
	$App::FileStatus::VERSION = "1.01";
}


# 此部分只负责查找文件状态  对于文件的判断由State来完成
sub check{
	my $class = shift;
	my $prop = shift;

	my @result;
	my $stat = new App::FileStatus::get($prop->{FILENAME});
	
	printf "Look %s\n", $stat->blksize();
	if ($stat->blksize){
		return (CHECK_FILE_FOUND, []);
	}else{
		return (CHECK_FILE_NOT_FOUND, []);	
	}

	return (CHECK_FINISH_STATE, \@result);	
}

package App::FileStatus::get;
# App::FileStatus::get Copy From CPAN File::Stat  AUTHOR : Shin Honda<lt>makoto@cpan.jp<gt>
sub class	{ref$_[0]||$_[0]}
sub new		{bless [stat($_[1])],$_[0]->class;}
sub stat_	{CORE::stat(shift)}
sub lstat_	{CORE::lstat(shift)}
sub set		{
	return (
		$st_dev,$st_ino,$st_inode,$st_mode,$st_nlink,$st_uid,$st_gid,
		$st_rdev,$st_size,$st_atime,$st_mtime,$st_ctime,$st_blksize,$st_blocks
	) = @_;
}
sub stat {
	return new File::Stat(shift)	unless(wantarray);
	return set( stat_(shift) );
}
sub lstat {
	return new File::Stat(shift)	unless(wantarray);
	return set( lstat_(shift) );
}
sub dev		:method	{shift()->[ 0]}
sub ino		:method	{shift()->[ 1]}
sub inode	:method	{shift()->[ 1]}
sub mode	:method	{shift()->[ 2]}
sub nlink	:method	{shift()->[ 3]}
sub uid		:method	{shift()->[ 4]}
sub gid		:method	{shift()->[ 5]}
sub rdev	:method	{shift()->[ 6]}
sub size	:method	{shift()->[ 7]}
sub atime	:method	{shift()->[ 8]}
sub mtime	:method	{shift()->[ 9]}
sub ctime	:method	{shift()->[10]}
sub blksize	:method	{shift()->[11]}
sub blocks	:method	{shift()->[12]}

1;
