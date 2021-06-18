#import "CPStoryContentPreview.h"

@implementation CPStoryContentPreview
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        
        if ([json objectForKey:@"publisher"] != nil && ![[json objectForKey:@"publisher"] isKindOfClass:[NSNull class]]) {
            self.publisher = [json objectForKey:@"publisher"];
        }
        if ([json objectForKey:@"publisherLogoSrc"] != nil && ![[json objectForKey:@"publisherLogoSrc"] isKindOfClass:[NSNull class]]) {
            self.publisherLogoSrc = [json objectForKey:@"publisherLogoSrc"];
        }
        if ([json objectForKey:@"posterPortraitSrc"] != nil && ![[json objectForKey:@"posterPortraitSrc"] isKindOfClass:[NSNull class]]) {
            self.posterPortraitSrc = [json objectForKey:@"posterPortraitSrc"];
        }
        if ([json objectForKey:@"publisherLogoWidth"] != nil && ![[json objectForKey:@"publisherLogoWidth"] isKindOfClass:[NSNull class]]) {
            self.publisherLogoWidth = [json objectForKey:@"publisherLogoWidth"];
        }
        if ([json objectForKey:@"publisherLogoHeight"] != nil && ![[json objectForKey:@"publisherLogoHeight"] isKindOfClass:[NSNull class]]) {
            self.publisherLogoHeight = [json objectForKey:@"publisherLogoHeight"];
        }
        if ([json objectForKey:@"posterLandscapeSrc"] != nil && ![[json objectForKey:@"posterLandscapeSrc"] isKindOfClass:[NSNull class]]) {
            self.posterLandscapeSrc = [json objectForKey:@"posterLandscapeSrc"];
        }
        if ([json objectForKey:@"posterSquareSrc"] != nil && ![[json objectForKey:@"posterSquareSrc"] isKindOfClass:[NSNull class]]) {
            self.posterSquareSrc = [json objectForKey:@"posterSquareSrc"];
        }
    }
    return self;
}
@end
