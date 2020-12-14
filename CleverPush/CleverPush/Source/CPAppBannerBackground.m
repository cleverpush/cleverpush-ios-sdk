#import "CPAppBannerBackground.h"

@implementation CPAppBannerBackground

- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.dismiss = YES;
        self.color = @"#FFFFFF";
        
        if (json) {
            self.imageUrl = [json objectForKey:@"imageUrl"];
            if ([json objectForKey:@"color"] != nil) {
                self.color = [json objectForKey:@"color"];
            }
            if ([json objectForKey:@"dismiss"] == false) {
                self.dismiss = NO;
            }
        }
    }
    return self;
}

@end
