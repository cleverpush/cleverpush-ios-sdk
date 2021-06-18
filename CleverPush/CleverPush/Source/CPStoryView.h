#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "CPWidget.h"
#import "CPStory.h"
#import "UIImageView+CleverPush.h"

@interface CPStoryView : UIView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) UICollectionView *storyCollection;
@property (nonatomic, strong) CPWidget *widget;
@property (nonatomic, strong) NSString *fontStyle;
@property (nonatomic, strong) UIColor *ringBorderColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) NSMutableArray<CPStory*> *stories;
@property (strong, nonatomic) NSMutableArray *readStories;

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor family:(NSString *)family borderColor:(UIColor *)borderColor widgetStoryId:(NSString *)id;

@end
