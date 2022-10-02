#import "CPAppBannerButtonBlock.h"
#import "NSDictionary+SafeExpectations.h"

@implementation CPAppBannerButtonBlock
#pragma mark - wrapping the data of the Banner Button Block in to CPAppBannerButtonBlock NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.type = CPAppBannerBlockTypeButton;

        self.text = @"";
        if ([json stringForKey:@"text"]) {
            self.text = [json stringForKey:@"text"];
        }

        if ([json stringForKey:@"color"] && ![[json stringForKey:@"color"] isEqual:@""]) {
            self.color = [json stringForKey:@"color"];
        } else {
            self.color = @"#000000";
        }

        if ([json stringForKey:@"family"] && ![[json stringForKey:@"family"] isEqual:@""]) {
            self.family = [json stringForKey:@"family"];
        }

        if ([json stringForKey:@"background"] && ![[json stringForKey:@"background"] isEqual:@""]) {
            self.background = [json stringForKey:@"background"];
        } else {
            self.background = @"#FFFFFF";
        }

        self.size = 18;
        if ([json objectForKey:@"size"]) {
            self.size = [[json objectForKey:@"size"] intValue];
        }

        self.alignment = CPAppBannerAlignmentCenter;
        if ([[json stringForKey:@"alignment"] isEqual:@"right"]) {
            self.alignment = CPAppBannerAlignmentRight;
        } else if ([[json stringForKey:@"alignment"] isEqual:@"right"]) {
            self.alignment = CPAppBannerAlignmentRight;
        }

        self.action = [[CPAppBannerAction alloc] initWithJson:[json objectForKey:@"action"]];

        self.radius = 0;
        if ([json objectForKey:@"radius"]) {
            self.radius = [[json objectForKey:@"radius"] intValue];
        }
    }
    return self;
}

@end
