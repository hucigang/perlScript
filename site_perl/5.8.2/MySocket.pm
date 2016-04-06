#!/usr/bin/perl -w
package MySocket;
use Socket;
use IO::Socket;
use POSIX;
use URI::URL;

sub do{
        my $class = shift;
        my ($realval) = shift;
        my ($st, $res);

#        my $addr = "127.0.0.1";
        my $addr = "132.35.77.21";
        my $port1 = "5124";
        my $iaddr = inet_aton($addr);
        my $paddr = sockaddr_in($port1, $iaddr);
        my $buf = undef;

        socket(SOCK,2,1,6) or return (3, "SOCKET CREATE FAILED ");
        connect(SOCK,$paddr) or return (3, "SOCKET CONNECT FAILED");
				binmode SOCK;
        print "Send $realval\n";
        syswrite(SOCK, $realval);
        my $bs = sysread(SOCK, $buf, 8);
        if (substr($buf, 6, 1) eq "Y"){
                $st = 1;
                my $size = 0;
								my $filebuf = "";
								#SOCK->blocking(8);
								while (1) {
       							my $rdn = sysread SOCK, my $buf, 4096;
        						unless (defined $rdn) {
                			next if $! == EAGAIN || $! == EINTR;
                			last;
        						}
        						last if $rdn == 0;
        						$size += $rdn;
        						$filebuf .= $buf;
								}
                $res = $filebuf;
        } elsif (substr($buf, 6, 1) eq "N"){
                $st = 2;
                my $size = 0;
								my $filebuf = "";
								#SOCK->blocking(8);
								while (1) {
       							my $rdn = sysread SOCK, my $buf, 4096;
        						unless (defined $rdn) {
                			next if $! == EAGAIN || $! == EINTR;
                			last;
        						}
        						last if $rdn == 0;
        						$size += $rdn;
        						$filebuf .= $buf;
								}
                $res = $filebuf;
        }else{
                $st = 3;
                $res = "JAVA CONTENT ERROR";    
        }
        return ($st, $res);
}

1;
