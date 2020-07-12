#!/bin/sh
# requires https://github.com/markc/midicomp to dump the midi file

TEMPO=120 # default in lv2 plugin

BASE=$(
midicomp "$1" \
| head -1 \
| cut -d' ' -f4
)

START=$(
midicomp "$1" \
| grep -E '[0-9]* (Off|On)' \
| sort -n \
| head -1 \
| cut -d' ' -f1
)

midicomp "$1" \
| grep -E '[0-9]* (Off|On|Par|PrCh|Tempo)' \
| sed 's/\([0-9]*\) On \(.*\) v=0/\1 Off \2 v=0/' \
| sort -n \
| sed 's/\([0-9]*\) On ch=\([0-9]*\) n=\([0-9]*\) v=\([0-9]*\)/On \1 \2 \3 \4/' \
| sed 's/\([0-9]*\) Off ch=\([0-9]*\) n=\([0-9]*\) v=\([0-9]*\)/Off \1 \2 \3 \4/' \
| sed 's/\([0-9]*\) Par ch=\([0-9]*\) c=\([0-9]*\) v=\([0-9]*\)/CC \1 \2 \3 \4/' \
| sed 's/\([0-9]*\) PrCh ch=\([0-9]*\) p=\([0-9]*\)/PC \1 \2 \3/' \
| sed 's/\([0-9]*\) Tempo \([0-9]*\)/BPM \1 \2/' \
| awk 'BEGIN  { d = 0; o = 0 ; bpm = 1 }
			 /BPM / { bpm = 60000000.0 / $3; printf ("\t// TEMPO %.3f BPM\n", bpm ); bpm = '$TEMPO' / bpm; } 
			 /On /  { t = t + ($2 - '$START' - o) * bpm / '$BASE'; d = t; o = $2 - '$START'; printf "\t{ %8.4f, 3, {0x9%x, %3d, 0x%02x} },\n", t, $3 - 1, $4, $5} 
       /Off / { t = t + ($2 - '$START' - o) * bpm / '$BASE'; d = t; o = $2 - '$START'; printf "\t{ %8.4f, 3, {0x8%x, %3d, 0x%02x} },\n", t, $3 - 1, $4, $5}
			 /CC /  { t = t + ($2 - '$START' - o) * bpm / '$BASE'; if (t < 0) t = 0; d = t; o = $2 - '$START'; printf "\t{ %8.4f, 3, {0xb%x, %3d, 0x%02x} },\n", t, $3 - 1, $4 - 1, $5}
			 /PC /  { t = t + ($2 - '$START' - o) * bpm / '$BASE'; if (t < 0) t = 0; d = t; o = $2 - '$START'; printf "\t{ %8.4f, 2, {0xc%x, 0x%02x, 0x00} },\n", t, $3 - 1, $4}
			 END    { d = int (d + 1); printf "\t{ %8.4f, 3, {0xff, 255, 0xff} },\n", d; }'


##| sed 's/ch=9 /ch=3 /' \
