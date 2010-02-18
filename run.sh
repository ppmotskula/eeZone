#!/bin/bash

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

if [[ "$1" == "" ]] ; then
    echo 'usage:
    run.sh -r|-z|-d|-h [-s]
    (recurse all, zone, domain, hosts, recreate sql and update db (slow!))

See README for details.
'
    exit
fi

if [[ "$1" == "-r" || "$1" == "-z" ]] ; then
    echo "parsing eeZone.txt";
    if [ "$2" == "-s" ] ; then
        ./eeZone.pl data/eeZone.txt -s
        sqlite3 data/eeZone.db < data/eeZone.sql
    fi
    sqlite3 data/eeZone.db '
SELECT DISTINCT domain
FROM zone
ORDER BY domain ASC;
    ' > data/eeDomains.txt
    sqlite3 -separator '	' data/eeZone.db '
SELECT ns_domain, count(*)
FROM zone
GROUP BY ns_domain
ORDER BY count(*) DESC;
    ' > data/topNsDomains.txt
fi

if [[ "$1" == "-r" || "$1" == "-d" ]] ; then
    echo "parsing eeDomains.txt";
    if [ "$2" == "-s" ] ; then
        ./eeDomains.pl data/eeDomains.txt -r -s
        sqlite3 data/eeZone.db < data/eeDomains.sql
    fi
    sqlite3 -separator '	' data/eeZone.db '
SELECT ip, count(*) AS vhosts
FROM (
        SELECT domain, root_ip AS ip
        FROM domains
        WHERE root_ip != "-"
    UNION
        SELECT domain, www_ip AS ip
        FROM domains
        WHERE www_ip != "-" AND www_ip != "*"
)
GROUP BY ip
ORDER BY vhosts DESC;
    ' > data/eeHosts.txt
fi

if [[ "$1" == "-r" || "$1" == "-h" ]] ; then
    echo "parsing eeHosts.txt";
    if [ "$2" == "-s" ] ; then
        ./eeHosts.pl data/eeHosts.txt -s
        sqlite3 data/eeZone.db < data/eeHosts.sql
    fi
    sqlite3 -separator '	' data/eeZone.db '
SELECT domain, sum(vhosts) AS vhosts
FROM providers
GROUP BY domain
ORDER BY vhosts DESC, domain ASC;
    ' > data/topHostingDomains.txt
    sqlite3 -separator '	' data/eeZone.db '
SELECT netname, sum(vhosts) AS vhosts
FROM providers
GROUP BY netname
ORDER BY vhosts DESC, netname ASC;
    ' > data/topHostingNetnames.txt
    sqlite3 -separator '	' data/eeZone.db '
SELECT domain, count(vhosts) AS vhosts
FROM providers
GROUP BY domain
ORDER BY vhosts DESC, domain ASC;
    ' > data/topProviderDomains.txt
    sqlite3 -separator '	' data/eeZone.db '
SELECT netname, count(vhosts) AS vhosts
FROM providers
GROUP BY netname
ORDER BY vhosts DESC, netname ASC;
    ' > data/topProviderNetnames.txt
fi
