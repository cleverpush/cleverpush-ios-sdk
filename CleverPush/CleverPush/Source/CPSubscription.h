#import <Foundation/Foundation.h>

@interface CPSubscription : NSObject

@property (readonly, nullable) NSString *id;

+ (instancetype _Nonnull)initWithJson:(nonnull NSDictionary*)json;
- (void)parseJson:(nonnull NSDictionary*)json;

@end
