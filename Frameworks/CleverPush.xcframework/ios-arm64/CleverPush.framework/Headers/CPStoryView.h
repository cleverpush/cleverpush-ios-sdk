#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "CPStoryWidget.h"
#import "CPStory.h"
#import "UIImageView+CleverPush.h"
#import "CPStoryWidgetCloseButtonPosition.h"
#import "CPStoryWidgetTextPosition.h"

@interface CPStoryView : UIView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,  WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate>

typedef void (^CPStoryViewFinishedBlock)(void);
typedef void (^CPStoryViewOpenedBlock)(NSURL* url, CPStoryViewFinishedBlock finishedCallback);

@property (strong, nonatomic) UICollectionView *storyCollection;
@property (strong, nonatomic) UIView *emptyView;
@property (nonatomic, strong) CPStoryWidget *widget;
@property (nonatomic, strong) NSMutableArray<CPStory*> *stories;
@property (strong, nonatomic) NSMutableArray *readStories;
@property (nonatomic, strong) UIColor *ringBorderColor;
@property (nonatomic, strong) UIColor *borderColorLoading;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *unreadStoryCountBackgroundColor;
@property (nonatomic, strong) UIColor *unreadStoryCountTextColor;
@property (nonatomic, strong) UIColor *borderColorDarkMode;
@property (nonatomic, strong) UIColor *borderColorLoadingDarkMode;
@property (nonatomic, strong) UIColor *backgroundColorDarkMode;
@property (nonatomic, strong) UIColor *textColorDarkMode;
@property (nonatomic, strong) UIColor *unreadStoryCountBackgroundColorDarkMode;
@property (nonatomic, strong) UIColor *unreadStoryCountTextColorDarkMode;
@property (nonatomic, strong) UIColor *backgroundColorLightMode;
@property (nonatomic, strong) NSString *fontStyle;
@property (nonatomic, assign) BOOL titleVisibility;
@property (nonatomic, assign) BOOL storyIconBorderVisibility;
@property (nonatomic, assign) BOOL storyIconShadow;
@property (nonatomic, assign) BOOL isFixedCellLayout;
@property (nonatomic, assign) BOOL unreadStoryCountVisibility;
@property (nonatomic, assign) BOOL storyWidgetShareButtonVisibility;
@property (nonatomic, assign) BOOL sortToLastIndex;
@property (nonatomic, assign) BOOL allowAutoRotation;
@property (nonatomic, assign) BOOL hasTrackedShown;
@property (nonatomic, assign) BOOL autoTrackShown;
@property (nonatomic) int titleTextSize;
@property (nonatomic) int storyIconHeight;
@property (nonatomic) int storyIconWidth;
@property (nonatomic) int storyIconCornerRadius;
@property (nonatomic) int storyIconSpacing;
@property (nonatomic) int storyIconBorderMargin;
@property (nonatomic) int storyIconBorderWidth;
@property (nonatomic) int storyRestrictToItems;
@property (nonatomic) CPStoryWidgetCloseButtonPosition closeButtonPosition;
@property (nonatomic) CPStoryWidgetTextPosition textPosition;

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor widgetId:(NSString *)id;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth widgetId:(NSString *)id;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth widgetId:(NSString *)id;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth storyIconCornerRadius:(int)storyIconCornerRadius storyIconSpacing:(int)storyIconSpacing storyIconBorderVisibility:(BOOL)storyIconBorderVisibility storyIconShadow:(BOOL)storyIconShadow widgetId:(NSString *)id;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor borderColorLoading:(UIColor *)borderColorLoading titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth storyIconCornerRadius:(int)storyIconCornerRadius storyIconSpacing:(int)storyIconSpacing storyIconBorderVisibility:(BOOL)storyIconBorderVisibility storyIconBorderMargin:(int)storyIconBorderMargin storyIconBorderWidth:(int)storyIconBorderWidth storyIconShadow:(BOOL)storyIconShadow storyRestrictToItems:(int)storyRestrictToItems unreadStoryCountVisibility:(BOOL)unreadStoryCountVisibility unreadStoryCountBackgroundColor:(UIColor*)unreadStoryCountBackgroundColor unreadStoryCountTextColor:(UIColor*)unreadStoryCountTextColor storyViewCloseButtonPosition:(CPStoryWidgetCloseButtonPosition)storyViewCloseButtonPosition storyViewTextPosition:(CPStoryWidgetTextPosition)storyViewTextPosition storyWidgetShareButtonVisibility:(BOOL)storyWidgetShareButtonVisibility sortToLastIndex:(BOOL)sortToLastIndex allowAutoRotation:(BOOL)allowAutoRotation borderColorDarkMode:(UIColor *)borderColorDarkMode borderColorLoadingDarkMode:(UIColor *)borderColorLoadingDarkMode backgroundColorDarkMode:(UIColor *)backgroundColorDarkMode textColorDarkMode:(UIColor *)textColorDarkMode unreadStoryCountBackgroundColorDarkMode:(UIColor *)unreadStoryCountBackgroundColorDarkMode unreadStoryCountTextColorDarkMode:(UIColor *)unreadStoryCountTextColorDarkMode widgetId:(NSString *)id;
- (void)configureWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor borderColorLoading:(UIColor *)borderColorLoading titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth storyIconCornerRadius:(int)storyIconCornerRadius storyIconSpacing:(int)storyIconSpacing storyIconBorderVisibility:(BOOL)storyIconBorderVisibility storyIconBorderMargin:(int)storyIconBorderMargin storyIconBorderWidth:(int)storyIconBorderWidth storyIconShadow:(BOOL)storyIconShadow storyRestrictToItems:(int)storyRestrictToItems unreadStoryCountVisibility:(BOOL)unreadStoryCountVisibility unreadStoryCountBackgroundColor:(UIColor *)unreadStoryCountBackgroundColor unreadStoryCountTextColor:(UIColor *)unreadStoryCountTextColor storyViewCloseButtonPosition:(CPStoryWidgetCloseButtonPosition)storyViewCloseButtonPosition storyViewTextPosition:(CPStoryWidgetTextPosition)storyViewTextPosition storyWidgetShareButtonVisibility:(BOOL)storyWidgetShareButtonVisibility sortToLastIndex:(BOOL)sortToLastIndex allowAutoRotation:(BOOL)allowAutoRotation borderColorDarkMode:(UIColor *)borderColorDarkMode borderColorLoadingDarkMode:(UIColor *)borderColorLoadingDarkMode backgroundColorDarkMode:(UIColor *)backgroundColorDarkMode textColorDarkMode:(UIColor *)textColorDarkMode unreadStoryCountBackgroundColorDarkMode:(UIColor *)unreadStoryCountBackgroundColorDarkMode unreadStoryCountTextColorDarkMode:(UIColor *)unreadStoryCountTextColorDarkMode autoTrackShown:(BOOL)autoTrackShown widgetId:(NSString *)widgetId;

- (void)setOpenedCallback:(CPStoryViewOpenedBlock)callback;

- (void)trackShown;

+ (void)setWidgetId:(NSString*)widgetId;
+ (void)setDarkModeEnabled:(BOOL)enabled;

+ (NSString*)getWidgetId;
+ (BOOL)getDarkModeEnabled;

@end
