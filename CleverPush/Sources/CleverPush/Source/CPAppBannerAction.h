#import <Foundation/Foundation.h>

@interface CPAppBannerAction : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *urlType;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSArray *topics;
@property (nonatomic, strong) NSString *attributeId;
@property (nonatomic, strong) NSString *attributeValue;
@property (nonatomic) BOOL dismiss;
@property (nonatomic) BOOL openInWebview;

- (id)initWithJson:(NSDictionary*)json;

@end
