#ifndef WRAPPER_CURL_CURL_H
#define WRAPPER_CURL_CURL_H

// Include the real curl.h
#include_next <curl/curl.h>

// Undo curl gcc typechecking macros
#ifdef curl_easy_setopt
#undef curl_easy_setopt
#endif
#ifdef curl_easy_getinfo
#undef curl_easy_getinfo
#endif
#ifdef curl_share_setopt
#undef curl_share_setopt
#endif

// Functions to be resolved via dlsym
__attribute__((__visibility__("hidden")))
extern CURLcode (*indirect_curl_global_init)(long flags);
__attribute__((__visibility__("hidden")))
extern void (*indirect_curl_global_cleanup)(void);

__attribute__((__visibility__("hidden")))
extern curl_version_info_data *(*indirect_curl_version_info)(CURLversion);

__attribute__((__visibility__("hidden")))
extern CURL *(*indirect_curl_easy_init)(void);
__attribute__((__visibility__("hidden")))
extern CURLcode (*indirect_curl_easy_getinfo)(CURL *curl, CURLINFO info, ...);
__attribute__((__visibility__("hidden")))
extern CURLcode (*indirect_curl_easy_setopt)(CURL *curl, CURLoption option, ...);
__attribute__((__visibility__("hidden")))
extern CURL* (*indirect_curl_easy_duphandle)(CURL *curl);
__attribute__((__visibility__("hidden")))
extern void (*indirect_curl_easy_reset)(CURL *curl);
__attribute__((__visibility__("hidden")))
extern CURLcode (*indirect_curl_easy_pause)(CURL *handle, int bitmask);
__attribute__((__visibility__("hidden")))
extern void (*indirect_curl_easy_cleanup)(CURL *curl);

__attribute__((__visibility__("hidden")))
extern CURLM *(*indirect_curl_multi_init)(void);
__attribute__((__visibility__("hidden")))
extern CURLMsg *(*indirect_curl_multi_info_read)(CURLM *multi_handle,
                                          int *msgs_in_queue);
__attribute__((__visibility__("hidden")))
extern CURLMcode (*indirect_curl_multi_fdset)(CURLM *multi_handle,
                                       fd_set *read_fd_set,
                                       fd_set *write_fd_set,
                                       fd_set *exc_fd_set,
                                       int *max_fd);
__attribute__((__visibility__("hidden")))
extern CURLMcode (*indirect_curl_multi_timeout)(CURLM *multi_handle,
                                         long *milliseconds);
__attribute__((__visibility__("hidden")))
extern CURLMcode (*indirect_curl_multi_perform)(CURLM *multi_handle,
                                         int *running_handles);
__attribute__((__visibility__("hidden")))
extern CURLMcode (*indirect_curl_multi_add_handle)(CURLM *multi_handle,
                                            CURL *curl_handle);
__attribute__((__visibility__("hidden")))
extern CURLMcode (*indirect_curl_multi_remove_handle)(CURLM *multi_handle,
                                               CURL *curl_handle);
__attribute__((__visibility__("hidden")))
extern CURLMcode (*indirect_curl_multi_cleanup)(CURLM *multi_handle);

__attribute__((__visibility__("hidden")))
extern CURLSH *(*indirect_curl_share_init)(void);
__attribute__((__visibility__("hidden")))
extern CURLSHcode (*indirect_curl_share_setopt)(CURLSH *, CURLSHoption option, ...);
__attribute__((__visibility__("hidden")))
extern CURLSHcode (*indirect_curl_share_cleanup)(CURLSH *);

#ifndef NO_REDIRECT_CURL_FUNCS
// Macros to replare the normal functions with the indirect replacements
#define curl_global_cleanup indirect_curl_global_cleanup
#define curl_version_info indirect_curl_version_info
#define curl_easy_init indirect_curl_easy_init
#define curl_easy_getinfo indirect_curl_easy_getinfo
#define curl_easy_setopt indirect_curl_easy_setopt
#define curl_easy_duphandle indirect_curl_easy_duphandle
#define curl_easy_reset indirect_curl_easy_reset
#define curl_easy_pause indirect_curl_easy_pause
#define curl_easy_cleanup indirect_curl_easy_cleanup

#define curl_multi_init indirect_curl_multi_init
#define curl_multi_info_read indirect_curl_multi_info_read
#define curl_multi_fdset indirect_curl_multi_fdset
#define curl_multi_timeout indirect_curl_multi_timeout
#define curl_multi_perform indirect_curl_multi_perform
#define curl_multi_add_handle indirect_curl_multi_add_handle
#define curl_multi_remove_handle indirect_curl_multi_remove_handle
#define curl_multi_cleanup indirect_curl_multi_cleanup

#define curl_share_init indirect_curl_share_init
#define curl_share_setopt indirect_curl_share_setopt
#define curl_share_cleanup indirect_curl_share_cleanup
#endif /* NO_REDIRECT_CURL_FUNCS */
#endif /* WRAPPER_CURL_CURL_H */
