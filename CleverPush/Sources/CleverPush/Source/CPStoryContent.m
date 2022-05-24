#import "CPStoryContent.h"

@implementation CPStoryContent
#pragma mark - wrapping the data of the Story Content in to CPStoryContent NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        if ([json objectForKey:@"version"] != nil && ![[json objectForKey:@"version"] isKindOfClass:[NSNull class]]) {
            self.version = [json objectForKey:@"version"];
        }
        if ([json objectForKey:@"title"] != nil && ![[json objectForKey:@"title"] isKindOfClass:[NSNull class]]) {
            self.title = [json objectForKey:@"title"];
        }
        if ([json objectForKey:@"canonicalUrl"] != nil && ![[json objectForKey:@"canonicalUrl"] isKindOfClass:[NSNull class]]) {
            self.canonicalUrl = [json objectForKey:@"canonicalUrl"];
        }
        if ([json objectForKey:@"slug"] != nil && ![[json objectForKey:@"slug"] isKindOfClass:[NSNull class]]) {
            self.slug = [json objectForKey:@"slug"];
        }
        if ([json objectForKey:@"subtitle"] != nil && ![[json objectForKey:@"subtitle"] isKindOfClass:[NSNull class]]) {
            self.subtitle = [json objectForKey:@"subtitle"];
        }
        if ([json objectForKey:@"preview"] != nil && ![[json objectForKey:@"preview"] isKindOfClass:[NSNull class]]) {
            self.preview = [[CPStoryContentPreview alloc] initWithJson:[json objectForKey:@"preview"]];
        }
        if ([json objectForKey:@"meta"] != nil && ![[json objectForKey:@"meta"] isKindOfClass:[NSNull class]]) {
            self.meta = [[CPStoryContentMeta alloc] initWithJson:[json objectForKey:@"meta"]];
        }
        self.supportsLandscape = NO;
        if ([json objectForKey:@"supportsLandscape"] != nil && ![[json objectForKey:@"supportsLandscape"] isKindOfClass:[NSNull class]] && [[json objectForKey:@"supportsLandscape"] boolValue]) {
            self.supportsLandscape = YES;
        }
        
        self.published = NO;
        if ([json objectForKey:@"published"] != nil && ![[json objectForKey:@"published"] isKindOfClass:[NSNull class]] && [[json objectForKey:@"published"] boolValue]) {
            self.published = YES;
        }
    }
    return self;
}
@end
