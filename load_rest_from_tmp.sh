#!/bin/sh

./pages.sh $1 "$(ls tmp 2>/dev/null | grep -E "[0-9]+" || echo "")"

# ./pages.sh "$1" $(ls tmp 2>/dev/null | grep -E "[0-9]+" || echo "")