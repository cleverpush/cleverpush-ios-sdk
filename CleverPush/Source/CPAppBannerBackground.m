#import "CPAppBannerBackground.h"
#import "NSDictionary+SafeExpectations.h"

@implementation CPAppBannerBackground

#pragma mark - wrapping the data of the Background in to CPAppBannerBackground NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.dismiss = YES;
        self.color = @"#FFFFFF";

        if (json) {
            self.imageUrl = [json objectForKey:@"imageUrl"];
            if ([json objectForKey:@"darkImageUrl"] != nil) {
                self.darkImageUrl = [json objectForKey:@"darkImageUrl"];
            }

            if ([json objectForKey:@"color"] != nil) {
                self.color = [json objectForKey:@"color"];
            }
            if ([json cleverPushStringForKey:@"darkColor"] && ![[json cleverPushStringForKey:@"darkColor"] isEqual:@""]) {
                self.darkColor = [json cleverPushStringForKey:@"darkColor"];
            }

            if ([json objectForKey:@"dismiss"] == false) {
                self.dismiss = NO;
            }
        }
    }
    return self;
}

@end
