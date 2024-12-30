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

@interface CPStoriesController : UIViewController<UIGestureRecognizerDelegate,SFSafariViewControllerDelegate, WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) NSMutableArray<CPStory*> *stories;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *storyStatusMap;
@property (nonatomic, assign) NSInteger storyIndex;
@property (nonatomic, assign) CGFloat buttonWidth;
@property (nonatomic, assign) CGFloat buttonHeight;
@property (nonatomic, assign) CGFloat buttonXPosition;
@property (nonatomic, assign) CGFloat topPadding;
@property (nonatomic, strong) IBOutlet UIButton *closeButton;
@property (nonatomic, strong) NSMutableArray *readStories;
@property (nonatomic, assign) BOOL storyWidgetShareButtonVisibility;
@property (nonatomic, assign) BOOL sortToLastIndex;
@property (nonatomic, assign) BOOL allowAutoRotation;
@property (nonatomic, assign) id delegate;
@property (atomic, strong) CPStoryViewOpenedBlock openedCallback;
@property (atomic, strong) CPStoryViewFinishedBlock finishedCallback;
@property (nonatomic) CPStoryWidgetCloseButtonPosition closeButtonPosition;
@property (nonatomic, strong) CPStoryWidget *widget;
@property (nonatomic, assign) UIWindow* window;
@property (nonatomic, strong) CPWKWebView *webview;
@property (nonatomic, copy) void (^contentLoadedCompletion)(void);

- (void)loadContentWithCompletion:(void (^)(void))completion;

@end
NS_ASSUME_NONNULL_END
