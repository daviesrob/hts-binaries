#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#define SELF_EXE "/proc/self/exe"

/*
  Find plugins dir relative to location pointed to by /proc/self/exe
  symlink.

  Notes:
   - Doesn't try to reclaim the memory used to store the location.  Valgrind
  classifies it as "still reachable".

   - If it fails, it advises the use of BCFTOOLS_PLUGINS, which will
  bypass this code.  It then calls exit, as there's no very good way of
  passing back an error condition.
*/

const char *locate_plugins(const char *relative_location) {
    static char *result = NULL;
    char *s;
    size_t rl_len = strlen(relative_location), link_len = 0;
    ssize_t r;

    if (result) return result;

    do {
        link_len = link_len ? link_len * 2 : 256;
        free(result);
        result = malloc(link_len + rl_len + 1);
        if (!result) {
            fprintf(stderr, "[E::locate_plugins] Out of memory\n");
            goto fail;
        }
        result[0] = '\0';
        r = readlink(SELF_EXE, result, link_len);
        if (r < 0) {
            fprintf(stderr, "[E::locate_plugins] Couldn't read \"%s\" link: %s\n",
                    SELF_EXE, strerror(errno));
            goto fail;
        }
    } while (r >= link_len);

    result[r] = '\0';
    s = strrchr(result, '/');
    if (!s) {
        fprintf(stderr, "[E::locate_plugins] Can't find directory containing bcftools program\n");
        goto fail;
    }
    memcpy(s + 1, relative_location, rl_len + 1);
    return result;

 fail:
    fprintf(stderr,
            "[E::locate_plugins] Set BCFTOOLS_PLUGINS to the location of the plugins\n"
            "directory to work around this problem.\n");
    exit(EXIT_FAILURE);
}
