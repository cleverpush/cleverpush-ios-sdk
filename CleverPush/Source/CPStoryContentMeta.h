#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface CPStoryContentMeta : NSObject

@property (nonatomic, strong) NSString *articleBody;

- (id)initWithJson:(NSDictionary*)json;

@end
NS_ASSUME_NONNULL_END
