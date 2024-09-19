#!/bin/sh

target="total_info_100.txt"
# target="total_info.txt"
max_titles=10000

echo -n > "$target"

i=0

ls info | while IFS= read -r filename; do
	cat "info/$filename" >> "$target"

	if [[ $(( $i % 100 )) -eq 0 ]]; then
		echo "[$filename]"
	fi
	i=$(( i + 1 ))
	if [[ $i -eq $max_titles ]]; then
		break;
	fi
done



# find . -type f -exec cat {} \; > total_info.txt

# echo $(ls info)

# cat $(find info | head -n 2)

# cat info/*


# for i in $(ls info)
# do
# 	echo ""
# done