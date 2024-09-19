#!/bin/bash

num_threads_if_only_info=20
num_title_threads=2
num_threads=16

attempt_time=120
restart_attempts=20
failed_to_load_log=failed_to_load.txt
full_log=full_log.txt

# echo "LIST: [$@]"
magic_numbers=$(echo "$@"| grep -Eo "[0-9]+")
# echo "MAGIC: [$magic_numbers]"

character_banlist_linux='s/(\/)/ /g'
character_banlist_mac='s/(\/)|:/ /g'
character_banlist_windows='s/(\/)|:|\||\*|"|<|>|\?|\\\\/ /g'

character_banlist="$character_banlist_windows"

ban_filename_characters(){
	sed -E -e "$character_banlist"
}

inside_list(){
	echo $2 | grep -w -q $1
}

write_and_log(){
	tee >(sed -E 's/\x1b[^m]*m//g' >> full_log.txt)
}
write_and_log_failed(){
	tee >(sed -E 's/\x1b[^m]*m//g' | tee -a "$failed_to_load_log" >> full_log.txt)
}


while getopts 'I:h' opt; do
  case "$opt" in
    I)
		only_info=true
      ;;
    W)
		character_banlist="$character_banlist_windows"
	  ;;
	M)
		character_banlist="$character_banlist_mac"
	  ;;
	L)
		character_banlist="$character_banlist_linux"
	  ;;
		
    ?|h)
      echo "Usage: $(basename $0) [-I] magic_numbers_list"
      exit 1
      ;;
  esac
done

wget_safe(){
	addr="$1"
	dest="$2"

	for i in $(seq 1 $restart_attempts); do
		result=$(wget --timeout="$attempt_time" --server-response "$addr" -O "$dest" 2>&1 | grep "HTTP/" | tail -n 1 | awk '{print $2}')
		if [[ ! "$result" ]]; then 
			result="000"
		fi

		if [[ "$result" -eq 200 ]]; then
			printf "\033[0;32mloaded %s\033[0m\n" "$dest" | write_and_log
			return 0
		else
			rm -f "$dest"
			if [ $i -eq $restart_attempts ] || [ "$result" == "404" ]; then
				printf "\033[0;31mfailed(%s) %s >>> %s\033[0m\n" "$result" "$addr" "$dest" | write_and_log_failed
				return 1
			else
				printf "\033[0;33mfailed(%s), retry: %s\033[0m\n" "$result" "$addr" | write_and_log
			fi
		fi
	done
	printf "\033[0;31m;UNREACHABLE REACHED (wget_safe, %s >>> %s)\033[0m\n" "$addr" "$dest" | write_and_log_failed
	return 1
}

get_gallery_id_and_ext(){
	title_id=$1
	page_id=$2
	directory_name=$3
	tmp_name=$(printf "tmp/%d/%d.html" $title_id $page_id)
	page_addr="https://nhentai.net/g/$title_id/$page_id"

    wget_safe "$page_addr" "$tmp_name"
    ok=$?

	image_addr=$(cat $tmp_name | grep -E "https://i[0-9]+\.nhentai\.net/galleries/[0-9]+/[0-9]+\.(png|jpg)" -o) &&
	gallery_id=$(echo "$image_addr" | sed -E -e "s/https:\/\/i([0-9]+)\.nhentai\.net\/galleries\/([0-9]+)\/([0-9]+)\.((png)|(jpg))/\2/g") &&
	image_ext=$(echo $image_addr | grep -E "\.(png|jpg)$" -o) &&

	echo "$gallery_id $image_ext" >&2
	rm -f $tmp_name

	return $ok
}

extract_page(){
	title_id=$1
	page_id=$2
	directory_name=$3
	gallery_id=$4
	page_filename=$5

	image_addr="https://i3.nhentai.net/galleries/$gallery_id/$page_id$image_ext"
    page_filename=$(printf "%s/%04d%s" "$directory_name" "$page_id" "$image_ext")

    wget_safe "$image_addr" "$page_filename"
}

pwait(){
	if [[ $1 -gt 1 ]]; then
		while [ $(jobs -p | wc -l) -ge $1 ]; do
		    sleep 1
		done
	else
		wait
	fi
}

extract_info(){
	source=$1

	info=$(grep <"$1" "$2" -A 1 -m 1 | tail -n 1 | grep -oP "<span class=\"name\">\K[^<]+")
	printf "$2\n%s\n\n" "$info"
}

validate_id_string(){
	id_string=$1
	if [[ $(echo "$id_string" | wc -c) != 7 ]]; then
		exit 1
	fi
}

html_decode(){
	sed -E\
		-e 's/&#(([0-2][0-9])|(30)|(31)|(x[0-1][0-9a-f]));//g'\
		-e 's/&#((x20)|(32));/ /g'\
		-e 's/&#((x21)|(33));/!/g'\
		-e 's/&((#((x22)|(34))));/\"/g'\
		-e 's/&#((x23)|(35));/#/g'\
		-e 's/&#((x24)|(36));/$/g'\
		-e 's/&#((x25)|(37));/%/g'\
		-e 's/&((#((x26)|(38)))|amp);/\&/g'\
		-e "s/&((#((x27)|(39)))|quot);/'/g"\
		-e 's/&#((x28)|(40));/(/g'\
		-e 's/&#((x29)|(41));/)/g'\
		-e 's/&#((x2a)|(42));/*/g'\
		-e 's/&#((x2b)|(43));/+/g'\
		-e 's/&#((x2c)|(44));/,/g'\
		-e 's/&#((x2d)|(45));/-/g'\
		-e 's/&#((x2e)|(46));/./g'\
		-e 's/&#((x2f)|(47));/\//g'\
		-e 's/&#((x30)|(48));/0/g'\
		-e 's/&#((x31)|(49));/1/g'\
		-e 's/&#((x32)|(50));/2/g'\
		-e 's/&#((x33)|(51));/3/g'\
		-e 's/&#((x34)|(52));/4/g'\
		-e 's/&#((x35)|(53));/5/g'\
		-e 's/&#((x36)|(54));/6/g'\
		-e 's/&#((x37)|(55));/7/g'\
		-e 's/&#((x38)|(56));/8/g'\
		-e 's/&#((x39)|(57));/9/g'\
		-e 's/&#((x3a)|(58));/:/g'\
		-e 's/&#((x3b)|(59));/;/g'\
		-e 's/&((#((x3c)|(60)))|lt);/</g'\
		-e 's/&#((x3d)|(61));/=/g'\
		-e 's/&((#((x3e)|(62)))|gt);/>/g'\
		-e 's/&#((x3f)|(63));/?/g'\
		-e 's/&#((x40)|(64));/@/g'\
		-e 's/&#((x41)|(65));/A/g'\
		-e 's/&#((x42)|(66));/B/g'\
		-e 's/&#((x43)|(67));/C/g'\
		-e 's/&#((x44)|(68));/D/g'\
		-e 's/&#((x45)|(69));/E/g'\
		-e 's/&#((x46)|(70));/F/g'\
		-e 's/&#((x47)|(71));/G/g'\
		-e 's/&#((x48)|(72));/H/g'\
		-e 's/&#((x49)|(73));/I/g'\
		-e 's/&#((x4a)|(74));/J/g'\
		-e 's/&#((x4b)|(75));/K/g'\
		-e 's/&#((x4c)|(76));/L/g'\
		-e 's/&#((x4d)|(77));/M/g'\
		-e 's/&#((x4e)|(78));/N/g'\
		-e 's/&#((x4f)|(79));/O/g'\
		-e 's/&#((x50)|(80));/P/g'\
		-e 's/&#((x51)|(81));/Q/g'\
		-e 's/&#((x52)|(82));/R/g'\
		-e 's/&#((x53)|(83));/S/g'\
		-e 's/&#((x54)|(84));/T/g'\
		-e 's/&#((x55)|(85));/U/g'\
		-e 's/&#((x56)|(86));/V/g'\
		-e 's/&#((x57)|(87));/W/g'\
		-e 's/&#((x58)|(88));/X/g'\
		-e 's/&#((x59)|(89));/Y/g'\
		-e 's/&#((x5a)|(90));/Z/g'\
		-e 's/&#((x5b)|(91));/[/g'\
		-e 's/&#((x5c)|(92));/\\/g'\
		-e 's/&#((x5d)|(93));/]/g'\
		-e 's/&#((x5e)|(94));/^/g'\
		-e 's/&#((x5f)|(95));/_/g'\
		-e 's/&#((x60)|(96));/`/g'\
		-e 's/&#((x61)|(97));/a/g'\
		-e 's/&#((x62)|(98));/b/g'\
		-e 's/&#((x63)|(99));/c/g'\
		-e 's/&#((x64)|(100));/d/g'\
		-e 's/&#((x65)|(101));/e/g'\
		-e 's/&#((x66)|(102));/f/g'\
		-e 's/&#((x67)|(103));/g/g'\
		-e 's/&#((x68)|(104));/h/g'\
		-e 's/&#((x69)|(105));/i/g'\
		-e 's/&#((x6a)|(106));/j/g'\
		-e 's/&#((x6b)|(107));/k/g'\
		-e 's/&#((x6c)|(108));/l/g'\
		-e 's/&#((x6d)|(109));/m/g'\
		-e 's/&#((x6e)|(110));/n/g'\
		-e 's/&#((x6f)|(111));/o/g'\
		-e 's/&#((x70)|(112));/p/g'\
		-e 's/&#((x71)|(113));/q/g'\
		-e 's/&#((x72)|(114));/r/g'\
		-e 's/&#((x73)|(115));/s/g'\
		-e 's/&#((x74)|(116));/t/g'\
		-e 's/&#((x75)|(117));/u/g'\
		-e 's/&#((x76)|(118));/v/g'\
		-e 's/&#((x77)|(119));/w/g'\
		-e 's/&#((x78)|(120));/x/g'\
		-e 's/&#((x79)|(121));/y/g'\
		-e 's/&#((x7a)|(122));/z/g'\
		-e 's/&#((x7b)|(123));/{/g'\
		-e 's/&#((x7c)|(124));/|/g'\
		-e 's/&#((x7d)|(125));/}/g'\
		-e 's/&#((x7e)|(126));/~/g'
}

load_title(){
	title_id=$1
	tmp_name=$(printf "tmp/%d" $title_id)

	mkdir -p "$tmp_name" &&

	id_string=$(printf "%06d" $title_id) &&
	main_filename="$tmp_name/main.html" &&
	wget_safe "https://nhentai.net/g/$title_id" "$main_filename" || { rm -rf $tmp_name && return; }

	title_name=$(cat $main_filename | grep -E "<title>.*</title>" -o | sed "s/<title>//" | sed "s/ &raquo; nhentai: hentai doujinshi and manga<\/title>//" | html_decode) &&
	directory_name="$(echo "$id_string" | sed -E "s/((..)(..)..)/titles\/\2\/\3\/\1/") $(echo "$title_name" | ban_filename_characters)"
	validate_id_string "$id_string"

	pages_count=$(cat "$main_filename" | grep "Pages:$" -A 1 -m 1 | grep -E "<span class=\"name\">[0-9]+</span>" -o | grep -E "[0-9]+" -o) &&
	upolad_time=$(cat "$main_filename" | grep "Uploaded:$" -A 1 -m 1 | tail -n 1 | grep -E '<time class="nobold" datetime="[^"]*">' -m 1 -o | sed -E 's/.*datetime="([^"]*)".*/\1/g')

	mkdir -p "$directory_name"

	info_filename="${directory_name}/info.txt"
	info_filename_alt="$(printf "info/%06d.txt" $title_id)"

	echo "$info_filename" | write_and_log
	echo -n > "$info_filename"

	# I HATE ANTICHRIST I HATE ANTICHRIST I HATE ANTICHRIST I HATE ANTICHRIST
	fmt1='(<span class="before">[^<]+</span>)?<span class="pretty">[^<]+</span>(<span class="after">[^<]+</span>)?'
	fmt2='s/(<span class="before">([^<]+)<\/span>)?<span class="pretty">([^<]+)<\/span>(<span class="after">([^<]+)<\/span>)?/\2\3\5/g'
	full_name=$(cat "$main_filename" | grep -oP "$fmt1" | sed -E "$fmt2" | html_decode)
	favorites_count=$(cat "$main_filename" | grep -E -m 1 "<span>Favorite <span class=\"nobold\">\([0-9]+\)</span></span>" -o | sed -E -e 's/<span>Favorite <span class=\"nobold">\(([0-9]+)\)<\/span><\/span>/\1/g')

	printf "Code:\n%s\n\n" "$title_id" >> "$info_filename"
	printf "Title:\n%s\n\n" "$title_name" >> "$info_filename"
	printf "Pages:\n%s\n\n" "$pages_count" >> "$info_filename"
	printf "Full name:\n%s\n\n" "$full_name" >> "$info_filename"
	printf "Uploaded:\n%s\n\n" "$upolad_time" >> "$info_filename"
	printf "Favorites:\n%s\n\n" "$favorites_count" >> "$info_filename"

	extract_info "$main_filename" "Parodies:" "parody" >> "$info_filename"
	extract_info "$main_filename" "Characters:" "character" >> "$info_filename"
	extract_info "$main_filename" "Tags:" "tag" >> "$info_filename"
	extract_info "$main_filename" "Artists:" "artist" >> "$info_filename"
	extract_info "$main_filename" "Groups:" "group" >> "$info_filename"
	extract_info "$main_filename" "Languages:" "language" >> "$info_filename"
	extract_info "$main_filename" "Categories:" "category" >> "$info_filename"

	cp -f "$info_filename" "$info_filename_alt"

	if [[ ! $only_info ]]; then
		exec 3>&1
		gallery_id_and_ext=$(get_gallery_id_and_ext "$title_id" "1" "$directory_name" 2>&1 1>&3)
		exec 3>&-

		if [ $? -ne 0 ] ; then
			printf "extention & id extraction failure: %s" "gallery_id_and_ext" | write_and_log_failed
			return 1
		fi

		gallery_id=$(echo "$gallery_id_and_ext" | sed -E "s/([^ ]*).*/\1/")
		image_ext=$(echo "$gallery_id_and_ext" | sed -E "s/[^ ]* (.*)/\1/")
		# TODO check if extention & id valid

		for page_id in $(seq 1 $pages_count)
		do
			extract_page $title_id $page_id "$directory_name" $gallery_id "$image_ext" &
			pwait $num_threads
		done
		wait
	fi

	rm -rf $tmp_name
	# rm -f $main_filename
}

printf "==== %s ====\n" "$(date)" | write_and_log_failed

mkdir -p titles
mkdir -p info
mkdir -p tmp

for title_id in $magic_numbers
do
	title_id_fixed=$(printf "%d" "$title_id")
	if [[ $only_info ]]; then
		load_title $title_id_fixed &
		pwait $num_threads_if_only_info
	else
		load_title $title_id_fixed &
		pwait "$num_title_threads"
	fi
done
wait

# rm -rf tmp

printf "~~~~ %s ~~~~\n" "$(date)" | write_and_log_failed