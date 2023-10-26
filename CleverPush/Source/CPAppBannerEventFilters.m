#import "CPAppBannerEventFilters.h"

@implementation CPAppBannerEventFilters

#pragma mark - wrapping the data of the banner in to CPAppBanner NSObject
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

        self.createdDateTime = @"";
        if ([json objectForKey:@"createdDateTime"] && [[json objectForKey:@"createdDateTime"] isKindOfClass:[NSString class]]) {
            self.createdDateTime = [json objectForKey:@"createdDateTime"];
        }

        self.event = @"";
        if ([json objectForKey:@"event"] && [[json objectForKey:@"event"] isKindOfClass:[NSString class]]) {
            self.event = [json objectForKey:@"event"];
        }

        self.updatedDateTime = @"";
        if ([json objectForKey:@"updatedDateTime"] && [[json objectForKey:@"updatedDateTime"] isKindOfClass:[NSString class]]) {
            self.updatedDateTime = [json objectForKey:@"updatedDateTime"];
        }

    }
    return self;
}

@end
