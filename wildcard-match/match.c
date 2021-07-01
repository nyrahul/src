/*
 * The aim of the code is to implement wildcard matching code that can be used
 * in eBPF.
 * Limitations of the code: we assume that the max file path size will be 256
 */

#include <stdio.h>
#include <string.h>
#include <assert.h>

#define MAX_PATH_SZ 256

/*
 * This function has to be eBPF compliant which means no unbound loops.
 */
#if 0
int wildcardMatch(const char* string, const char* wild)
{
    const char* cp = NULL, *mp = NULL;

    while ((*string) && (*wild != '*'))
    {
        if ((*wild != *string) && (*wild != '?'))
        {
            return 0;
        }
        wild++;
        string++;
    }

    while (*string)
    {
        if (*wild == '*')
        {
            if (!*++wild)
            {
                return 1;
            }
            mp = wild;
            cp = string+1;
        }
        else if ((*wild == *string) || (*wild == '?'))
        {
            wild++;
            string++;
        }
        else
        {
            wild = mp;
            string = cp++;
        }
    }

    while (*wild == '*')
    {
        wild++;
    }
    return !*wild;
}
#endif

#if 1
int wildcardMatch(const char* string, const char* wild)
{
	int i, w = 0, mp = 0, cp = 0;

	for (i = 0; i < MAX_PATH_SZ; i++) {
		if (!string[i] || wild[i] == '*') break;

		if ((wild[i] != string[i]) && (wild[i] != '?')) return 0;
	}
	w = i;

	for (; i < MAX_PATH_SZ;) {
		if (!string[i]) break;

		if (wild[w] == '*') {
			if (!wild[++w]) return 1;
			mp = w;
			cp = i+1;
		} else if ((wild[w] == string[i]) || (wild[w] == '?')) {
			w++;
			i++;
		} else {
			w = mp;
			i = cp++;
		}
	}

	for (; w < MAX_PATH_SZ; w++) {
		if (wild[w] != '*') break;
	}
    return !wild[w];
}
#endif

typedef struct {
	char *pat;
	int match;
} pattern_t;

int main(int argc, char *argv[])
{
	pattern_t pattern[] = {
		{ "/bin/*?sh", 1 },
		{ "/*/*sh", 1 },
		{ "*sh", 1 },
		{ "*s*", 1 },
		{ "/???/*sh", 1 },
		{ "*", 1 },
		{ "*sj", 0 },
		{ "/????/*sh", 0 },
		{ NULL, 0}
	};
	const char *str = "/bin/bash";
	int match, i;

	for (i = 0; pattern[i].pat; i++) {
		match = wildcardMatch(str, pattern[i].pat);
		printf("string[%s] %s wildcard[%s]\n", str, match?"MATCHED":"NOT MATCHED", pattern[i].pat);
		assert (match == pattern[i].match);
	}
	return 0;
}

