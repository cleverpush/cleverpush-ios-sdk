#import "NSString+VersionComparator.h"

static NSString *versionSeparator = @".";

@implementation NSString (VersionComparator)

- (NSComparisonResult)compareToVersion:(NSString *)version {
    if ([self isEqualToString:version]) {
        return NSOrderedSame;
    }
    
    NSArray *thisVersion = [self componentsSeparatedByString:versionSeparator];
    NSArray *compareVersion = [version componentsSeparatedByString:versionSeparator];
    NSInteger maxCount = MAX([thisVersion count], [compareVersion count]);
    
    for (NSInteger index = 0; index < maxCount; index++) {
        NSInteger thisSegment = (index < [thisVersion count]) ? [[thisVersion objectAtIndex:index] integerValue] : 0;
        NSInteger compareSegment = (index < [compareVersion count]) ? [[compareVersion objectAtIndex:index] integerValue] : 0;
        
        if (thisSegment < compareSegment) {
            return NSOrderedAscending;
        }
        if (thisSegment > compareSegment) {
            return NSOrderedDescending;
        }
    }
    return NSOrderedSame;
}

- (BOOL)isOlderThanVersion:(NSString *)version {
    return [self compareToVersion:version] == NSOrderedAscending;
}

- (BOOL)isNewerThanVersion:(NSString *)version {
    return [self compareToVersion:version] == NSOrderedDescending;
}

- (BOOL)isEqualToVersion:(NSString *)version {
    return [self compareToVersion:version] == NSOrderedSame;
}

- (BOOL)isEqualOrOlderThanVersion:(NSString *)version {
    return [self compareToVersion:version] != NSOrderedDescending;
}

- (BOOL)isEqualOrNewerThanVersion:(NSString *)version {
    return [self compareToVersion:version] != NSOrderedAscending;
}

- (BOOL)isBetweenVersion:(NSString *)lowerVersion andVersion:(NSString *)upperVersion {
    NSInteger versionToCheckInt = [self integerValue];
    NSInteger lowerVersionInt = [lowerVersion integerValue];
    NSInteger upperVersionInt = [upperVersion integerValue];
    return (versionToCheckInt >= lowerVersionInt) && (versionToCheckInt <= upperVersionInt);
}

@end
