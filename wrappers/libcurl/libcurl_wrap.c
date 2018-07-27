#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <fcntl.h>
#include <dlfcn.h>
#define NO_REDIRECT_CURL_FUNCS
#include <curl/curl.h>

static void *libcurl = NULL;

__attribute__((__visibility__("hidden")))
CURLcode (*indirect_curl_global_init)(long flags) = NULL;
__attribute__((__visibility__("hidden")))
void (*indirect_curl_global_cleanup)(void) = NULL;

__attribute__((__visibility__("hidden")))
curl_version_info_data *(*indirect_curl_version_info)(CURLversion) = NULL;

__attribute__((__visibility__("hidden")))
CURL *(*indirect_curl_easy_init)(void) = NULL;
__attribute__((__visibility__("hidden")))
CURLcode (*indirect_curl_easy_getinfo)(CURL *curl, CURLINFO info, ...) = NULL;
__attribute__((__visibility__("hidden")))
CURLcode (*indirect_curl_easy_setopt)(CURL *curl, CURLoption option, ...) = NULL;
__attribute__((__visibility__("hidden")))
CURL* (*indirect_curl_easy_duphandle)(CURL *curl) = NULL;
__attribute__((__visibility__("hidden")))
void (*indirect_curl_easy_reset)(CURL *curl) = NULL;
__attribute__((__visibility__("hidden")))
CURLcode (*indirect_curl_easy_pause)(CURL *handle, int bitmask) = NULL;
__attribute__((__visibility__("hidden")))
void (*indirect_curl_easy_cleanup)(CURL *curl) = NULL;

__attribute__((__visibility__("hidden")))
CURLM *(*indirect_curl_multi_init)(void) = NULL;
__attribute__((__visibility__("hidden")))
CURLMsg *(*indirect_curl_multi_info_read)(CURLM *multi_handle,
                                          int *msgs_in_queue) = NULL;
__attribute__((__visibility__("hidden")))
CURLMcode (*indirect_curl_multi_fdset)(CURLM *multi_handle,
                                       fd_set *read_fd_set,
                                       fd_set *write_fd_set,
                                       fd_set *exc_fd_set,
                                       int *max_fd) = NULL;
__attribute__((__visibility__("hidden")))
CURLMcode (*indirect_curl_multi_timeout)(CURLM *multi_handle,
                                         long *milliseconds) = NULL;
__attribute__((__visibility__("hidden")))
CURLMcode (*indirect_curl_multi_perform)(CURLM *multi_handle,
                                         int *running_handles) = NULL;
__attribute__((__visibility__("hidden")))
CURLMcode (*indirect_curl_multi_add_handle)(CURLM *multi_handle,
                                            CURL *curl_handle) = NULL;
__attribute__((__visibility__("hidden")))
CURLMcode (*indirect_curl_multi_remove_handle)(CURLM *multi_handle,
                                               CURL *curl_handle) = NULL;
__attribute__((__visibility__("hidden")))
CURLMcode (*indirect_curl_multi_cleanup)(CURLM *multi_handle) = NULL;

__attribute__((__visibility__("hidden")))
CURLSH *(*indirect_curl_share_init)(void) = NULL;
__attribute__((__visibility__("hidden")))
CURLSHcode (*indirect_curl_share_setopt)(CURLSH *, CURLSHoption option, ...) = NULL;
__attribute__((__visibility__("hidden")))
CURLSHcode (*indirect_curl_share_cleanup)(CURLSH *) = NULL;

#define RESOLVE(NAME) *(void **) (&indirect_##NAME) = dlsym(libcurl, #NAME); \
  if (!indirect_##NAME) goto fail

static int try_load(const char *so_name) {
    if (!indirect_curl_global_init) {
        libcurl = dlopen(so_name, RTLD_LAZY|RTLD_LOCAL);
        if (!libcurl) return -1;
    }
    RESOLVE(curl_global_init);
    RESOLVE(curl_global_cleanup);
    RESOLVE(curl_version_info);
    RESOLVE(curl_easy_init);
    RESOLVE(curl_easy_getinfo);
    RESOLVE(curl_easy_setopt);
    RESOLVE(curl_easy_duphandle);
    RESOLVE(curl_easy_reset);
    RESOLVE(curl_easy_pause);
    RESOLVE(curl_easy_cleanup);
    RESOLVE(curl_multi_init);
    RESOLVE(curl_multi_info_read);
    RESOLVE(curl_multi_fdset);
    RESOLVE(curl_multi_timeout);
    RESOLVE(curl_multi_perform);
    RESOLVE(curl_multi_add_handle);
    RESOLVE(curl_multi_remove_handle);
    RESOLVE(curl_multi_cleanup);
    RESOLVE(curl_share_init);
    RESOLVE(curl_share_setopt);
    RESOLVE(curl_share_cleanup);
    return 0;
 fail:
    dlclose(libcurl);
    libcurl = NULL;
    indirect_curl_global_init = NULL;
    return -1;
}

CURLcode curl_global_init(long flags) {
    int not_loaded = -1;
    // Usual name for libcurl; openssl version on debian-based systems
    not_loaded = try_load("libcurl.so.4");
    // Gnutls version on debian-based systems
    if (not_loaded) not_loaded = try_load("libcurl-gnutls.so.4");
    // Fallback libcurl, included in the package
    if (not_loaded) {
        not_loaded = try_load("${ORIGIN}/../lib/fallback/libcurl.so");
    }
    // Give up if not loaded at this point
    if (not_loaded) return CURLE_FAILED_INIT;

    return indirect_curl_global_init(flags);
}

// These are needed so that the configure script detects libcurl correctly.
// They should not be called in practice thanks to the redirection macros.
CURLcode curl_easy_pause(CURL *handle, int bitmask) {
    return indirect_curl_easy_pause(handle, bitmask);
}
CURL * curl_easy_init(void) {
    return indirect_curl_easy_init();
}
