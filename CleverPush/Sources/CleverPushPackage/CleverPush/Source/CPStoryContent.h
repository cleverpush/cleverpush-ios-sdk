#import <Foundation/Foundation.h>
#import "CPStoryContentPreview.h"
#import "CPStoryContentMeta.h"

NS_ASSUME_NONNULL_BEGIN
@interface CPStoryContent : NSObject

@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *canonicalUrl;
@property (nonatomic, strong) NSString *slug;
@property (nonatomic, strong) NSString *pages;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) CPStoryContentPreview *preview;
@property (nonatomic, strong) CPStoryContentMeta *meta;
@property (nonatomic, readwrite) BOOL supportsLandscape;
@property (nonatomic, readwrite) BOOL published;

- (id)initWithJson:(NSDictionary*)json;

@end
NS_ASSUME_NONNULL_END
