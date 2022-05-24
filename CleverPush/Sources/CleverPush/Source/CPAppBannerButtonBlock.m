#import "CPAppBannerButtonBlock.h"

@implementation CPAppBannerButtonBlock
#pragma mark - wrapping the data of the Banner Button Block in to CPAppBannerButtonBlock NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.type = CPAppBannerBlockTypeButton;
        
        self.text = @"";
        if ([json objectForKey:@"text"]) {
            self.text = [json objectForKey:@"text"];
        }
        
        if ([json objectForKey:@"color"] && ![[json objectForKey:@"color"] isEqual:@""]) {
            self.color = [json objectForKey:@"color"];
        } else {
            self.color = @"#000000";
        }
        
        if ([json objectForKey:@"family"]&& ![[json objectForKey:@"family"] isEqual:@""]) {
            self.family = [json objectForKey:@"family"];
        }
        
        if ([json objectForKey:@"background"] && ![[json objectForKey:@"background"] isEqual:@""]) {
            self.background = [json objectForKey:@"background"];
        } else {
            self.background = @"#FFFFFF";
        }
        
        self.size = 18;
        if ([json objectForKey:@"size"]) {
            self.size = [[json objectForKey:@"size"] intValue];
        }
        
        self.alignment = CPAppBannerAlignmentCenter;
        if ([[json objectForKey:@"alignment"] isEqual:@"right"]) {
            self.alignment = CPAppBannerAlignmentRight;
        } else if ([[json objectForKey:@"alignment"] isEqual:@"right"]) {
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
