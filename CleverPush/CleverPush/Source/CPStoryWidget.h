#import <Foundation/Foundation.h>
#import "CPStory.h"
#import "CPWidgetVariant.h"
#import "CPWidgetPosition.h"
#import "CPWidgetDisplay.h"

NS_ASSUME_NONNULL_BEGIN
@interface CPStoryWidget : NSObject

@property (nonatomic) CPWidgetVariant variant;
@property (nonatomic) CPWidgetPosition position;
@property (nonatomic) CPWidgetDisplay display;
@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *channel;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *maxStoriesNumber;
@property (nonatomic, strong) NSString *storyHeight;
@property (nonatomic, strong) NSString *margin;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSMutableArray<CPStory*> *selectedStories;

- (id)initWithJson:(NSDictionary*)json;

@end
NS_ASSUME_NONNULL_END
