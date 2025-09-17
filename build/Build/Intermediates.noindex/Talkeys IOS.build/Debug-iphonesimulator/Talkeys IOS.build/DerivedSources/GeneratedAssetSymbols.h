#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "splash_bg" asset catalog image resource.
static NSString * const ACImageNameSplashBg AC_SWIFT_PRIVATE = @"splash_bg";

#undef AC_SWIFT_PRIVATE
