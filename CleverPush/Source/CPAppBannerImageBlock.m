#import "CPAppBannerImageBlock.h"
#import "NSDictionary+SafeExpectations.h"

@implementation CPAppBannerImageBlock

#pragma mark - wrapping the data of the Banner Image Block in to CPAppBannerImageBlock NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.type = CPAppBannerBlockTypeImage;
        self.isimageClicked = NO;
        self.actions = [[NSMutableArray alloc] init];

        if ([json cleverPushStringForKey:@"imageUrl"]) {
            self.imageUrl = [json cleverPushStringForKey:@"imageUrl"];
        }
        if ([json cleverPushStringForKey:@"darkImageUrl"] && ![[json cleverPushStringForKey:@"darkImageUrl"] isEqual:@""]) {
            self.darkImageUrl = [json cleverPushStringForKey:@"darkImageUrl"];
        }

        self.scale = 100;
        if ([json objectForKey:@"scale"] && [[json objectForKey:@"scale"] intValue]) {
            self.scale = [[json objectForKey:@"scale"] intValue];
        }
        
        self.id = @"";
        if ([json objectForKey:@"id"]) {
            self.id = [json objectForKey:@"id"];
        }

        self.imageWidth = 100;
        if ([json objectForKey:@"imageWidth"] && [[json objectForKey:@"imageWidth"] intValue]) {
            self.imageWidth = [[json objectForKey:@"imageWidth"] intValue];
        }

        self.imageHeight = 100;
        if ([json objectForKey:@"imageHeight"] && [[json objectForKey:@"imageHeight"] intValue]) {
            self.imageHeight = [[json objectForKey:@"imageHeight"] intValue];
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
