#import "CPStoryView.h"
#import "CleverPush.h"
#import "CPStoryCell.h"
#import "CPWidgetModule.h"
#import "CPStoriesController.h"
#import "CPLog.h"

#define DEFAULT_TEXT_SIZE 10
#define DEFAULT_ICON_SIZE 75
#define TEXT_HEIGHT 30

@implementation CPStoryView

NSString* storyWidgetId;

#pragma mark - Initialise the Widgets with UICollectionView frame
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor widgetId:(NSString *)id {
    return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor titleVisibility:true titleTextSize:0 storyIconHeight:0 storyIconWidth:0 widgetId:id];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor {
    return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor titleVisibility:true titleTextSize:0 storyIconHeight:0 storyIconWidth:0 widgetId:nil];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth widgetId:(NSString *)id {
    return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor titleVisibility:true titleTextSize:0 storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth widgetId:id];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth {
    return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor titleVisibility:true titleTextSize:0 storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth widgetId:nil];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth widgetId:(NSString *)id {
    return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor titleVisibility:titleVisibility titleTextSize:titleTextSize storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth widgetId:id];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth {
    return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor titleVisibility:titleVisibility titleTextSize:titleTextSize storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth widgetId:nil];
}

- (id)CPStoryViewinitWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth widgetId:(NSString *)id {
    if (self) {
        NSString *customWidgetId = id;
        if (customWidgetId == nil || [customWidgetId isKindOfClass:[NSNull class]] || [customWidgetId isEqualToString:@""]) {
            customWidgetId = [CPStoryView getWidgetId];
        }
        if (customWidgetId != nil && customWidgetId.length != 0) {
            [CPWidgetModule getWidgetsStories:customWidgetId completion:^(CPWidgetsStories *Widget) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    if (backgroundColor != nil) {
                        self.backgroundColor = backgroundColor;
                    } else {
                        self.backgroundColor = UIColor.whiteColor;
                    }

                    if (borderColor != nil) {
                        self.ringBorderColor = borderColor;
                    } else {
                        self.ringBorderColor = UIColor.darkGrayColor;
                    }

                    if (textColor != nil) {
                        self.textColor = textColor;
                    } else {
                        self.textColor = UIColor.blackColor;
                    }

                    if (fontFamily != nil && fontFamily.length != 0) {
                        self.fontStyle = fontFamily;
                    } else {
                        self.fontStyle = @"AppleSDGothicNeo-Regular";
                    }

                    self.titleVisibility = TRUE;
                    if (titleVisibility == false) {
                        self.titleVisibility = titleVisibility;
                    }

                    self.titleTextSize = DEFAULT_TEXT_SIZE;
                    if (titleTextSize > 0) {
                        self.titleTextSize = titleTextSize;
                    }

                    self.storyIconWidth = DEFAULT_ICON_SIZE;
                    if (storyIconWidth > 0) {
                        self.storyIconWidth = storyIconWidth;
                    }

                    self.storyIconHeight = DEFAULT_ICON_SIZE;
                    if (storyIconHeight > 0) {
                        self.storyIconHeight = storyIconHeight;
                    }

                    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
                    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
                    self.storyCollection = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, self.storyIconHeight + TEXT_HEIGHT) collectionViewLayout:layout];
                    [self.storyCollection registerClass:[CPStoryCell class] forCellWithReuseIdentifier:@"CPStoryCell"];
                    self.storyCollection.backgroundColor = UIColor.clearColor;
                    self.storyCollection.directionalLockEnabled = YES;
                    [self.storyCollection setDataSource:self];
                    [self.storyCollection setDelegate:self];
                    [self addSubview:self.storyCollection];
                    self.widget = Widget.widgets;
                    self.stories = Widget.stories;
                    [self reloadReadStories:CleverPush.getSeenStories];
                    [CleverPush addStoryView:self];
                });
            }];
        } else {
            self.emptyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 125.0)];
            UILabel *emptyString = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 125.0)];
            self.emptyView.backgroundColor = backgroundColor;
            emptyString.text = @"Please enter a valid story ID.";
            [emptyString setFont:[UIFont fontWithName:@"AppleSDGothicNeo-Bold" size:(CGFloat)(17.0)]];
            emptyString.textAlignment = NSTextAlignmentCenter;
            [self.emptyView addSubview:emptyString];
            [self addSubview:self.emptyView];
            [CleverPush addStoryView:self];
        }
    }
    return self;
}

#pragma mark - Set & get story widgetId
+ (void)setWidgetId:(NSString *)widgetId {
    storyWidgetId = widgetId;
}

+ (NSString*)getWidgetId {
    return storyWidgetId;
}

#pragma mark - UICollectionView delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.stories.count;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CPStoryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CPStoryCell" forIndexPath:indexPath];

    if (!cell.image) {
        cell.outerRing = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.storyIconWidth, self.storyIconHeight)];
        [cell addSubview:cell.outerRing];
        cell.image = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, self.storyIconWidth - 10, self.storyIconHeight - 10)];
        [cell.outerRing addSubview:cell.image];
        cell.name = [[UILabel alloc] initWithFrame:CGRectMake(0, cell.outerRing.frame.size.height, self.storyIconWidth, TEXT_HEIGHT)];
        [cell addSubview:cell.name];
    }

    cell.image.contentMode = UIViewContentModeScaleAspectFill;
    cell.image.clipsToBounds = YES;
    cell.name.text = self.stories[indexPath.item].title;
    cell.name.textColor = self.textColor;
    cell.name.textAlignment = NSTextAlignmentCenter;
    cell.name.numberOfLines = 1;
    
    if (self.fontStyle && [self.fontStyle length] > 0 && [CPUtils fontFamilyExists:self.fontStyle]) {
        [cell.name setFont:[UIFont fontWithName:self.fontStyle size:(CGFloat)(self.titleTextSize)]];
    } else {
        [CPLog error:@"Font Family not found: %@", self.fontStyle];
        [cell.name setFont:[UIFont systemFontOfSize:(CGFloat)(self.titleTextSize) weight:UIFontWeightSemibold]];
    }

    if (self.stories[indexPath.item].content.preview.posterPortraitSrc != nil && ![self.stories[indexPath.item].content.preview.posterPortraitSrc isKindOfClass:[NSNull class]]) {
        [cell.image setImageWithURL:[NSURL URLWithString:self.stories[indexPath.item].content.preview.posterPortraitSrc]];
    }
    cell.image.layer.cornerRadius = cell.image.frame.size.height / 2;
    cell.outerRing.layer.cornerRadius = cell.outerRing.frame.size.height / 2;
    cell.outerRing.backgroundColor = UIColor.whiteColor;

    if ([self.readStories containsObject:self.stories[indexPath.item].id]) {
        cell.outerRing.layer.borderWidth = 2.0;
        cell.outerRing.layer.borderColor = [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0].CGColor;
    } else {
        cell.outerRing.layer.borderWidth = 2.5;
        cell.outerRing.layer.borderColor = self.ringBorderColor.CGColor;
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.storyIconWidth, self.storyIconHeight + TEXT_HEIGHT);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    CPStoriesController* storiesController = [[CPStoriesController alloc] init];
    if (![self.readStories containsObject:self.stories[indexPath.item].id]) {
        [self.readStories addObject:self.stories[indexPath.item].id];
    }
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.readStories forKey:CLEVERPUSH_SEEN_STORIES_KEY];
    storiesController.storyIndex = indexPath.item;
    storiesController.stories = self.stories;
    storiesController.readStories = self.readStories;
    storiesController.delegate = self;
    UIViewController* topController = [CleverPush topViewController];
    storiesController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    storiesController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    storiesController.openedCallback = self.openedCallback;
    [topController presentViewController:storiesController animated:YES completion:nil];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    CPStoryCell *cell = (CPStoryCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.image.alpha = 0.5;
    cell.outerRing.alpha = 0.5;
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    CPStoryCell *cell = (CPStoryCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.image.alpha = 1.0;
    cell.outerRing.alpha = 1.0;
}

- (void)reloadReadStories:(NSArray *)array {
    self.readStories = [[NSMutableArray alloc] initWithArray:CleverPush.getSeenStories];
    if (self.readStories.count != 0 && self.readStories.count != self.stories.count) {
        NSMutableArray<CPStory *> *seenArray = [NSMutableArray array];
        NSMutableArray<CPStory *> *unSeenArray = [NSMutableArray array];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            for (int cp = 0; cp < self.stories.count; cp++) {
                if ([self.readStories containsObject:self.stories[cp].id]) {
                    [seenArray addObject:self.stories[cp]];
                } else {
                    [unSeenArray addObject:self.stories[cp]];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.stories removeAllObjects];
                [self.stories addObjectsFromArray:unSeenArray];
                [self.stories addObjectsFromArray:seenArray];
                [self.storyCollection reloadData];
            });
        });
    } else {
        [self.storyCollection reloadData];
    }
}

@end
