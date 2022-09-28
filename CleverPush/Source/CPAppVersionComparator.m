#import "CPAppVersionComparator.h"

@implementation NSString (CompareToVersion)

- (NSComparisonResult) CompareToVersion:(NSString *)version {
    if ([self isEqualToString:version])
        return NSOrderedSame;
    
    NSArray *thisVersion = [self componentsSeparatedByString:@"."];
    NSArray *compareVersion = [version componentsSeparatedByString:@"."];
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

@end
