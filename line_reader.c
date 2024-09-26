#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>

#define TOP_VISIBLE 15
#define MAX_ENTRIES 15024

typedef struct {
	char *name;
	int count;
	bool was_in_top;
} Entry;

int main() {
	const char* filename = "total_info.txt";

	FILE * fp;
	char * line = NULL;
	size_t len = 0;
	ssize_t read;

	fp = fopen(filename, "r");
	if(fp == NULL) {
		return 1;
	}

	Entry* entries_list = (Entry*)calloc(MAX_ENTRIES, sizeof(Entry));
	int entries_count = 0;


	int line_id = 0;
	bool in_characters_list = false;

	while((read = getline(&line, &len, fp)) != -1) {
		assert(line);
		// printf("Retrieved line of length %zu:\n", read);
		if(!strcmp(line, "Parodies:\n")) {
			in_characters_list = true;
		} else if(!strcmp(line, "\n")) {
			in_characters_list = false;
		} else {
			if(in_characters_list) {
				// printf("read: %s", line);
				int i = 0;
				for(; i < entries_count; i++) {
					if(!strcmp(entries_list[i].name, line)) {
						// printf("found copy: %d\n", i);
						entries_list[i].count += 1;
						int j = i;
						for(; j >= 1; j--) {
							if(entries_list[j - 1].count < entries_list[j].count) {
								// printf("up\n");
								Entry tmp = entries_list[j - 1];
								entries_list[j - 1] = entries_list[j];
								entries_list[j] = tmp;
							} else {
								break;
							}
						}
						entries_list[j].was_in_top |= j < TOP_VISIBLE;

						break;
					}
				}
				if(i == entries_count) {
					assert(entries_count < MAX_ENTRIES);
					Entry new_entry = {.name = line, .count = 1, .was_in_top = (i < TOP_VISIBLE)};
					entries_list[entries_count++] = new_entry;
					line = NULL;
					// create entry
				}
			}
		}
		line_id += 1;
		// if(line_id == 10000000) break;
	}

	fclose(fp);
	if (line) free(line);

	for(int i = 0; i < entries_count; i++) {
		printf("%4d%c %s", entries_list[i].count, entries_list[i].was_in_top ? '+' : ' ', entries_list[i].name);
	}
	// int was_in_top_count = 0
	// for(int i = 0; i < entries_count; i++) {
	// 	was_in_top_count += entries_list[i].was_in_top;
	// }
	// printf("was_in_top_count: %d\n", was_in_top_count)

	return 0;
}


// const char* filename = "total_info.txt";

// int main() {

// 	return 0;
// }