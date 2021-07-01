#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "CPWidget.h"
#import "CPStory.h"
#import "UIImageView+CleverPush.h"
#import "CPTranslate.h"

@interface CPStoryView : UIView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) UICollectionView *storyCollection;
@property (strong, nonatomic) UIView *emptyView;
@property (nonatomic, strong) CPWidget *widget;
@property (nonatomic, strong) NSMutableArray<CPStory*> *stories;
@property (strong, nonatomic) NSMutableArray *readStories;
@property (nonatomic, strong) UIColor *ringBorderColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) NSString *fontStyle;

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor family:(NSString *)family borderColor:(UIColor *)borderColor widgetStoryId:(NSString *)id;

@end
