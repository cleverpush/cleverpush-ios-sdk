#import "CPStoryWidget.h"
#import "CPUtils.h"
NS_ASSUME_NONNULL_BEGIN
@implementation CPStoryWidget
#pragma mark - wrapping the data of the Widget in to CPWidget NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        
        if ([json objectForKey:@"_id"] != nil && ![[json objectForKey:@"_id"] isKindOfClass:[NSNull class]]) {
            self.id = [json objectForKey:@"_id"];
        }
        if ([json objectForKey:@"channel"] != nil && ![[json objectForKey:@"channel"] isKindOfClass:[NSNull class]]) {
            self.channel = [json objectForKey:@"channel"];
        }
        if ([json objectForKey:@"name"] != nil && ![[json objectForKey:@"name"] isKindOfClass:[NSNull class]]) {
            self.name = [json objectForKey:@"name"];
        }
        if ([json objectForKey:@"maxStoriesNumber"] != nil && ![[json objectForKey:@"maxStoriesNumber"] isKindOfClass:[NSNull class]]) {
            self.maxStoriesNumber = [json objectForKey:@"maxStoriesNumber"];
        }
        if ([json objectForKey:@"storyHeight"] != nil && ![[json objectForKey:@"storyHeight"] isKindOfClass:[NSNull class]]) {
            self.storyHeight = [json objectForKey:@"storyHeight"];
        }
        if ([json objectForKey:@"margin"] != nil && ![[json objectForKey:@"margin"] isKindOfClass:[NSNull class]]) {
            self.margin = [json objectForKey:@"margin"];
        }
                
        if ([[json objectForKey:@"createdAt"] isKindOfClass:[NSString class]]) {
            self.createdAt = [CPUtils getLocalDateTimeFromUTC:[json objectForKey:@"createdAt"]];
        }
        
        if ([[json objectForKey:@"variant"] isEqual:@"bubbles"]) {
            self.variant = CPWidgetVariantBubbles;
        } else if ([[json objectForKey:@"variant"] isEqual:@"cards"]) {
            self.variant = CPWidgetVariantCards;
        } else {
            self.variant = CPWidgetVariantInline;
        }
        
        if ([[json objectForKey:@"position"] isEqual:@"inline"]) {
            self.position = CPWidgetPositionInline;
        } else if ([[json objectForKey:@"position"] isEqual:@"sticky"]) {
            self.position = CPWidgetPositionSticky;
        } else if ([[json objectForKey:@"position"] isEqual:@"fixedtop"]) {
            self.position = CPWidgetPositionFixedTop;
        } else {
            self.position = CPWidgetPositionFixedBottom;
        }
        
        if ([[json objectForKey:@"display"] isEqual:@"all"]) {
            self.display = CPWidgetDisplayAll;
        } else if ([[json objectForKey:@"display"] isEqual:@"desktop"]) {
            self.display = CPWidgetDisplayDesktop;
        } else {
            self.display = CPWidgetDisplayMobile;
        }
        
        self.selectedStories = [NSMutableArray new];
        if ([json objectForKey:@"selectedStories"] != nil) {
            for (NSDictionary *story in [json objectForKey:@"selectedStories"]) {
                [self.selectedStories addObject:[[CPStory alloc] initWithJson:story]];
            }
        }
    }
    return self;
}
@end
NS_ASSUME_NONNULL_END
