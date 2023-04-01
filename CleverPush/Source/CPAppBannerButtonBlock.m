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
        if ([json stringForKey:@"darkColor"] && ![[json stringForKey:@"darkColor"] isEqual:@""]) {
            self.darkColor = [json stringForKey:@"darkColor"];
        }

        if ([json stringForKey:@"family"] && ![[json stringForKey:@"family"] isEqual:@""]) {
            self.family = [json stringForKey:@"family"];
        }

        if ([json stringForKey:@"background"] && ![[json stringForKey:@"background"] isEqual:@""]) {
            self.background = [json stringForKey:@"background"];
        } else {
            self.background = @"#FFFFFF";
        }
        if ([json stringForKey:@"darkBackground"] && ![[json stringForKey:@"darkBackground"] isEqual:@""]) {
            self.darkBackground = [json stringForKey:@"darkBackground"];
        }

        self.size = 18;
        if ([json objectForKey:@"size"]) {
            self.size = [[json objectForKey:@"size"] intValue];
        }

        self.alignment = CPAppBannerAlignmentCenter;
        if ([[json stringForKey:@"alignment"] isEqual:@"right"]) {
            self.alignment = CPAppBannerAlignmentRight;
        } else if ([[json stringForKey:@"alignment"] isEqual:@"left"]) {
            self.alignment = CPAppBannerAlignmentLeft;
        }

        self.radius = 0;
        if ([json objectForKey:@"radius"]) {
            self.radius = [[json objectForKey:@"radius"] intValue];
        }
        
        self.id = @"";
        if ([json objectForKey:@"id"]) {
            self.id = [json objectForKey:@"id"];
        }
        
        NSMutableDictionary *buttonBlockDic = [[NSMutableDictionary alloc] init];
        buttonBlockDic = [[json objectForKey:@"action"] mutableCopy];
        buttonBlockDic[@"blockId"] = self.id;
        self.action = [[CPAppBannerAction alloc] initWithJson:buttonBlockDic];
    }
    return self;
}

@end
