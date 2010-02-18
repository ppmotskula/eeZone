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

# parse arguments;
# if second argument is -r then spawn background processes
# to handle domains starting with each letter in the list,
# then keep track of process count and exit when all childs
# are finished.
$domainsFile = $ARGV[0];
$sql = ('-s' eq $ARGV[2]);
if ($sql) {
    $sqlFile = $domainsFile;
    $sqlFile =~ s/\.txt$//;
    $sqlFile .= '.sql';
}
if ($ARGV[1] eq '-r') {
    $chars = '0123456789abcdefghijklmnopqrstuvwxyz';
    if ($sql) {
        open OUT, ">$sqlFile" or die "cannot open output file $sqlFile\n";
        print OUT "DROP TABLE IF EXISTS domains;\n";
        print OUT "CREATE TABLE domains (domain, root_ip, www_ip);\n";
        print OUT "BEGIN;\n";
        close OUT;
    }
    for ($i = 0; $i < length($chars); $i++) {
        $x = substr($chars, $i, 1);
        system("$0 $domainsFile $x $ARGV[2] &");
    }
    do {
        $ps = `ps aux | grep -c $0`;
        chomp $ps;
        $ps = $ps - 2;
        if ($sql) {
            print "$ps \r";
        }
        sleep 1;
    } while ($ps);
    if ($sql) {
        open OUT, ">>$sqlFile";
        print OUT "COMMIT;\n";
        close OUT;
        print " \r";
    }
    print "\n";
    exit;
} elsif (length($firstLetter = $ARGV[1]) != 1) {
    die 'usage:
    eeDomains.pl <DomainsFile> -r|<firstLetter> [-s];
';
}

# process domains starting with a given letter

open SRC, $domainsFile or die "cannot open domains file $domainsFile\n";
open OUT, ">>$sqlFile";
DOMAIN: while ($domain = <SRC>) {
    if (substr($domain, 0, 1) ne $firstLetter) {
        next DOMAIN;
    }
    chomp $domain;
    $_ = `host -t a $domain`;
    if (/has address (\S+)/) {
        $rootIp = $1;
    } else {
        $rootIp = '-';
    }
    $_ = `host -t a www.$domain`;
    if (/has address (\S+)/) {
        if ($rootIp eq $1) {
            $wwwIp = '*';
        } else {
            $wwwIp = $1;
        }
    } else {
        $wwwIp = '-';
    }
    if ($sql) {
        # sql output
        print OUT "INSERT INTO domains (domain, root_ip, www_ip) VALUES ('$domain', '$rootIp', '$wwwIp');\n";
    } else {
        # plaintext output
        print "$domain\t$rootIp\t$wwwIp\n";
    }
}
close OUT;
