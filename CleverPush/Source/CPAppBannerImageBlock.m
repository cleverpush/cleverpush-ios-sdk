#import "CPAppBannerImageBlock.h"
#import "NSDictionary+SafeExpectations.h"

@implementation CPAppBannerImageBlock

#pragma mark - wrapping the data of the Banner Image Block in to CPAppBannerImageBlock NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.type = CPAppBannerBlockTypeImage;

        if ([json stringForKey:@"imageUrl"]) {
            self.imageUrl = [json stringForKey:@"imageUrl"];
        }
        if ([json stringForKey:@"darkImageUrl"] && ![[json stringForKey:@"darkImageUrl"] isEqual:@""]) {
            self.darkImageUrl = [json stringForKey:@"darkImageUrl"];
        }

        self.scale = 100;
        if ([json objectForKey:@"scale"] && [[json objectForKey:@"scale"] intValue]) {
            self.scale = [[json objectForKey:@"scale"] intValue];
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
