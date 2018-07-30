/*  locate_plugins.c -- Find BCFtools plugins relative to binary location

    Copyright (c) 2018 Genome Research Ltd.

    Author: Rob Davies <rmd@sanger.ac.uk>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.  */

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
