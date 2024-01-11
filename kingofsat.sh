#!/bin/bash
# This script converts https://en.kingofsat.net SATTV data to Services_KingOfSat_ALL.txt to be imported in dreamboxEDIT
#
#    Copyright (C) 2023  Silvester Vossen
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#

echo "checking system configuration"

if ! iconv -V > /dev/null; then
	echo "Please install iconv first. ERROR."
	exit 1
fi

if ! recode --version > /dev/null; then
	echo "Please install recode first. ERROR."
	exit 1
fi

> /tmp/kingofsat.txt

cat << EOF | grep . | while read sat; do

19.2E
23.5E
28.2E

EOF

namespace=$(($(echo $sat | sed 's,[E.],,g') * 65536))
echo "retrieve kingofsat data for pos$sat from https://en.kingofsat.net"
wget -nv -O /tmp/pos$sat.html https://en.kingofsat.net/pos-$sat.php
if [ ! -s /tmp/pos$sat.html ]; then
	echo "kingofsat data for pos$sat could not be retrieved"
	exit
fi

echo "convert pos$sat to ascii"
iconv -f UTF-8 -t ASCII//TRANSLIT < /tmp/pos$sat.html | sed -e 's,&nbsp;,,g' > /tmp/pos$sat-asc.html

echo "parse kingofsat data for pos$sat"

# join complete table to one line:
sed -n 'H
/<\/table>/{
x
s/\n/ /g
s/\t//g
# create lines with data for every channel / transponder by replacing </tr> tag with newline:
s,</tr>,\n,g
p}
/<table/x' /tmp/pos$sat-asc.html \
| sed -n "/<td class=\"pos\"/{
# remove usused transponder data fields:
s,.*\(<td.*<td.*<td.*<td.*\)<td.*<td.*\(<td.*<td.*<td.*\)<td.*\(<td.*<td.*\)<td.*,\1\2\3,
# remove nbc text in front of Satellite name:
s,<span class=\"nbc\">.*</span><a class=\"bld\">,,
# divide cell with Symbolrate and FEC and add 3 zeros to Symbolrate:
s,<a class=\"bld\">\([^<]*\)</a> <a class=\"bld\">\([^<]*\)</a>,\1000</td><td>\2,
# convert Frequency into kHz:
s, *<td [^>]*class=\"bld\">\(.....\).\(..\)</td>,<td>\1\20</td>,
# convert Satellite position from string to value:
s,<td class=\"pos\" dir=\"ltr\">\([^<]*\)&deg;.</td>,<td>\1</td>,
h}
/<td>Audio<\/td>/ d
/<td class=\"ch\">/{
# remove usused channel data fields:
s,\(.*<td.*<td.*\)\(<td.*\)<td.*<td.*\(<td.*\)<td.*\(<td.*<td.*\)<td.*<td.*\(<td.*<td.*\)<td.*,\1\2\3\4\5,
# add Type field=25 at start for High Definition channels:
/<a title=\"High Definition\">/ {
s,.*<td.*<td.*\(<td.*<td.*<td.*<td.*<td.*<td.*\),<td>25</td>\1,
b cont}
# add Type field=2 at start for radio channels:
/<img src=\"\/radio.gif\"/ {
s,.*<td.*<td.*\(<td.*<td.*<td.*<td.*<td.*<td.*\),<td>2</td>\1,
b cont}
# add Type field=1 at start for SD TV channels:
s,.*<td.*<td.*\(<td.*<td.*<td.*<td.*<td.*<td.*\),<td>1</td>\1,
: cont
# replace all but last bouquet names with Package names followed by comma:
s_<a class=\"bq\"[^>]*>\([^<]*\)</a><br/>_\1,_g
# replace last bouquet name with Package name:
s,<a class=\"bq\"[^>]*>\([^<]*\)</a>,\1,
G
# join channel data and transponder data:
s,\n,,
# replace </td> tags with TAB:
s, *</td> *,\t,g
# remove remaining tags:
s, *<[^>]*> *,,g
# put fields 1..10 in the right order:
s,\(.*\t\)\(.*\t.*\t\)\(.*\t.*\t.*\t.*\t\)\(.*\t.*\t.*\t\)\(.*\t\)\(.*\t.*\t\)\(.*\t\)\(.*\t\)\(.*\t.*\t\),\2\1\4\7\5\8\3\6\9,
# put remaining fields in the right order:
s,\(.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t\)\(.*\t\)\(.*\t\)\(.*\t\)\(.*\t.*\)\t\(.*\t\)\(.*\t\),\1\7\6$namespace\t0\t\2\t\4\3\t0\t\5,
# remove services without name:
/^[^\t]/ p}" | recode html >> /tmp/kingofsat.txt

done

echo "join time share services"

cut -f3- /tmp/kingofsat.txt | sort > /tmp/kingofsat1.txt
# unique services:
sort -u /tmp/kingofsat1.txt > /tmp/kingofsat2.txt
# time shares:
diff /tmp/kingofsat1.txt /tmp/kingofsat2.txt | grep "^<"| cut -c3- > /tmp/kingofsat3.txt
# services without time shares:
diff /tmp/kingofsat2.txt /tmp/kingofsat3.txt | grep "^<"| cut -c3- > /tmp/kingofsat4.txt

# services without time shares:
cat /tmp/kingofsat4.txt | while read service; do
	grep "$service" /tmp/kingofsat.txt
done > /tmp/kingofsat5.txt
# time shares:
cat /tmp/kingofsat3.txt | while read service; do
	grep "$service" /tmp/kingofsat.txt \
	| sed -n 'N;s,^\(.*\)\(\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\)\n\(.*\)\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*,\1/\3\2,;p'
done >> /tmp/kingofsat5.txt

echo "Service Name	Package	Type	Satellite position	Satellite name	Frequency	Symbolrate	Polarization	FEC	Service ID	Transponder ID	Network ID	Namespace	Channelnumber	Video PID	Audio PID	Teletext PID	PCR PID	AC3 PID	Flags	System	Modulation" > Services_KingOfSat_ALL.txt
sort /tmp/kingofsat5.txt >> Services_KingOfSat_ALL.txt

# check output format:
# sed '/^.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*/'d Services_KingOfSat_ALL.txt

