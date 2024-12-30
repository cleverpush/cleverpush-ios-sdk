#import "CPStory.h"
#import "CPUtils.h"

@implementation CPStory

#pragma mark - Initialise stories by NSDictionary
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        if ([json objectForKey:@"_id"] != nil && ![[json objectForKey:@"_id"] isKindOfClass:[NSNull class]]) {
            self.id = [json objectForKey:@"_id"];
        }
        if ([json objectForKey:@"channel"] != nil && ![[json objectForKey:@"channel"] isKindOfClass:[NSNull class]]) {
            self.channel = [json objectForKey:@"channel"];
        }
        if ([json objectForKey:@"title"] != nil && ![[json objectForKey:@"title"] isKindOfClass:[NSNull class]]) {
            self.title = [json objectForKey:@"title"];
        }
        if ([json objectForKey:@"content"] != nil && ![[json objectForKey:@"content"] isKindOfClass:[NSNull class]]) {
            self.content = [[CPStoryContent alloc] initWithJson:[json objectForKey:@"content"]];
        }
    }
    return self;
}

@end
