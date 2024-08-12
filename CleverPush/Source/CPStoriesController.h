#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "CPWidgetsStories.h"
#import "CPiCarousel.h"
#import "CPUtils.h"
#import "CPWKWebView.h"

NS_ASSUME_NONNULL_BEGIN
@protocol refreshReadStories <NSObject>
- (void)reloadReadStories:(NSArray *)array;
@end

@interface CPStoriesController : UIViewController<UIGestureRecognizerDelegate, iCarouselDataSource, iCarouselDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) NSMutableArray<CPStory*> *stories;
@property (nonatomic, assign) NSInteger storyIndex;
@property (nonatomic, strong) IBOutlet CleverPushiCarousel *carousel;
@property (nonatomic, strong) NSMutableArray *readStories;
@property (nonatomic, assign) BOOL storyWidgetShareButtonVisibility;
@property (nonatomic, assign) id delegate;
@property (atomic, strong) CPStoryViewOpenedBlock openedCallback;
@property (nonatomic) CPStoryWidgetCloseButtonPosition closeButtonPosition;

@end
NS_ASSUME_NONNULL_END
