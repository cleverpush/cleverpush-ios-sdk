#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "CPStoryWidget.h"
#import "CPStory.h"
#import "UIImageView+CleverPush.h"

@interface CPStoryView : UIView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

typedef void (^CPStoryViewOpenedBlock)(NSURL* url);

@property (strong, nonatomic) UICollectionView *storyCollection;
@property (strong, nonatomic) UIView *emptyView;
@property (nonatomic, strong) CPStoryWidget *widget;
@property (nonatomic, strong) NSMutableArray<CPStory*> *stories;
@property (strong, nonatomic) NSMutableArray *readStories;
@property (nonatomic, strong) UIColor *ringBorderColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) NSString *fontStyle;
@property (nonatomic, assign) BOOL titleVisibility;
@property (nonatomic) int titleTextSize;
@property (nonatomic) int storyIconHeight;
@property (nonatomic) int storyIconWidth;
@property (atomic, strong) CPStoryViewOpenedBlock openedCallback;

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor widgetId:(NSString *)id;
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth widgetId:(NSString *)id;

@end
