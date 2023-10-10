#import "CPAppBannerCarouselBlock.h"
#import "CPAppBannerDismissType.h"
#import "CPAppBannerFrequency.h"
#import "CPAppBannerStatus.h"
#import "CPAppBannerStopAtType.h"
#import "CPAppBannerType.h"
#import "CPAppBannerBackground.h"
#import "CPAppBannerTextBlock.h"
#import "CPAppBannerButtonBlock.h"
#import "CPAppBannerImageBlock.h"
#import "CPAppBannerTrigger.h"
#import "CPAppBannerTriggerType.h"
#import "CPAppBannerHTMLBlock.h"
#import "CPUtils.h"

@implementation CPAppBannerCarouselBlock

#pragma mark - wrapping the data of the banner in to CPAppBanner NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.id = [json objectForKey:@"id"];

        self.blocks = [NSMutableArray new];
        self.content = [json objectForKey:@"content"];
        self.isScreenClicked = NO;
        self.isScreenAlreadyShown = NO;

        if ([json objectForKey:@"blocks"] != nil) {
            for (NSDictionary *blockJson in [json objectForKey:@"blocks"]) {
                CPAppBannerBlock* block;
                if ([[blockJson objectForKey:@"type"] isEqual:@"button"]) {
                    block = [[CPAppBannerButtonBlock alloc] initWithJson:blockJson];
                } else if ([[blockJson objectForKey:@"type"] isEqual:@"text"]) {
                    block = [[CPAppBannerTextBlock alloc] initWithJson:blockJson];
                } else if ([[blockJson objectForKey:@"type"] isEqual:@"image"]) {
                    block = [[CPAppBannerImageBlock alloc] initWithJson:blockJson];
                } else if ([[blockJson objectForKey:@"type"] isEqual:@"html"]) {
                    block = [[CPAppBannerHTMLBlock alloc] initWithJson:blockJson];
                } else {
                    continue;
                }
                [self.blocks addObject:block];
            }
        }
    }
    return self;
}

@end
