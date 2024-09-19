#!/bin/sh

L1=$(ls titles | tail -n 1)
L2=$(ls titles/$L1 | tail -n 1)

ls titles/$L1/$L2 | tail -n 1 | grep -Eo "[0-9]{6}" -m 1 | sed -E "s/0*([0-9]*)/\1/"


# find titles/\
# 	| grep -E "titles/[0-9]{2}/[0-9]{2}/[0-9]{6}" -o\
# 	| grep -E '[0-9]{6}' -o\
# 	| sort\
# 	| tail -n 1\
# 	| sed -E "s/0*(.*)/\1/"
