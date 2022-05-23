#import "CPAppBannerBlock.h"
#import "CPAppBannerButtonBlock.h"
#import "CPAppBannerTextBlock.h"
#import "CPAppBannerImageBlock.h"
#import "CPAppBannerHTMLBlock.h"
@implementation CPAppBannerBlock

#pragma mark - wrapping the data of the Banner Block in to CPAppBannerBlock NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        if ([[json objectForKey:@"type"] isEqual:@"button"]) {
            self.type = CPAppBannerBlockTypeButton;
        } else if ([[json objectForKey:@"type"] isEqual:@"text"]) {
            self.type = CPAppBannerBlockTypeText;
        } else if ([[json objectForKey:@"type"] isEqual:@"image"]) {
            self.type = CPAppBannerBlockTypeImage;
        } else if ([[json objectForKey:@"type"] isEqual:@"html"]) {
            self.type = CPAppBannerBlockTypeHTML;
        }
    }
    return self;
}

- (CPAppBannerBlock*)create:(NSDictionary*)json {
    CPAppBannerBlock *bannerBlock = [[CPAppBannerBlock alloc] initWithJson:json];
    
    switch (bannerBlock.type) {
        case CPAppBannerBlockTypeButton:
            return [[CPAppBannerButtonBlock alloc] initWithJson:json];
        case CPAppBannerBlockTypeText:
            return [[CPAppBannerTextBlock alloc] initWithJson:json];
        case CPAppBannerBlockTypeImage:
            return [[CPAppBannerImageBlock alloc] initWithJson:json];
        case CPAppBannerBlockTypeHTML:
            return [[CPAppBannerHTMLBlock alloc] initWithJson:json];
            break;
    }
}

@end
