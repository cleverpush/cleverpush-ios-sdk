#import <Foundation/Foundation.h>

@interface CPSubscription : NSObject

#pragma mark - Class Variables
@property (readonly, nullable) NSString *id;

#pragma mark - Class Methods
+ (instancetype _Nonnull)initWithJson:(nonnull NSDictionary*)json;
- (void)parseJson:(nonnull NSDictionary*)json;

@end
