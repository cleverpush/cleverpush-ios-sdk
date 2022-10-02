#import <Foundation/Foundation.h>
#import "CPUtils.h"

@interface CPChannelTopic : NSObject

#pragma mark - Class Variables
@property (readonly, nullable) NSString *id;
@property (readonly, nullable) NSString *parentTopic;
@property (readonly, nullable) NSString *name;
@property (readonly, nullable) NSString *fcmBroadcastTopic;
@property (readonly, nullable) NSString *externalId;
@property (readonly, nullable) NSNumber *sort;
@property (readonly, nullable) NSDictionary *customData;
@property (readonly, nullable) NSDate *createdAt;
@property (nonatomic, readwrite) BOOL defaultUnchecked;

#pragma mark - Class Methods
+ (instancetype _Nonnull)initWithJson:(nonnull NSDictionary*)json;
- (void)parseJson:(nonnull NSDictionary*)json;

@end
