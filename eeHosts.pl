#!/usr/bin/perl

# eeZone 1.0, 2010-02-18
# See README for details

# Copyright © 2010 Peeter P. Mõtsküla <peeterpaul@motskula.net>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$sql = ('-s' eq $ARGV[1]);
if (!($hostsFile = $ARGV[0])) {
    die 'usage:
    eeHosts.pl <hostsFile> [-s]
';
}
if ($sql) {
    $sqlFile = $hostsFile;
    $sqlFile =~ s/\.txt$//;
    $sqlFile .= '.sql';
}

open SRC, $hostsFile or die "cannot open hosts file $hostsFile\n";
if ($sql) {
    open OUT, ">$sqlFile" or die "cannot open output file $sqlFile\n";
    print OUT "DROP TABLE IF EXISTS providers;\n";
    print OUT "CREATE TABLE providers (vhosts, ip, hostname, domain, netname);\n";
    print OUT "BEGIN;\n";
}
LINE: while (<SRC>) {
    chomp;
    ($ip, $vhosts) = split;
    print "$vhosts\t$ip\t";
    $host = `host $ip`;
    if ($host =~ /domain name pointer (.*?)\.\n/i) {
        $hostname = $1;
    } else {
        $hostname = '';
    }
    print "$hostname\t";
    if ($hostname) {
        $hostname =~ /^.*\.([^.]+\..+)$/;
        $domain = $1;
    } else {
        $domain = '';
    }
    print "$domain\t";
    $whois = `whois -H $ip`;
    if ($whois =~ /\nnetname:\s+(\S+)/i) {
        $netname = $1;
    } else {
        $netname = '';
    }
    print "$netname\n";
    if ($sql) {
        print OUT "INSERT INTO providers (vhosts, ip, hostname, domain, netname) VALUES ($vhosts, '$ip', '$hostname', '$domain', '$netname');\n";
    }
}
if ($sql) {
    print OUT "COMMIT;\n";
    close OUT;
}
print "\n";
