#!/bin/sh

range="1 99999"

./pages $1 "$(comm <(ls info | grep -E "[0-9]{6}" -o) <(seq -f "%06.0f" $range) -1 -3 | sed -E -e "s/0*([0-9]+)/\1/g")"
