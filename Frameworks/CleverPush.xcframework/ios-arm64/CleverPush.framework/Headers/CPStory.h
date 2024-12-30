#import <Foundation/Foundation.h>
#import "CPStoryContent.h"

NS_ASSUME_NONNULL_BEGIN
@interface CPStory : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *channel;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, readwrite) BOOL opened;
@property (nonatomic, strong) CPStoryContent *content;
@property (nonatomic) NSInteger subStoryCount;
@property (nonatomic) NSInteger unreadCount;

- (id)initWithJson:(NSDictionary*)json;

@end
NS_ASSUME_NONNULL_END
