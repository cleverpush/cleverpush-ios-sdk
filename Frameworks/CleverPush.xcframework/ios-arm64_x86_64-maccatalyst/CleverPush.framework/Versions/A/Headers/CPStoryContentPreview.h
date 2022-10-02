#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface CPStoryContentPreview : NSObject

@property (nonatomic, strong) NSString *publisher;
@property (nonatomic, strong) NSString *publisherLogoSrc;
@property (nonatomic, strong) NSString *posterPortraitSrc;
@property (nonatomic, strong) NSString *publisherLogoWidth;
@property (nonatomic, strong) NSString *publisherLogoHeight;
@property (nonatomic, strong) NSString *posterLandscapeSrc;
@property (nonatomic, strong) NSString *posterSquareSrc;

- (id)initWithJson:(NSDictionary*)json;

@end
NS_ASSUME_NONNULL_END
