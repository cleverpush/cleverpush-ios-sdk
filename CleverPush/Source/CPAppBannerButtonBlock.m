#import "CPAppBannerButtonBlock.h"
#import "NSDictionary+SafeExpectations.h"

@implementation CPAppBannerButtonBlock
#pragma mark - wrapping the data of the Banner Button Block in to CPAppBannerButtonBlock NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.type = CPAppBannerBlockTypeButton;
        self.isButtonClicked = NO;
        self.actions = [[NSMutableArray alloc] init];

        self.text = @"";
        if ([json cleverPushStringForKey:@"text"]) {
            self.text = [json cleverPushStringForKey:@"text"];
        }

        if ([json cleverPushStringForKey:@"color"] && ![[json cleverPushStringForKey:@"color"] isEqual:@""]) {
            self.color = [json cleverPushStringForKey:@"color"];
        } else {
            self.color = @"#000000";
        }
        if ([json cleverPushStringForKey:@"darkColor"] && ![[json cleverPushStringForKey:@"darkColor"] isEqual:@""]) {
            self.darkColor = [json cleverPushStringForKey:@"darkColor"];
        }

        if ([json cleverPushStringForKey:@"family"] && ![[json cleverPushStringForKey:@"family"] isEqual:@""]) {
            self.family = [json cleverPushStringForKey:@"family"];
        }

        if ([json cleverPushStringForKey:@"background"] && ![[json cleverPushStringForKey:@"background"] isEqual:@""]) {
            self.background = [json cleverPushStringForKey:@"background"];
        } else {
            self.background = @"#FFFFFF";
        }
        if ([json cleverPushStringForKey:@"darkBackground"] && ![[json cleverPushStringForKey:@"darkBackground"] isEqual:@""]) {
            self.darkBackground = [json cleverPushStringForKey:@"darkBackground"];
        }

        self.size = 18;
        if ([json objectForKey:@"size"]) {
            self.size = [[json objectForKey:@"size"] intValue];
        }

        self.alignment = CPAppBannerAlignmentCenter;
        if ([[json cleverPushStringForKey:@"alignment"] isEqual:@"right"]) {
            self.alignment = CPAppBannerAlignmentRight;
        } else if ([[json cleverPushStringForKey:@"alignment"] isEqual:@"left"]) {
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

        if ([json cleverPushArrayForKey:@"actions"] &&
            [json cleverPushArrayForKey:@"actions"] != nil &&
            ![[json cleverPushArrayForKey:@"actions"] isKindOfClass:[NSNull class]] &&
            [[json cleverPushArrayForKey:@"actions"] isKindOfClass:[NSArray class]] &&
            [json cleverPushArrayForKey:@"actions"].count > 0) {

            for (NSDictionary *actionsDic in [json cleverPushArrayForKey:@"actions"]) {
                CPAppBannerAction* actionBlock;
                actionBlock = [[CPAppBannerAction alloc] initWithJson:actionsDic];
                [self.actions addObject:actionBlock];
            }
        }
    }
    return self;
}

@end
