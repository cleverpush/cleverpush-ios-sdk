#import "CPAppBannerTextBlock.h"
#import "NSDictionary+SafeExpectations.h"

@implementation CPAppBannerTextBlock

#pragma mark - wrapping the data of the banner text block in to CPAppBannerTextBlock NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.type = CPAppBannerBlockTypeText;

        self.text = @"";
        if ([json stringForKey:@"text"]) {
            self.text = [json stringForKey:@"text"];
        }

        self.color = @"#000000";
        if ([json stringForKey:@"color"] && ![[json stringForKey:@"family"] isEqual:@""]) {
            self.color = [json stringForKey:@"color"];
        }
        if ([json stringForKey:@"darkColor"] && ![[json stringForKey:@"darkColor"] isEqual:@""]) {
            self.darkColor = [json stringForKey:@"darkColor"];
        }

        if ([json stringForKey:@"family"] && ![[json stringForKey:@"family"] isEqual:@""]) {
            self.family = [json stringForKey:@"family"];
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
    }
    return self;
}

@end
