#import "CPStoryContentMeta.h"

@implementation CPStoryContentMeta
#pragma mark - wrapping the data of the contentMeta in to CPStoryContentMeta NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        if ([json objectForKey:@"articleBody"] != nil && ![[json objectForKey:@"articleBody"] isKindOfClass:[NSNull class]]) {
            self.articleBody = [json objectForKey:@"articleBody"];
        }
    }
    return self;
}
@end
