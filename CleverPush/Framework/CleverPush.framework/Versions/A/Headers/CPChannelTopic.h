#import <Foundation/Foundation.h>

@interface CPChannelTopic : NSObject

@property (readonly, nullable) NSString *id;

@property (readonly, nullable) NSString *parentTopic;
@property (readonly, nullable) NSString *name;
@property (readonly, nullable) NSNumber *sort;
@property (readonly) BOOL defaultUnchecked;

@property (readonly, nullable) NSString *fcmBroadcastTopic;
@property (readonly, nullable) NSString *externalId;

@property (readonly, nullable) NSDictionary *customData;

@property (readonly, nullable) NSDate *createdAt;

+ (instancetype _Nonnull)initWithJson:(nonnull NSDictionary*)json;
- (void)parseJson:(nonnull NSDictionary*)json;

@end
