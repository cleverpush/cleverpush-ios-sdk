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
        if ([json objectForKey:@"slug"] != nil && ![[json objectForKey:@"slug"] isKindOfClass:[NSNull class]]) {
            self.slug = [json objectForKey:@"slug"];
        }
        if ([json objectForKey:@"code"] != nil && ![[json objectForKey:@"code"] isKindOfClass:[NSNull class]]) {
            self.code = [json objectForKey:@"code"];
        }
        if ([json objectForKey:@"content"] != nil && ![[json objectForKey:@"content"] isKindOfClass:[NSNull class]]) {
            self.content = [[CPStoryContent alloc] initWithJson:[json objectForKey:@"content"]];
        }
        if ([json objectForKey:@"user"] != nil && ![[json objectForKey:@"user"] isKindOfClass:[NSNull class]]) {
            self.user = [json objectForKey:@"user"];
        }
        if ([json objectForKey:@"views"] != nil && ![[json objectForKey:@"views"] isKindOfClass:[NSNull class]]) {
            self.views = [json objectForKey:@"views"];
        }
        if ([json objectForKey:@"completions"] != nil && ![[json objectForKey:@"completions"] isKindOfClass:[NSNull class]]) {
            self.completions = [json objectForKey:@"completions"];
        }
        if ([json objectForKey:@"widgetViews"] != nil && ![[json objectForKey:@"widgetViews"] isKindOfClass:[NSNull class]]) {
            self.widgetViews = [json objectForKey:@"widgetViews"];
        }
        if ([json objectForKey:@"clicks"] != nil && ![[json objectForKey:@"clicks"] isKindOfClass:[NSNull class]]) {
            self.clicks = [json objectForKey:@"clicks"];
        }
        if ([json objectForKey:@"viewsWidget"] != nil && ![[json objectForKey:@"viewsWidget"] isKindOfClass:[NSNull class]]) {
            self.viewsWidget = [json objectForKey:@"viewsWidget"];
        }
        if ([json objectForKey:@"viewsOrganic"] != nil && ![[json objectForKey:@"viewsOrganic"] isKindOfClass:[NSNull class]]) {
            self.viewsOrganic = [json objectForKey:@"viewsOrganic"];
        }
        
        if ([[json objectForKey:@"createdAt"] isKindOfClass:[NSString class]]) {
            self.createdAt = [CPUtils getLocalDateTimeFromUTC:[json objectForKey:@"createdAt"]];
        }
        if ([[json objectForKey:@"validatedAt"] isKindOfClass:[NSString class]]) {
            self.validatedAt = [CPUtils getLocalDateTimeFromUTC:[json objectForKey:@"validatedAt"]];
        }
        
        self.published = NO;
        if ([json objectForKey:@"published"] != nil && ![[json objectForKey:@"published"] isKindOfClass:[NSNull class]] && [[json objectForKey:@"published"] boolValue]) {
            self.published = YES;
        }
        
        self.redirectUrls = [NSMutableArray new];
        if ([json objectForKey:@"redirectUrls"] != nil) {
            for (NSString *redirectJsonUrls in [json objectForKey:@"redirectUrls"]) {
                [self.redirectUrls addObject:redirectJsonUrls];
            }
        }
        
        self.fontFamilies = [NSMutableArray new];
        if ([json objectForKey:@"fontFamilies"] != nil) {
            for (NSString *fontFamiliesJson in [json objectForKey:@"fontFamilies"]) {
                [self.fontFamilies addObject:fontFamiliesJson];
            }
        }
        
        self.keywords = [NSMutableArray new];
        if ([json objectForKey:@"keywords"] != nil) {
            for (NSString *keywordsJson in [json objectForKey:@"keywords"]) {
                [self.keywords addObject:keywordsJson];
            }
        }
        
        self.valid = NO;
        if ([json objectForKey:@"valid"] != nil && ![[json objectForKey:@"valid"] isKindOfClass:[NSNull class]] && [[json objectForKey:@"valid"] boolValue]) {
            self.valid = YES;
        }
    }
    return self;
}

@end
