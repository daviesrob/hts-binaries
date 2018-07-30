/*  find_ca_files.c -- Look in likely locations for the CA bundle file

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

#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

__attribute__((constructor)) void hts_wrapper_find_ca_certs_file() {
    /*
      Annoyingly, certificates aren't stored in a standard location, and
      libraries only allow a single location to be set.  So instead of
      having a default path to find these, we need to go hunting for them.

      For more information, see:
      https://www.happyassassin.net/2015/01/12/a-note-about-ssltls-trusted-certificate-stores-and-platforms/

      This list is a combination of the search lists used by the gnutls and
      libcurl configure scripts.
     */

    const static char *locations[] = {
        "/etc/ssl/certs/ca-certificates.crt",
        "/etc/pki/tls/certs/ca-bundle.crt",
        "/etc/pki/tls/cert.pem",
        "/usr/share/ssl/certs/ca-bundle.crt",
        "/usr/local/share/certs/ca-root-nss.crt",
        "/etc/ssl/cert.pem",
        "/etc/ssl/ca-bundle.pem"
    };
    const size_t num_locs = sizeof(locations) / sizeof(locations[0]);
    const char *found = NULL;
    size_t i;
    int save_errno = errno;

    // Check if user has already supplied a CURL_CA_BUNDLE
    if (getenv("CURL_CA_BUNDLE") != NULL) {
        errno = save_errno;
        return;
    }

    for (i = 0; i < num_locs; i++) {
        int fd = open(locations[i], O_RDONLY);
        if (fd >= 0) {
            close(fd);
            found = locations[i];
            break;
        }
    }

    if (found)
        setenv("CURL_CA_BUNDLE", found, 0);

    errno = save_errno;
    return;
}
