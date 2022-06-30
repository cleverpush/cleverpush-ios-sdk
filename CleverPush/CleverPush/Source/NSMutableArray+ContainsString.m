#import "NSMutableArray+ContainsString.h"

@implementation NSMutableArray (ContainsString)

- (BOOL)containsString:(NSString*)string {
    for (NSString* str in self) {
        if ([str isEqualToString:string])
            return YES;
    }
    return NO;
}

@end
