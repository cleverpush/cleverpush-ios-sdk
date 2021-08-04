#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "CPStoryWidget.h"
#import "CPStory.h"
#import "UIImageView+CleverPush.h"

@interface CPStoryView : UIView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) UICollectionView *storyCollection;
@property (strong, nonatomic) UIView *emptyView;
@property (nonatomic, strong) CPStoryWidget *widget;
@property (nonatomic, strong) NSMutableArray<CPStory*> *stories;
@property (strong, nonatomic) NSMutableArray *readStories;
@property (nonatomic, strong) UIColor *ringBorderColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) NSString *fontStyle;

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor storyWidgetId:(NSString *)id;

@end
