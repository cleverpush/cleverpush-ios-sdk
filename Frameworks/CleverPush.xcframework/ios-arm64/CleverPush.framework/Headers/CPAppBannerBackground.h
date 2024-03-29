#import <Foundation/Foundation.h>

@interface CPAppBannerBackground : NSObject

@property (nonatomic, strong) NSString *imageUrl;
@property (nonatomic, strong) NSString *darkImageUrl;
@property (nonatomic, strong) NSString *color;
@property (nonatomic, strong) NSString *darkColor;
@property (nonatomic) BOOL dismiss;

- (id)initWithJson:(NSDictionary*)json;

@end
