#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdbool.h>
#include <CoreFoundation/CoreFoundation.h>

// OSStatus SecTrustSetNetworkFetchAllowed(SecTrustRef trust, Boolean allowFetch);

typedef OSStatus (pr_realSecTrustSetNetworkFetchAllowed) (void *, Boolean);
typedef pr_realSecTrustSetNetworkFetchAllowed* pt_pr_realSecTrustSetNetworkFetchAllowed;
static pt_pr_realSecTrustSetNetworkFetchAllowed realSecTrustSetNetworkFetchAllowed;

__attribute__((constructor)) static void initSecShim(){
    void *handle = dlopen ("/System/Library/Frameworks/Security.framework/Versions/A/Security", RTLD_NOW);
    if (!handle) {
        puts (dlerror());
        abort();
    }

    realSecTrustSetNetworkFetchAllowed = (pt_pr_realSecTrustSetNetworkFetchAllowed) dlsym(handle, "SecTrustSetNetworkFetchAllowed");
}

OSStatus SecTrustSetNetworkFetchAllowed(void *trust, Boolean allowFetch) {
    if(realSecTrustSetNetworkFetchAllowed) {
        return realSecTrustSetNetworkFetchAllowed(trust, allowFetch);
    } else {
        return 0;
    }
}

