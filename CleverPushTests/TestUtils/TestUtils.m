#import "TestUtils.h"
@implementation TestUtils

+ (void)waitForVerifiedMock:(OCMockObject *)inMock delay:(NSTimeInterval)inDelay
{
    NSTimeInterval i = 0;
    while (i < inDelay)
    {
        @try
        {
            [inMock verify];
            return;
        }
        @catch (NSException *e) {}
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        i+=0.5;
    }
    [inMock verify];
}

@end
