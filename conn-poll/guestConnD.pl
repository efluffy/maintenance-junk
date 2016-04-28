#!/usr/bin/perl

use strict;
use warnings;
use Sys::Syslog qw(:DEFAULT setlogsock);

my @statuses = ("up", "congested", "down");
my $avgPing;
my $status = 2;
my $lastStatus = 2;
my $time = time();
my $toLog;

while (1) {
	openlog("[GINET]", 'ndelay', 'local6');
	$avgPing = `ping -I x.x.x.x -i 0.25 -c 5 8.8.4.4 | tail -1 | cut -f 2 -d "=" | cut -f 2 -d"/" | cut -f 1 -d "."`;
	chomp($avgPing);
	if($avgPing =~ m/^\d+$/) {
		if($avgPing > 1000) {
			$status = 1;
		}
		else {
			$status = 0;
		}
	}
	else {
		$status = 2;
		$avgPing = "(timeout)";
	}
	if($status == 1 || $status == 2) {
		if((time() - $time) > 300) {
			$toLog = "Connection $statuses[$status] for " . int(((time() - $time)/60)) . " minutes. ($avgPing ms rtt)";		
			print "$toLog\n";
			syslog('info', $toLog);
		}
	}
	elsif($status != $lastStatus && $status == 0) {
		if(time() - $time > 300) {
			$toLog = "Connection $statuses[$status]. ($avgPing ms rtt)";
			print "$toLog\n";
			syslog('info', $toLog);
			$time = time();
		}
	}
	elsif($status == 0) {
		$time = time();
	}	
	
	$lastStatus = $status;
	closelog();
	sleep(60);
}
