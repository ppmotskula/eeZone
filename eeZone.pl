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
if (!($zoneFile = $ARGV[0])) {
    die 'usage:
    eeZone.pl <zoneFile> [-s]
';
}

open SRC, $zoneFile or die "cannot open zonefile $zoneFile\n";

LINE: while (<SRC>) {
    chomp;
    if (/^\s*(\S+?\.\S+?)\.\s+86400\s+IN\s+NS\s+\S+?\.(\S+?\.\S+)\.\s*$/) {
        $domain = $1;
        $nsDomain = $2;
        if ($sql) {
            print "$domain                        \r";
        }
        $zone{"$domain\t$nsDomain"} = 1;
    }
}
if ($sql) {
    print "                                        \r";
}

if ($sql) {
    # prepare sql insert script
    $sqlFile = $zoneFile;
    $sqlFile =~ s/\.txt$//;
    $sqlFile .= '.sql';
    open OUT, ">$sqlFile" or die "cannot open sqlfile $sqlFile\n";
    print OUT "DROP TABLE IF EXISTS zone;\n";
    print OUT "CREATE TABLE zone (domain, ns_domain);\n";
    print OUT "BEGIN;\n";
    foreach (sort(keys %zone)) {
        ($domain, $nsDomain) = split;
        print OUT "INSERT INTO zone (domain, ns_domain) VALUES ('$domain', '$nsDomain');\n";
    }
    print OUT "COMMIT;\n";
    close OUT;
} else {
    # plaintext output
    foreach (sort(keys %zone)) {
        print "$_\n";
    }
}

print "\n";
