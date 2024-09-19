#!/bin/sh

source="total_info.txt"


# target="Characters:"
# cat "$source"\
# 	| grep "Characters:"\
# 	| wc -l


target="Characters:"
cat "$source"\
	| grep -Pzo "Characters:\n([^(\n)]+\n)*\n"\
	| tr -d '\0'\
	| sed -r "/^$/d"\
	| sed -r "/^Characters:$/d"\
	| tee raw_characters_list_100k.txt\
	| sort\
	| uniq -c\
	| sort -rn\
	> sorted_characters_list_100k.txt


# | grep -E "Characters"

# get_list_of_properties(){
# 	info_src=$1
# 	target=$2

# 	list=$(cat "$info_src" | grep -Pzo "$target:\n([^(\n)]+\n)*\n" | tr -d '\0')
# 	lc=$(echo "$list" | wc -l)
# 	echo "$list" | tail -n $(($lc - 1))
# }

# get_list_of_properties_total(){
# 	IFS=$'\n'
# 	for i in $(find . -name "info.txt" | sort); do
# 		get_list_of_properties "$i" $1
# 	done
# }

# max_titles=10
# get_list_of_properties_total(){
# 	i=0
# 	ls info | while IFS= read -r filename; do
# 		get_list_of_properties "info/$filename" $1
# 		echo "file: $filename" >&2
# 		i=$(( i + 1 ))
# 		if [[ $i -eq $max_titles ]]; then
# 			break;
# 		fi
# 	done
# }

# get_list_of_properties_total "Characters" | sort | uniq -c | sort -rn | head -n 15 | grep -o "[^ ].*"

# get_list_of_properties_total "Characters" | sort | uniq -c | sort -rn
# | head -n 15 | grep -o "[^ ].*"





# get_list_of_properties(){
# 	info_src=$1
# 	target=$2

# 	list=$(cat "$info_src" | grep -Pzo "$target:\n([^(\n)]+\n)*\n" | tr -d '\0')
# 	lc=$(echo "$list" | wc -l)
# 	echo "$list" | tail -n $(($lc - 1))
# }

# # get_list_of_properties_total(){
# # 	IFS=$'\n'
# # 	for i in $(find . -name "info.txt" | sort); do
# # 		get_list_of_properties "$i" $1
# # 	done
# # }

# # max_titles=10
# get_list_of_properties_total(){
# 	i=0
# 	ls info | while IFS= read -r filename; do
# 		get_list_of_properties "info/$filename" $1
# 		echo "file: $filename" >&2
# 		i=$(( i + 1 ))
# 		if [[ $i -eq $max_titles ]]; then
# 			break;
# 		fi
# 	done
# }

# get_list_of_properties_total "Characters" | sort | uniq -c | sort -rn | head -n 15 | grep -o "[^ ].*"

# # get_list_of_properties_total "Characters" | sort | uniq -c | sort -rn
# # | head -n 15 | grep -o "[^ ].*"
