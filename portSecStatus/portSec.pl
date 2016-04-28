#!/usr/bin/perl 

use strict;
use Data::Dumper;

my $year = `date +%Y`; chomp($year);
my $month = `date +%b`; chomp($month);
my $day = `date +%d`; chomp($day);

my $path = "/path/to/configs";

my @files;
my $portStatus = {};
my $found = 0;
my $portSec = 0;

opendir(DH, $path) || die "Couldn't open config directory: $!\n";
@files = readdir(DH);
closedir(DH);

foreach my $file (@files) {
	open(FH, "<", $path . "/" . $file) || die "Couldn't open config file $file: $!\n";
	my @lines = <FH>;
	for(my $i = 0; $i < $#lines; $i++) {
		if($lines[$i] =~ m/interface/) {
			if($lines[$i] =~ m/FastEthernet/ || $lines[$i] =~ m/GigabitEthernet/) {
				my $hostname = (split /_/, $file)[0];
				my $ifName;
				if($lines[$i] =~ m/FastEthernet/) {
					$ifName = "fa" . (split /FastEthernet/, $lines[$i])[1];
				}
                                elsif($lines[$i] =~ m/TenGigabitEthernet/) {
                                        $ifName = "te" . (split /TenGigabitEthernet/, $lines[$i])[1];
                                }
				elsif($lines[$i] =~ m/GigabitEthernet/) {
					$ifName = "gi" . (split /GigabitEthernet/, $lines[$i])[1];
				}
				chomp($ifName);
				chomp($hostname); 
				for(my $j = $i; ; $j++) {
					if($lines[$j] =~ m/!/) { last; }
					if($lines[$j] =~ m/switchport port-security/i) {
						$portSec = 1;
						if($lines[$j] =~ m/switchport port-security violation restrict/i) {
							push @{$portStatus->{$hostname}}, "$ifName  -> YES";
							$found = 1;
							last;
						}
					}

				}
				if($portSec == 1 && $found == 0) {
					push @{$portStatus->{$hostname}}, "$ifName  ->  NO";
				} 
				elsif($portSec == 0 && $found == 0) {
					push @{$portStatus->{$hostname}}, "$ifName  -> N/A";
				}
				$portSec = 0;
				$found = 0;
			}
		}
	}
}
print "switchport port-security violation restrict status:\n YES = portsec on violation restrict, NO = portsec on violation NOT restrict, N/A = no portsec\n";
while (my ($key, $value) = each %{$portStatus}) {
	print $key . " = {\n";
	my $size = @{$portStatus->{$key}};
	for(my $k = 0; $k <= $size; $k += 4) {
		printf ("%18s %18s %18s %18s\n", $portStatus->{$key}[$k], $portStatus->{$key}[$k+1], $portStatus->{$key}[$k+2], $portStatus->{$key}[$k+3]);
	}
print "}\n\n";
}
