#import <Foundation/Foundation.h>

@interface NSString (CompareToVersion)

- (NSComparisonResult)CompareToVersion:(NSString *)version;

- (BOOL)isOlderThanVersion:(NSString *)version;
- (BOOL)isNewerThanVersion:(NSString *)version;
- (BOOL)isEqualToVersion:(NSString *)version;
- (BOOL)isEqualOrOlderThanVersion:(NSString *)version;
- (BOOL)isEqualOrNewerThanVersion:(NSString *)version;

@end
