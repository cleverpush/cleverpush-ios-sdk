#import "CPStoryView.h"
#import "CleverPush.h"
#import "CPStoryCell.h"
#import "CPWidgetModule.h"
#import "CPStoriesController.h"
#import "CPLog.h"
#import "CPStoryWidgetCloseButtonPosition.h"
#import "CPStoryWidgetTextPosition.h"

#define DEFAULT_TEXT_SIZE 10
#define DEFAULT_ICON_SIZE 75
#define DEFAULT_ICON_CORNER_RADIUS 0
#define DEFAULT_ICON_SPACING 10
#define DEFAULT_ICON_MARGIN 0
#define DEFAULT_BORDER_WIDTH 2.5
#define TEXT_HEIGHT 30

@implementation CPStoryView

NSString* storyWidgetId;

#pragma mark - Initialise the Widgets with UICollectionView frame
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor widgetId:(NSString *)id {
    return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor titleVisibility:YES titleTextSize:0 storyIconHeight:0 storyIconWidth:0 storyIconCornerRadius:0 storyIconSpacing:0 storyIconBorderVisibility:YES storyIconBorderMargin:0 storyIconBorderWidth:0 storyIconShadow:NO isFixedCellLayout:NO unreadStoryCountVisibility:NO unreadStoryCountBackgroundColor:nil unreadStoryCountTextColor:nil storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionDefault storyWidgetShareButtonVisibility:YES sortToLastIndex:NO widgetId:id];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor {
    return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor titleVisibility:YES titleTextSize:0 storyIconHeight:0 storyIconWidth:0 storyIconCornerRadius:0 storyIconSpacing:0 storyIconBorderVisibility:YES storyIconBorderMargin:0 storyIconBorderWidth:0 storyIconShadow:NO isFixedCellLayout:NO unreadStoryCountVisibility:NO unreadStoryCountBackgroundColor:nil unreadStoryCountTextColor:nil storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionDefault storyWidgetShareButtonVisibility:YES sortToLastIndex:NO widgetId:nil];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth widgetId:(NSString *)id {
    return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor titleVisibility:YES titleTextSize:0 storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth storyIconCornerRadius:0 storyIconSpacing:0 storyIconBorderVisibility:YES storyIconBorderMargin:0 storyIconBorderWidth:0 storyIconShadow:NO isFixedCellLayout:NO unreadStoryCountVisibility:NO unreadStoryCountBackgroundColor:nil unreadStoryCountTextColor:nil storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionDefault storyWidgetShareButtonVisibility:YES sortToLastIndex:NO widgetId:id];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth {
    return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor titleVisibility:YES titleTextSize:0 storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth storyIconCornerRadius:0 storyIconSpacing:0 storyIconBorderVisibility:YES storyIconBorderMargin:0 storyIconBorderWidth:0 storyIconShadow:NO isFixedCellLayout:NO unreadStoryCountVisibility:NO unreadStoryCountBackgroundColor:nil unreadStoryCountTextColor:nil storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionDefault storyWidgetShareButtonVisibility:YES sortToLastIndex:NO widgetId:nil];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth widgetId:(NSString *)id {
    return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor titleVisibility:titleVisibility titleTextSize:titleTextSize storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth storyIconCornerRadius:0 storyIconSpacing:0 storyIconBorderVisibility:YES storyIconBorderMargin:0 storyIconBorderWidth:0 storyIconShadow:NO isFixedCellLayout:NO unreadStoryCountVisibility:NO unreadStoryCountBackgroundColor:nil unreadStoryCountTextColor:nil storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionDefault storyWidgetShareButtonVisibility:YES sortToLastIndex:NO widgetId:id];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth {
    return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor titleVisibility:titleVisibility titleTextSize:titleTextSize storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth storyIconCornerRadius:0 storyIconSpacing:0 storyIconBorderVisibility:YES storyIconBorderMargin:0 storyIconBorderWidth:0 storyIconShadow:NO isFixedCellLayout:NO unreadStoryCountVisibility:NO  unreadStoryCountBackgroundColor:nil unreadStoryCountTextColor:nil storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionDefault storyWidgetShareButtonVisibility:YES sortToLastIndex:NO widgetId:nil];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth storyIconCornerRadius:(int)storyIconCornerRadius storyIconSpacing:(int)storyIconSpacing storyIconBorderVisibility:(BOOL)storyIconBorderVisibility storyIconShadow:(BOOL)storyIconShadow widgetId:(NSString *)id {
    return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor titleVisibility:titleVisibility titleTextSize:titleTextSize storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth storyIconCornerRadius:storyIconCornerRadius storyIconSpacing:storyIconSpacing storyIconBorderVisibility:storyIconBorderVisibility storyIconBorderMargin:0 storyIconBorderWidth:0 storyIconShadow:storyIconShadow isFixedCellLayout:NO unreadStoryCountVisibility:NO unreadStoryCountBackgroundColor:nil unreadStoryCountTextColor:nil storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionDefault storyWidgetShareButtonVisibility:YES sortToLastIndex:NO widgetId:id];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth storyIconCornerRadius:(int)storyIconCornerRadius storyIconSpacing:(int)storyIconSpacing storyIconBorderVisibility:(BOOL)storyIconBorderVisibility storyIconBorderMargin:(int)storyIconBorderMargin storyIconBorderWidth:(int)storyIconBorderWidth storyIconShadow:(BOOL)storyIconShadow isFixedCellLayout:(BOOL)isFixedCellLayout unreadStoryCountVisibility:(BOOL)unreadStoryCountVisibility unreadStoryCountBackgroundColor:(UIColor*)unreadStoryCountBackgroundColor unreadStoryCountTextColor:(UIColor*)unreadStoryCountTextColor storyViewCloseButtonPosition:(CPStoryWidgetCloseButtonPosition)storyViewCloseButtonPosition storyViewTextPosition:(CPStoryWidgetTextPosition)storyViewTextPosition storyWidgetShareButtonVisibility:(BOOL)storyWidgetShareButtonVisibility sortToLastIndex:(BOOL)sortToLastIndex widgetId:(NSString *)id {
    return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor titleVisibility:titleVisibility titleTextSize:titleTextSize storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth storyIconCornerRadius:storyIconCornerRadius storyIconSpacing:storyIconSpacing storyIconBorderVisibility:storyIconBorderVisibility storyIconBorderMargin:storyIconBorderMargin storyIconBorderWidth:storyIconBorderWidth storyIconShadow:storyIconShadow isFixedCellLayout:isFixedCellLayout unreadStoryCountVisibility:unreadStoryCountVisibility  unreadStoryCountBackgroundColor:unreadStoryCountBackgroundColor unreadStoryCountTextColor:unreadStoryCountTextColor storyViewCloseButtonPosition:storyViewCloseButtonPosition storyViewTextPosition:storyViewTextPosition storyWidgetShareButtonVisibility:storyWidgetShareButtonVisibility sortToLastIndex:sortToLastIndex widgetId:id];
}

- (id)CPStoryViewinitWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth storyIconCornerRadius:(int)storyIconCornerRadius storyIconSpacing:(int)storyIconSpacing storyIconBorderVisibility:(BOOL)storyIconBorderVisibility storyIconBorderMargin:(int)storyIconBorderMargin storyIconBorderWidth:(int)storyIconBorderWidth storyIconShadow:(BOOL)storyIconShadow isFixedCellLayout:(BOOL)isFixedCellLayout unreadStoryCountVisibility:(BOOL)unreadStoryCountVisibility unreadStoryCountBackgroundColor:(UIColor*)unreadStoryCountBackgroundColor unreadStoryCountTextColor:(UIColor*)unreadStoryCountTextColor storyViewCloseButtonPosition:(CPStoryWidgetCloseButtonPosition)storyViewCloseButtonPosition storyViewTextPosition:(CPStoryWidgetTextPosition)storyViewTextPosition storyWidgetShareButtonVisibility:(BOOL)storyWidgetShareButtonVisibility sortToLastIndex:(BOOL)sortToLastIndex widgetId:(NSString *)id {
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

                    self.titleVisibility = YES;
                    if (titleVisibility == NO) {
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

                    self.storyIconCornerRadius = DEFAULT_ICON_CORNER_RADIUS;
                    if (storyIconCornerRadius > 0) {
                        self.storyIconCornerRadius = storyIconCornerRadius;
                    }

                    self.storyIconSpacing = DEFAULT_ICON_SPACING;
                    if (storyIconSpacing > 0) {
                        self.storyIconSpacing = storyIconSpacing;
                    }

                    self.storyIconBorderWidth = DEFAULT_BORDER_WIDTH;
                    if (storyIconBorderWidth > 0) {
                        self.storyIconBorderWidth = storyIconBorderWidth;
                    }

                    self.storyIconBorderMargin = DEFAULT_ICON_MARGIN;
                    if (storyIconBorderMargin > 0) {
                        self.storyIconBorderMargin = storyIconBorderMargin;
                    }

                    self.storyIconBorderVisibility = YES;
                    if (storyIconBorderVisibility == NO) {
                        self.storyIconBorderVisibility = storyIconBorderVisibility;
                    }

                    self.storyIconShadow = NO;
                    if (storyIconShadow == YES) {
                        self.storyIconShadow = storyIconShadow;
                    }

                    self.isFixedCellLayout = NO;
                    if (isFixedCellLayout == YES) {
                        self.isFixedCellLayout = isFixedCellLayout;
                        self.storyIconSpacing = 10;
                    }

                    self.unreadStoryCountVisibility = NO;
                    if (unreadStoryCountVisibility == YES) {
                        self.unreadStoryCountVisibility = unreadStoryCountVisibility;
                    }

                    self.storyWidgetShareButtonVisibility = YES;
                    if (storyWidgetShareButtonVisibility == NO) {
                        self.storyWidgetShareButtonVisibility = storyWidgetShareButtonVisibility;
                    }

                    self.sortToLastIndex = NO;
                    if (sortToLastIndex == YES) {
                        self.sortToLastIndex = sortToLastIndex;
                    }

                    if (unreadStoryCountBackgroundColor != nil) {
                        self.unreadStoryCountBackgroundColor = unreadStoryCountBackgroundColor;
                    } else {
                        self.unreadStoryCountBackgroundColor = UIColor.whiteColor;
                    }

                    if (unreadStoryCountTextColor != nil) {
                        self.unreadStoryCountTextColor = unreadStoryCountTextColor;
                    } else {
                        self.unreadStoryCountTextColor = UIColor.blackColor;
                    }

                    self.closeButtonPosition = storyViewCloseButtonPosition;
                    self.textPosition = storyViewTextPosition;

                    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
                    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
                    if (self.isFixedCellLayout) {
                        self.storyCollection = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) collectionViewLayout:layout];
                    } else {
                        self.storyCollection = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height + TEXT_HEIGHT) collectionViewLayout:layout];
                    }
                    [self.storyCollection registerClass:[CPStoryCell class] forCellWithReuseIdentifier:@"CPStoryCell"];
                    self.storyCollection.backgroundColor = UIColor.clearColor;
                    self.storyCollection.showsHorizontalScrollIndicator = NO;
                    self.storyCollection.directionalLockEnabled = YES;
                    [self.storyCollection setDataSource:self];
                    [self.storyCollection setDelegate:self];
                    [self addSubview:self.storyCollection];
                    self.widget = Widget.widgets;
                    self.stories = Widget.stories;

                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    NSDictionary *existingMap = [defaults objectForKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_KEY];

                    for (CPStory *story in self.stories) {
                        if (story.content.pages != nil) {
                            story.subStoryCount = story.content.pages.count;
                        }

                        NSString *storyId = story.id;
                        if (existingMap != nil && [existingMap objectForKey:storyId] != nil) {
                            NSInteger unreadCount = [existingMap[storyId] integerValue];
                            story.unreadCount = unreadCount;
                        } else {
                            story.unreadCount = story.content.pages.count;
                        }
                    }
                    
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

    CGFloat cellWidth = CGRectGetWidth(cell.frame);
    CGFloat cellHeight = CGRectGetHeight(cell.frame);

    [self configureCell:cell withWidth:cellWidth height:cellHeight atIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(CPStoryCell *)cell withWidth:(CGFloat)width height:(CGFloat)height atIndexPath:(NSIndexPath *)indexPath {
    if (!cell.outerRing) {
        cell.outerRing = [[UIView alloc] init];
        [cell addSubview:cell.outerRing];
    }

    if (!cell.image) {
        cell.image = [[UIImageView alloc] init];
        cell.image.contentMode = UIViewContentModeScaleAspectFill;
        [cell.outerRing addSubview:cell.image];
    }

    if (!cell.name) {
        cell.name = [[UILabel alloc] init];
        cell.name.textAlignment = NSTextAlignmentCenter;
        cell.name.numberOfLines = 0;
        [cell addSubview:cell.name];
    }

    [self configureCellFrame:cell withWidth:width height:height];
    [self configureCellContent:cell atIndexPath:indexPath];
    [self configureCellAppearance:cell forIndexPath:indexPath];
}

- (void)configureCellFrame:(CPStoryCell *)cell withWidth:(CGFloat)width height:(CGFloat)height {
    CGFloat borderMargin = MAX(self.storyIconBorderMargin, 0);
    CGFloat imagePadding = borderMargin;

    if (self.isFixedCellLayout) {
        CGFloat outerRingHeight = height - 5;
        cell.outerRing.frame = CGRectMake(0, 5, width, outerRingHeight);
        cell.outerRing.layer.cornerRadius = self.storyIconCornerRadius;

        if (self.titleVisibility && self.textPosition == CPStoryWidgetTextPositionDefault) {
            cell.outerRing.frame = CGRectMake(0, 5, width, height - TEXT_HEIGHT);
            cell.image.frame = CGRectMake(imagePadding, imagePadding, width - 2 * imagePadding, cell.outerRing.frame.size.height);
            cell.name.frame = CGRectMake(0, CGRectGetMaxY(cell.outerRing.frame), width, TEXT_HEIGHT);
        } else if (self.titleVisibility && (self.textPosition == CPStoryWidgetTextPositionInsideTop || self.textPosition == CPStoryWidgetTextPositionInsideBottom)) {
            cell.outerRing.frame = CGRectMake(0, 5, width, outerRingHeight);
            cell.image.frame = CGRectMake(0, 0, width, outerRingHeight);

            if (self.textPosition == CPStoryWidgetTextPositionInsideTop) {
                cell.name.frame = CGRectMake(5, 0, width - 10, outerRingHeight / 2);
            } else if (self.textPosition == CPStoryWidgetTextPositionInsideBottom) {
                cell.name.frame = CGRectMake(5, outerRingHeight - TEXT_HEIGHT, width - 10, TEXT_HEIGHT);
            }
        } else {
            cell.image.frame = CGRectMake(0, 0, width, outerRingHeight);
        }

        cell.image.layer.cornerRadius = self.storyIconCornerRadius;
    } else {
        CGFloat storyIconHeight = self.storyIconHeight;
        CGFloat storyIconWidth = self.storyIconWidth;
        CGFloat outerRingY = 10;
        CGFloat cornerRadius = self.storyIconCornerRadius > 0 ? self.storyIconCornerRadius : storyIconHeight / 2;

        cell.outerRing.frame = CGRectMake(0, outerRingY, storyIconWidth, storyIconHeight);
        cell.outerRing.layer.cornerRadius = cornerRadius;

        CGRect imageFrame = self.storyIconBorderVisibility ? CGRectMake(5, 5, storyIconWidth - 10, storyIconHeight - 10) : CGRectMake(0, 0, storyIconWidth, storyIconHeight);
        cell.image.frame = imageFrame;
        cell.image.layer.cornerRadius = cornerRadius;

        if (self.titleVisibility) {
            cell.name.frame = CGRectMake(0, CGRectGetMaxY(cell.outerRing.frame), storyIconWidth, TEXT_HEIGHT);
        }
    }

    cell.image.clipsToBounds = YES;
}

- (void)configureCellContent:(CPStoryCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSURL *imageURL = [NSURL URLWithString:self.stories[indexPath.item].content.preview.posterPortraitSrc];
    [cell.image setImageWithURL:imageURL];

    if (self.titleVisibility) {
        cell.name.text = self.stories[indexPath.item].title;
        cell.name.textColor = self.textColor;
        cell.name.font = [self fontForTitleTextSize];
    }
}

- (void)configureCellAppearance:(CPStoryCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    if (self.storyIconBorderVisibility) {
        if ([self.readStories containsObject:self.stories[indexPath.item].id] || self.stories[indexPath.item].opened == YES) {
            cell.outerRing.layer.borderWidth = self.storyIconBorderWidth - 0.5;
            cell.outerRing.layer.borderColor = [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0].CGColor;
        } else {
            cell.outerRing.layer.borderWidth = self.storyIconBorderWidth;
            cell.outerRing.layer.borderColor = self.ringBorderColor.CGColor;
        }
    }

    if (self.storyIconShadow) {
        cell.outerRing.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.3].CGColor;
        cell.outerRing.layer.shadowOffset = CGSizeMake(0, 3);
        cell.outerRing.layer.shadowOpacity = 0.6;
        cell.outerRing.layer.shadowRadius = 1.5;
        cell.outerRing.layer.masksToBounds = NO;
    }

    if (self.unreadStoryCountVisibility) {
        if (!cell.unReadCount) {
            cell.unReadCount = [[UILabel alloc] init];
            cell.unReadCount.textAlignment = NSTextAlignmentCenter;
            cell.unReadCount.font = [UIFont boldSystemFontOfSize:10];
            cell.unReadCount.layer.cornerRadius = 10;
            cell.unReadCount.clipsToBounds = YES;
        }
        cell.unReadCount.frame = CGRectMake(CGRectGetWidth(cell.frame) - 15, 0, 20, 20);
        cell.unReadCount.backgroundColor = self.unreadStoryCountBackgroundColor;
        cell.unReadCount.textColor = self.unreadStoryCountTextColor;

        if (([self.readStories containsObject:self.stories[indexPath.item].id] || self.stories[indexPath.item].opened == YES) && self.stories[indexPath.item].unreadCount <= 0) {
            [cell.unReadCount removeFromSuperview];
        } else {
            [cell addSubview:cell.unReadCount];
            cell.unReadCount.text = [NSString stringWithFormat:@"%ld", self.stories[indexPath.item].unreadCount];
        }
    }

    cell.outerRing.clipsToBounds = YES;
}

- (UIFont *)fontForTitleTextSize {
    if (self.fontStyle && [self.fontStyle length] > 0 && [CPUtils fontFamilyExists:self.fontStyle]) {
        return [UIFont fontWithName:self.fontStyle size:(CGFloat)(self.titleTextSize)];
    }
    return [UIFont systemFontOfSize:(CGFloat)(self.titleTextSize) weight:UIFontWeightSemibold];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isFixedCellLayout) {
        CGFloat collectionViewWidth = CGRectGetWidth(collectionView.frame);
        CGFloat collectionViewHeight = CGRectGetHeight(collectionView.frame);
        NSInteger numberOfCellsInRow = 3;
        CGFloat totalPadding = self.storyIconSpacing * numberOfCellsInRow;
        CGFloat availableWidth = collectionViewWidth - totalPadding;
        CGFloat cellWidth = availableWidth / numberOfCellsInRow;
        CGFloat cellHeight = collectionViewHeight;
        return CGSizeMake(cellWidth, cellHeight);
    } else {
        return CGSizeMake(self.storyIconWidth, self.storyIconHeight + TEXT_HEIGHT);
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    CPStoriesController* storiesController = [[CPStoriesController alloc] init];
    if (![self.readStories containsObject:self.stories[indexPath.item].id]) {
        [self.readStories addObject:self.stories[indexPath.item].id];
        self.stories[indexPath.item].opened = YES;
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
    storiesController.closeButtonPosition = self.closeButtonPosition;
    storiesController.storyWidgetShareButtonVisibility = self.storyWidgetShareButtonVisibility;
    storiesController.widget = self.widget;
    [topController presentViewController:storiesController animated:YES completion:nil];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.storyIconSpacing;
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
    self.readStories = [NSMutableArray arrayWithArray:CleverPush.getSeenStories];

    if (self.sortToLastIndex) {
        if (self.readStories.count != 0 && self.readStories.count != self.stories.count) {
            NSMutableArray<CPStory *> *seenArray = [NSMutableArray array];
            NSMutableArray<CPStory *> *unSeenArray = [NSMutableArray array];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSSet *readStoriesSet = [NSSet setWithArray:self.readStories];

                for (CPStory *story in self.stories) {
                    if ([readStoriesSet containsObject:story.id]) {
                        [seenArray addObject:story];
                    } else {
                        [unSeenArray addObject:story];
                    }
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.stories removeAllObjects];
                    [self.stories addObjectsFromArray:unSeenArray];
                    [self.stories addObjectsFromArray:seenArray];
                    [self.storyCollection reloadData];
                });
            });
        }
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *existingMap = [defaults objectForKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_KEY];

        for (CPStory *story in self.stories) {
            BOOL isRead = [self.readStories containsObject:story.id];
            if (isRead) {
                NSNumber *unreadCountNumber = existingMap[story.id];
                if (unreadCountNumber != nil) {
                    story.unreadCount = [unreadCountNumber integerValue];
                    story.opened = YES;
                } else {
                    story.unreadCount = story.content.pages.count;
                    story.opened = NO;
                }
            } else {
                story.unreadCount = story.content.pages.count;
                story.opened = NO;
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.storyCollection reloadData];
        });
    }
}

@end
