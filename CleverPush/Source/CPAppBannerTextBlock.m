#import "CPAppBannerTextBlock.h"
#import "NSDictionary+SafeExpectations.h"

@implementation CPAppBannerTextBlock

#pragma mark - wrapping the data of the banner text block in to CPAppBannerTextBlock NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.type = CPAppBannerBlockTypeText;

        self.text = @"";
        if ([json cleverPushStringForKey:@"text"]) {
            self.text = [json cleverPushStringForKey:@"text"];
        }

        self.html = @"";
        if ([json cleverPushStringForKey:@"html"] && ![[json cleverPushStringForKey:@"html"] isEqual:@""]) {
            self.html = [json cleverPushStringForKey:@"html"];
        }

        self.color = @"#000000";
        if ([json cleverPushStringForKey:@"color"] && ![[json cleverPushStringForKey:@"color"] isEqual:@""]) {
            self.color = [json cleverPushStringForKey:@"color"];
        }
        if ([json cleverPushStringForKey:@"darkColor"] && ![[json cleverPushStringForKey:@"darkColor"] isEqual:@""]) {
            self.darkColor = [json cleverPushStringForKey:@"darkColor"];
        }

        if ([json cleverPushStringForKey:@"family"] && ![[json cleverPushStringForKey:@"family"] isEqual:@""]) {
            self.family = [json cleverPushStringForKey:@"family"];
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
    }
    return self;
}

@end
