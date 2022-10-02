#import "CPWidgetsStories.h"

@implementation CPWidgetsStories
#pragma mark - wrapping the data of the Background in to CPWidgetsStories NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.stories = [NSMutableArray new];
        if ([json objectForKey:@"stories"] != nil && ![[json objectForKey:@"stories"] isKindOfClass:[NSNull class]]) {
            for (NSDictionary *storiesJson in [json objectForKey:@"stories"]) {
                [self.stories addObject:[[CPStory alloc] initWithJson:storiesJson]];
            }
        }
        if ([json objectForKey:@"widget"] != nil && ![[json objectForKey:@"widget"] isKindOfClass:[NSNull class]]) {
            self.widgets = [[CPStoryWidget alloc] initWithJson:[json objectForKey:@"widget"]];
        }
    }
    return self;
}
@end
