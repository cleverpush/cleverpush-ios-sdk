#import <Foundation/Foundation.h>

@interface NSString (VersionComparator)

- (NSComparisonResult)compareToVersion:(NSString *)version;

- (BOOL)isOlderThanVersion:(NSString *)version;
- (BOOL)isNewerThanVersion:(NSString *)version;
- (BOOL)isEqualToVersion:(NSString *)version;
- (BOOL)isEqualOrOlderThanVersion:(NSString *)version;
- (BOOL)isEqualOrNewerThanVersion:(NSString *)version;
- (BOOL)isBetweenVersion:(NSString *)lowerVersion andVersion:(NSString *)upperVersion;

@end
