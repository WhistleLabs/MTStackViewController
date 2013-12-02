//
//  SystemVersions.h
//  Whistle
//
//  Created by Justin Middleton on 3/26/13.
//  Copyright (c) 2013 whistle. All rights reserved.
//

#import <Foundation/NSObjCRuntime.h>

#ifndef Whistle_SystemVersions_h
#define Whistle_SystemVersions_h

/*
 * SDK Availability
 */

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 70000
#define WL_HAS_7_SDK 0
#else
#define WL_HAS_7_SDK 1
#endif

/*
 * OS-specific wrappers
 */

#ifndef NSFoundationVersionNumber_iOS_6_1
#define NSFoundationVersionNumber_iOS_6_1 993.00
#endif

#define WL_RUNNINGON_7 floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1
#define WL_RUNNINGON_6 floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1

/*
 * Only execute if running on iOS6. This is just a runtime check;
 * any code enclosed here will be present in the compiled app.
 */

#define WL_RUNON_6(code) \
    if (WL_RUNNINGON_6) { \
        code; \
    }

#if WL_HAS_7_SDK == 1  // XCode5 and above

/*
 * If something was deprecated in 6, it's probably gone in 7.
 * Use this if something that was legal but deprecated in 6
 * causes a compilation error in 7. Any code enclosed in this
 * macro will NOT be present in an iOS6 build.
 */

#define WL_INCLUDEON_6(code)

/*
 * Only execute if running on iOS7
 */

#define WL_RUNON_7(code) \
    if (WL_RUNNINGON_7) { \
        code; \
    }

#else  // XCode 4

/*
 * XCode4 doesn't know about iOS7, so don't include the code.
 */

#define WL_RUNON_7(code)

/*
 * Go ahead and add clang diagnostic stuff in XCode4, only include
 * outside of the presence of iOS7 SDK, and only
 * execute on iOS6
 */

#define WL_INCLUDEON_6(code) \
    WL_RUNON_6(code)

#endif

#endif
