#import <Foundation/Foundation.h>

@interface CPAppBannerAction : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *urlType;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *type;
@property (nonatomic) BOOL dismiss;

- (id)initWithJson:(NSDictionary*)json;

@end
