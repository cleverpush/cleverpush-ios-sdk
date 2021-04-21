#import <Foundation/Foundation.h>

@interface CPNotification : NSObject

@property (readonly, nullable) NSString *id;

@property (readonly, nullable) NSString *tag;
@property (readonly, nullable) NSString *title;
@property (readonly, nullable) NSString *text;
@property (readonly, nullable) NSString *url;

@property (readonly, nullable) NSString *iconUrl;
@property (readonly, nullable) NSString *mediaUrl;

@property (readonly, nullable) NSString *soundFilename;

@property (readonly, nullable) NSArray *actions;

@property (readonly, nullable) NSDictionary *customData;

@property (readonly) BOOL chatNotification;

@property (readonly) BOOL carouselEnabled;
@property (readonly, nullable) NSDictionary *carouselItems;

@property (readonly, nullable) NSDate *createdAt;
@property (readonly, nullable) NSDate *expiresAt;

+ (instancetype _Nonnull)initWithJson:(nonnull NSDictionary*)json;
- (void)parseJson:(nonnull NSDictionary*)json;

@end

