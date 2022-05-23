#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

@interface TestUtils : NSObject
+ (void)waitForVerifiedMock:(OCMockObject *)mock delay:(NSTimeInterval)delay;
@end
