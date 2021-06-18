#import <Foundation/Foundation.h>
#import "CPWidget.h"
#import "CPStory.h"

NS_ASSUME_NONNULL_BEGIN
@interface CPWidgetsStories : NSObject

@property (nonatomic, strong) CPWidget *widgets;
@property (nonatomic, strong) NSMutableArray<CPStory*> *stories;

- (id)initWithJson:(NSDictionary*)json;

@end
NS_ASSUME_NONNULL_END
