#import "CPAppBannerHTMLBlock.h"

@implementation CPAppBannerHTMLBlock

#pragma mark - wrapping the data of the Banner HTML Block in to CPAppBannerHTMLBlock NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.type = CPAppBannerBlockTypeHTML;
        
        if ([json objectForKey:@"url"]) {
            self.url = [json objectForKey:@"url"];
        }
        
        if ([json objectForKey:@"height"] && [[json objectForKey:@"height"] intValue]) {
            self.height = [[json objectForKey:@"height"] intValue];
        }
        
        self.action = [[CPAppBannerAction alloc] initWithJson:[json objectForKey:@"action"]];
    }
    return self;
}

@end
