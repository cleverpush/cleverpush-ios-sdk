#import <Foundation/Foundation.h>
@interface CPNotification : NSObject
NS_ASSUME_NONNULL_BEGIN
#pragma mark - Class Variables
@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *tag;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *iconUrl;
@property (nonatomic, strong) NSString *mediaUrl;
@property (nonatomic, strong) NSString *soundFilename;
@property (nonatomic, strong) NSString *appBanner;
@property (nonatomic, strong) NSArray *actions;
@property (nonatomic, strong) NSDictionary *customData;
@property (nonatomic, strong) NSDictionary *carouselItems;
@property (nonatomic, readwrite) BOOL chatNotification;
@property (nonatomic, readwrite) BOOL carouselEnabled;
@property (nonatomic, readwrite) BOOL silent;
@property (nonatomic, strong, nullable) NSDate *createdAt;
@property (nonatomic, strong, nullable) NSDate *expiresAt;
#pragma mark - Class Methods
+ (instancetype)initWithJson:(NSDictionary*)json;
- (void)parseJson:(NSDictionary*)json;
NS_ASSUME_NONNULL_END

@end
