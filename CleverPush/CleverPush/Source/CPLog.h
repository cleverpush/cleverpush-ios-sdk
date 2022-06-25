#import <Foundation/Foundation.h>

@interface CPLog : NSObject

typedef NS_ENUM(NSUInteger, CP_LOGLEVEL) {
    CP_LOGLEVEL_NONE,
    CP_LOGLEVEL_FATAL,
    CP_LOGLEVEL_ERROR,
    CP_LOGLEVEL_WARN,
    CP_LOGLEVEL_INFO,
    CP_LOGLEVEL_DEBUG,
    CP_LOGLEVEL_VERBOSE
};

+ (void)setLogLevel:(CP_LOGLEVEL)logLevel;
+ (void)fatal:(NSString* _Nonnull)format, ... NS_FORMAT_FUNCTION(1, 2);
+ (void)error:(NSString* _Nonnull)format, ... NS_FORMAT_FUNCTION(1, 2);
+ (void)warn:(NSString* _Nonnull)format, ... NS_FORMAT_FUNCTION(1, 2);
+ (void)info:(NSString* _Nonnull)format, ... NS_FORMAT_FUNCTION(1, 2);
+ (void)debug:(NSString* _Nonnull)format, ... NS_FORMAT_FUNCTION(1, 2);
+ (void)verbose:(NSString* _Nonnull)format, ... NS_FORMAT_FUNCTION(1, 2);

@end
