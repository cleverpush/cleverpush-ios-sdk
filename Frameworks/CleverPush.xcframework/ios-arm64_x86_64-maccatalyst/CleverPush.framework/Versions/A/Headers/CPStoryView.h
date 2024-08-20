#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "CPStoryWidget.h"
#import "CPStory.h"
#import "UIImageView+CleverPush.h"
#import "CPStoryWidgetCloseButtonPosition.h"
#import "CPStoryWidgetTextPosition.h"

@interface CPStoryView : UIView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

typedef void (^CPStoryViewOpenedBlock)(NSURL* url);

@property (strong, nonatomic) UICollectionView *storyCollection;
@property (strong, nonatomic) UIView *emptyView;
@property (nonatomic, strong) CPStoryWidget *widget;
@property (nonatomic, strong) NSMutableArray<CPStory*> *stories;
@property (strong, nonatomic) NSMutableArray *readStories;
@property (nonatomic, strong) UIColor *ringBorderColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *unreadStoryCountBackgroundColor;
@property (nonatomic, strong) UIColor *unreadStoryCountTextColor;
@property (nonatomic, strong) NSString *fontStyle;
@property (nonatomic, assign) BOOL titleVisibility;
@property (nonatomic, assign) BOOL storyIconBorderVisibility;
@property (nonatomic, assign) BOOL storyIconShadow;
@property (nonatomic, assign) BOOL isFixedCellLayout;
@property (nonatomic, assign) BOOL unreadStoryCountVisibility;
@property (nonatomic, assign) BOOL storyWidgetShareButtonVisibility;
@property (nonatomic) int titleTextSize;
@property (nonatomic) int storyIconHeight;
@property (nonatomic) int storyIconWidth;
@property (nonatomic) int storyIconCornerRadius;
@property (nonatomic) int storyIconSpacing;
@property (nonatomic) int storyIconBorderMargin;
@property (nonatomic) int storyIconBorderWidth;
@property (nonatomic) CPStoryWidgetCloseButtonPosition closeButtonPosition;
@property (nonatomic) CPStoryWidgetTextPosition textPosition;
@property (atomic, strong) CPStoryViewOpenedBlock openedCallback;

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor widgetId:(NSString *)id;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth widgetId:(NSString *)id;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth widgetId:(NSString *)id;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth storyIconCornerRadius:(int)storyIconCornerRadius storyIconSpacing:(int)storyIconSpacing storyIconBorderVisibility:(BOOL)storyIconBorderVisibility storyIconShadow:(BOOL)storyIconShadow widgetId:(NSString *)id;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth storyIconCornerRadius:(int)storyIconCornerRadius storyIconSpacing:(int)storyIconSpacing storyIconBorderVisibility:(BOOL)storyIconBorderVisibility storyIconBorderMargin:(int)storyIconBorderMargin storyIconBorderWidth:(int)storyIconBorderWidth storyIconShadow:(BOOL)storyIconShadow isFixedCellLayout:(BOOL)isFixedCellLayout unreadStoryCountVisibility:(BOOL)unreadStoryCountVisibility unreadStoryCountBackgroundColor:(UIColor*)unreadStoryCountBackgroundColor unreadStoryCountTextColor:(UIColor*)unreadStoryCountTextColor storyViewCloseButtonPosition:(CPStoryWidgetCloseButtonPosition)storyViewCloseButtonPosition storyViewTextPosition:(CPStoryWidgetTextPosition)storyViewTextPosition storyWidgetShareButtonVisibility:(BOOL)storyWidgetShareButtonVisibility widgetId:(NSString *)id;
+ (void)setWidgetId:(NSString*)widgetId;

+ (NSString*)getWidgetId;

@end
