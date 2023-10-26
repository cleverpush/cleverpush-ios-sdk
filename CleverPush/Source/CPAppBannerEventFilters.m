#import "CPAppBannerEventFilters.h"

@implementation CPAppBannerEventFilters

#pragma mark - wrapping the data of the event filters in to CPAppBannerEventFilters NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        
        self.event = @"";
        if ([json objectForKey:@"event"] && [[json objectForKey:@"event"] isKindOfClass:[NSString class]]) {
            self.event = [json objectForKey:@"event"];
        }

        self.property = @"";
        if ([json objectForKey:@"property"] && [[json objectForKey:@"property"] isKindOfClass:[NSString class]]) {
            self.property = [json objectForKey:@"property"];
        }

        self.value = @"";
        if ([json objectForKey:@"value"] && [[json objectForKey:@"value"] isKindOfClass:[NSString class]]) {
            self.value = [json objectForKey:@"value"];
        }

        self.relation = @"";
        if ([json objectForKey:@"relation"] && [[json objectForKey:@"relation"] isKindOfClass:[NSString class]]) {
            self.relation = [json objectForKey:@"relation"];
        }

        self.fromValue = @"";
        if ([json objectForKey:@"fromValue"] && [[json objectForKey:@"fromValue"] isKindOfClass:[NSString class]]) {
            self.fromValue = [json objectForKey:@"fromValue"];
        }

        self.toValue = @"";
        if ([json objectForKey:@"toValue"] && [[json objectForKey:@"toValue"] isKindOfClass:[NSString class]]) {
            self.toValue = [json objectForKey:@"toValue"];
        }

        self.banner = @"";
        if ([json objectForKey:@"banner"] && [[json objectForKey:@"banner"] isKindOfClass:[NSString class]]) {
            self.banner = [json objectForKey:@"banner"];
        }

        self.count = @"";
        if ([json objectForKey:@"count"] && [[json objectForKey:@"count"] isKindOfClass:[NSString class]]) {
            self.count =  [json objectForKey:@"count"];
        }

        self.createdAt = @"";
        if ([json objectForKey:@"createdAt"] && [[json objectForKey:@"createdAt"] isKindOfClass:[NSString class]]) {
            self.createdAt = [json objectForKey:@"createdAt"];
        }

        self.event = @"";
        if ([json objectForKey:@"event"] && [[json objectForKey:@"event"] isKindOfClass:[NSString class]]) {
            self.event = [json objectForKey:@"event"];
        }

        self.updatedAt = @"";
        if ([json objectForKey:@"updatedAt"] && [[json objectForKey:@"updatedAt"] isKindOfClass:[NSString class]]) {
            self.updatedAt = [json objectForKey:@"updatedAt"];
        }

    }
    return self;
}

@end
