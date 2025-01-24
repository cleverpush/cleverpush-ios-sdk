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
#define DEFAULT_ICON_SPACING 2.5
#define DEFAULT_ICON_MARGIN 0
#define DEFAULT_BORDER_WIDTH 2.5
#define TEXT_HEIGHT 30

CPStoryViewOpenedBlock openedCallback;

@implementation CPStoryView

NSString* storyWidgetId;
BOOL darkModeEnabled;
NSString * const CPAppearanceModeChangedNotification = @"AppearanceModeChangedNotification";
CPStoryCell *previousAnimatedCell;

#pragma mark - Initialise the Widgets with UICollectionView frame
- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor widgetId:(NSString *)id {
	return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor borderColorLoading:borderColor titleVisibility:YES titleTextSize:0 storyIconHeight:0 storyIconWidth:0 storyIconCornerRadius:0 storyIconSpacing:0 storyIconBorderVisibility:YES storyIconBorderMargin:0 storyIconBorderWidth:0 storyIconShadow:NO storyRestrictToItems:0 unreadStoryCountVisibility:NO unreadStoryCountBackgroundColor:nil unreadStoryCountTextColor:nil storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionDefault storyWidgetShareButtonVisibility:YES sortToLastIndex:NO allowAutoRotation:NO borderColorDarkMode:nil borderColorLoadingDarkMode:nil backgroundColorDarkMode:nil textColorDarkMode:nil unreadStoryCountBackgroundColorDarkMode:nil unreadStoryCountTextColorDarkMode:nil autoTrackShown:YES widgetId:id];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor {
	return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor borderColorLoading:borderColor titleVisibility:YES titleTextSize:0 storyIconHeight:0 storyIconWidth:0 storyIconCornerRadius:0 storyIconSpacing:0 storyIconBorderVisibility:YES storyIconBorderMargin:0 storyIconBorderWidth:0 storyIconShadow:NO storyRestrictToItems:0 unreadStoryCountVisibility:NO unreadStoryCountBackgroundColor:nil unreadStoryCountTextColor:nil storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionDefault storyWidgetShareButtonVisibility:YES sortToLastIndex:NO allowAutoRotation:NO borderColorDarkMode:nil borderColorLoadingDarkMode:nil backgroundColorDarkMode:nil textColorDarkMode:nil unreadStoryCountBackgroundColorDarkMode:nil unreadStoryCountTextColorDarkMode:nil autoTrackShown:YES widgetId:nil];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth widgetId:(NSString *)id {
	return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor borderColorLoading:borderColor titleVisibility:YES titleTextSize:0 storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth storyIconCornerRadius:0 storyIconSpacing:0 storyIconBorderVisibility:YES storyIconBorderMargin:0 storyIconBorderWidth:0 storyIconShadow:NO storyRestrictToItems:0 unreadStoryCountVisibility:NO unreadStoryCountBackgroundColor:nil unreadStoryCountTextColor:nil storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionDefault storyWidgetShareButtonVisibility:YES sortToLastIndex:NO allowAutoRotation:NO borderColorDarkMode:nil borderColorLoadingDarkMode:nil backgroundColorDarkMode:nil textColorDarkMode:nil unreadStoryCountBackgroundColorDarkMode:nil unreadStoryCountTextColorDarkMode:nil autoTrackShown:YES widgetId:id];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth {
	return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor borderColorLoading:borderColor titleVisibility:YES titleTextSize:0 storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth storyIconCornerRadius:0 storyIconSpacing:0 storyIconBorderVisibility:YES storyIconBorderMargin:0 storyIconBorderWidth:0 storyIconShadow:NO storyRestrictToItems:0 unreadStoryCountVisibility:NO unreadStoryCountBackgroundColor:nil unreadStoryCountTextColor:nil storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionDefault storyWidgetShareButtonVisibility:YES sortToLastIndex:NO allowAutoRotation:NO borderColorDarkMode:nil borderColorLoadingDarkMode:nil backgroundColorDarkMode:nil textColorDarkMode:nil unreadStoryCountBackgroundColorDarkMode:nil unreadStoryCountTextColorDarkMode:nil autoTrackShown:YES widgetId:nil];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth widgetId:(NSString *)id {
	return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor borderColorLoading:borderColor titleVisibility:titleVisibility titleTextSize:titleTextSize storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth storyIconCornerRadius:0 storyIconSpacing:0 storyIconBorderVisibility:YES storyIconBorderMargin:0 storyIconBorderWidth:0 storyIconShadow:NO storyRestrictToItems:0 unreadStoryCountVisibility:NO unreadStoryCountBackgroundColor:nil unreadStoryCountTextColor:nil storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionDefault storyWidgetShareButtonVisibility:YES sortToLastIndex:NO allowAutoRotation:NO borderColorDarkMode:nil borderColorLoadingDarkMode:nil backgroundColorDarkMode:nil textColorDarkMode:nil unreadStoryCountBackgroundColorDarkMode:nil unreadStoryCountTextColorDarkMode:nil autoTrackShown:YES widgetId:id];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth {
	return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor borderColorLoading:borderColor titleVisibility:titleVisibility titleTextSize:titleTextSize storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth storyIconCornerRadius:0 storyIconSpacing:0 storyIconBorderVisibility:YES storyIconBorderMargin:0 storyIconBorderWidth:0 storyIconShadow:NO storyRestrictToItems:0 unreadStoryCountVisibility:NO  unreadStoryCountBackgroundColor:nil unreadStoryCountTextColor:nil storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionDefault storyWidgetShareButtonVisibility:YES sortToLastIndex:NO allowAutoRotation:NO borderColorDarkMode:nil borderColorLoadingDarkMode:nil backgroundColorDarkMode:nil textColorDarkMode:nil unreadStoryCountBackgroundColorDarkMode:nil unreadStoryCountTextColorDarkMode:nil autoTrackShown:YES widgetId:nil];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth storyIconCornerRadius:(int)storyIconCornerRadius storyIconSpacing:(int)storyIconSpacing storyIconBorderVisibility:(BOOL)storyIconBorderVisibility storyIconShadow:(BOOL)storyIconShadow widgetId:(NSString *)id {
	return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor borderColorLoading:borderColor titleVisibility:titleVisibility titleTextSize:titleTextSize storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth storyIconCornerRadius:storyIconCornerRadius storyIconSpacing:storyIconSpacing storyIconBorderVisibility:storyIconBorderVisibility storyIconBorderMargin:0 storyIconBorderWidth:0 storyIconShadow:storyIconShadow storyRestrictToItems:0 unreadStoryCountVisibility:NO unreadStoryCountBackgroundColor:nil unreadStoryCountTextColor:nil storyViewCloseButtonPosition:CPStoryWidgetCloseButtonPositionLeftSide storyViewTextPosition:CPStoryWidgetTextPositionDefault storyWidgetShareButtonVisibility:YES sortToLastIndex:NO allowAutoRotation:NO borderColorDarkMode:nil borderColorLoadingDarkMode:nil backgroundColorDarkMode:nil textColorDarkMode:nil unreadStoryCountBackgroundColorDarkMode:nil unreadStoryCountTextColorDarkMode:nil autoTrackShown:YES widgetId:id];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor borderColorLoading:(UIColor *)borderColorLoading titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth storyIconCornerRadius:(int)storyIconCornerRadius storyIconSpacing:(int)storyIconSpacing storyIconBorderVisibility:(BOOL)storyIconBorderVisibility storyIconBorderMargin:(int)storyIconBorderMargin storyIconBorderWidth:(int)storyIconBorderWidth storyIconShadow:(BOOL)storyIconShadow storyRestrictToItems:(int)storyRestrictToItems unreadStoryCountVisibility:(BOOL)unreadStoryCountVisibility unreadStoryCountBackgroundColor:(UIColor*)unreadStoryCountBackgroundColor unreadStoryCountTextColor:(UIColor*)unreadStoryCountTextColor storyViewCloseButtonPosition:(CPStoryWidgetCloseButtonPosition)storyViewCloseButtonPosition storyViewTextPosition:(CPStoryWidgetTextPosition)storyViewTextPosition storyWidgetShareButtonVisibility:(BOOL)storyWidgetShareButtonVisibility sortToLastIndex:(BOOL)sortToLastIndex allowAutoRotation:(BOOL)allowAutoRotation borderColorDarkMode:(UIColor *)borderColorDarkMode borderColorLoadingDarkMode:(UIColor *)borderColorLoadingDarkMode backgroundColorDarkMode:(UIColor *)backgroundColorDarkMode textColorDarkMode:(UIColor *)textColorDarkMode unreadStoryCountBackgroundColorDarkMode:(UIColor *)unreadStoryCountBackgroundColorDarkMode unreadStoryCountTextColorDarkMode:(UIColor *)unreadStoryCountTextColorDarkMode autoTrackShown:(BOOL)autoTrackShown widgetId:(NSString *)id {
	return [[super initWithFrame:frame] CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor borderColorLoading:borderColorLoading titleVisibility:titleVisibility titleTextSize:titleTextSize storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth storyIconCornerRadius:storyIconCornerRadius storyIconSpacing:storyIconSpacing storyIconBorderVisibility:storyIconBorderVisibility storyIconBorderMargin:storyIconBorderMargin storyIconBorderWidth:storyIconBorderWidth storyIconShadow:storyIconShadow storyRestrictToItems:storyRestrictToItems unreadStoryCountVisibility:unreadStoryCountVisibility  unreadStoryCountBackgroundColor:unreadStoryCountBackgroundColor unreadStoryCountTextColor:unreadStoryCountTextColor storyViewCloseButtonPosition:storyViewCloseButtonPosition storyViewTextPosition:storyViewTextPosition storyWidgetShareButtonVisibility:storyWidgetShareButtonVisibility sortToLastIndex:sortToLastIndex allowAutoRotation:allowAutoRotation borderColorDarkMode:borderColorDarkMode borderColorLoadingDarkMode:borderColorLoadingDarkMode backgroundColorDarkMode:backgroundColorDarkMode textColorDarkMode:textColorDarkMode unreadStoryCountBackgroundColorDarkMode:unreadStoryCountBackgroundColorDarkMode unreadStoryCountTextColorDarkMode:unreadStoryCountTextColorDarkMode autoTrackShown:autoTrackShown widgetId:id];
}

- (void)configureWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor borderColorLoading:(UIColor *)borderColorLoading titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth storyIconCornerRadius:(int)storyIconCornerRadius storyIconSpacing:(int)storyIconSpacing storyIconBorderVisibility:(BOOL)storyIconBorderVisibility storyIconBorderMargin:(int)storyIconBorderMargin storyIconBorderWidth:(int)storyIconBorderWidth storyIconShadow:(BOOL)storyIconShadow storyRestrictToItems:(int)storyRestrictToItems unreadStoryCountVisibility:(BOOL)unreadStoryCountVisibility unreadStoryCountBackgroundColor:(UIColor *)unreadStoryCountBackgroundColor unreadStoryCountTextColor:(UIColor *)unreadStoryCountTextColor storyViewCloseButtonPosition:(CPStoryWidgetCloseButtonPosition)storyViewCloseButtonPosition storyViewTextPosition:(CPStoryWidgetTextPosition)storyViewTextPosition storyWidgetShareButtonVisibility:(BOOL)storyWidgetShareButtonVisibility sortToLastIndex:(BOOL)sortToLastIndex allowAutoRotation:(BOOL)allowAutoRotation borderColorDarkMode:(UIColor *)borderColorDarkMode borderColorLoadingDarkMode:(UIColor *)borderColorLoadingDarkMode backgroundColorDarkMode:(UIColor *)backgroundColorDarkMode textColorDarkMode:(UIColor *)textColorDarkMode unreadStoryCountBackgroundColorDarkMode:(UIColor *)unreadStoryCountBackgroundColorDarkMode unreadStoryCountTextColorDarkMode:(UIColor *)unreadStoryCountTextColorDarkMode autoTrackShown:(BOOL)autoTrackShown widgetId:(NSString *)widgetId {
	[self CPStoryViewinitWithFrame:frame backgroundColor:backgroundColor textColor:textColor fontFamily:fontFamily borderColor:borderColor borderColorLoading:borderColorLoading titleVisibility:titleVisibility titleTextSize:titleTextSize storyIconHeight:storyIconHeight storyIconWidth:storyIconWidth storyIconCornerRadius:storyIconCornerRadius storyIconSpacing:storyIconSpacing storyIconBorderVisibility:storyIconBorderVisibility storyIconBorderMargin:storyIconBorderMargin storyIconBorderWidth:storyIconBorderWidth storyIconShadow:storyIconShadow storyRestrictToItems:storyRestrictToItems unreadStoryCountVisibility:unreadStoryCountVisibility unreadStoryCountBackgroundColor:unreadStoryCountBackgroundColor unreadStoryCountTextColor:unreadStoryCountTextColor storyViewCloseButtonPosition:storyViewCloseButtonPosition storyViewTextPosition:storyViewTextPosition storyWidgetShareButtonVisibility:storyWidgetShareButtonVisibility sortToLastIndex:sortToLastIndex allowAutoRotation:allowAutoRotation borderColorDarkMode:borderColorDarkMode borderColorLoadingDarkMode:borderColorLoadingDarkMode backgroundColorDarkMode:backgroundColorDarkMode textColorDarkMode:textColorDarkMode unreadStoryCountBackgroundColorDarkMode:unreadStoryCountBackgroundColorDarkMode unreadStoryCountTextColorDarkMode:unreadStoryCountTextColorDarkMode autoTrackShown:autoTrackShown widgetId:widgetId];
}

- (id)CPStoryViewinitWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor fontFamily:(NSString *)fontFamily borderColor:(UIColor *)borderColor borderColorLoading:(UIColor *)borderColorLoading titleVisibility:(BOOL)titleVisibility titleTextSize:(int)titleTextSize storyIconHeight:(int)storyIconHeight storyIconWidth:(int)storyIconWidth storyIconCornerRadius:(int)storyIconCornerRadius storyIconSpacing:(int)storyIconSpacing storyIconBorderVisibility:(BOOL)storyIconBorderVisibility storyIconBorderMargin:(int)storyIconBorderMargin storyIconBorderWidth:(int)storyIconBorderWidth storyIconShadow:(BOOL)storyIconShadow storyRestrictToItems:(int)storyRestrictToItems unreadStoryCountVisibility:(BOOL)unreadStoryCountVisibility unreadStoryCountBackgroundColor:(UIColor*)unreadStoryCountBackgroundColor unreadStoryCountTextColor:(UIColor*)unreadStoryCountTextColor storyViewCloseButtonPosition:(CPStoryWidgetCloseButtonPosition)storyViewCloseButtonPosition storyViewTextPosition:(CPStoryWidgetTextPosition)storyViewTextPosition storyWidgetShareButtonVisibility:(BOOL)storyWidgetShareButtonVisibility sortToLastIndex:(BOOL)sortToLastIndex allowAutoRotation:(BOOL)allowAutoRotation borderColorDarkMode:(UIColor *)borderColorDarkMode borderColorLoadingDarkMode:(UIColor *)borderColorLoadingDarkMode backgroundColorDarkMode:(UIColor *)backgroundColorDarkMode textColorDarkMode:(UIColor *)textColorDarkMode unreadStoryCountBackgroundColorDarkMode:(UIColor *)unreadStoryCountBackgroundColorDarkMode unreadStoryCountTextColorDarkMode:(UIColor *)unreadStoryCountTextColorDarkMode autoTrackShown:(BOOL)autoTrackShown widgetId:(NSString *)id {
    if (self) {
        NSString *customWidgetId = id;
        if (customWidgetId == nil || [customWidgetId isKindOfClass:[NSNull class]] || [customWidgetId isEqualToString:@""]) {
            customWidgetId = [CPStoryView getWidgetId];
        }
        if (customWidgetId != nil && customWidgetId.length != 0) {
            [CPWidgetModule getWidgetsStories:customWidgetId completion:^(CPWidgetsStories *Widget) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
					          self.autoTrackShown = autoTrackShown;

                    if (backgroundColor != nil) {
                        self.backgroundColorLightMode = backgroundColor;
                    }

                    if (backgroundColorDarkMode != nil){
                        self.backgroundColorDarkMode = backgroundColorDarkMode;
                    }

                    if (![CPStoryView getDarkModeEnabled] && backgroundColor != nil) {
                        self.backgroundColor = backgroundColor;
                    } else if ([CPStoryView getDarkModeEnabled] && backgroundColorDarkMode != nil){
                        self.backgroundColor = backgroundColorDarkMode;
                    } else {
                        self.backgroundColor = UIColor.whiteColor;
                    }

                    if (borderColor != nil) {
                        self.ringBorderColor = borderColor;
                    } else {
                        self.ringBorderColor = UIColor.darkGrayColor;
                    }

                    if (borderColorLoading != nil) {
                        self.borderColorLoading = borderColorLoading;
                    } else {
                        self.borderColorLoading = self.ringBorderColor;
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

                    self.storyRestrictToItems = 0;
                    if (storyRestrictToItems > 0) {
                        self.storyRestrictToItems = storyRestrictToItems;
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

                    self.allowAutoRotation = NO;
                    if (allowAutoRotation == YES) {
                        self.allowAutoRotation = allowAutoRotation;
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

                    if (borderColorDarkMode != nil) {
                        self.borderColorDarkMode = borderColorDarkMode;
                    } else {
                        self.borderColorDarkMode = self.ringBorderColor;
                    }

                    if (borderColorLoadingDarkMode != nil) {
                        self.borderColorLoadingDarkMode = borderColorLoadingDarkMode;
                    } else {
                        self.borderColorLoadingDarkMode = self.borderColorDarkMode;
                    }

                    if (textColorDarkMode != nil) {
                        self.textColorDarkMode = textColorDarkMode;
                    } else {
                        self.textColorDarkMode = self.textColor;
                    }

                    if (unreadStoryCountBackgroundColorDarkMode != nil) {
                        self.unreadStoryCountBackgroundColorDarkMode = unreadStoryCountBackgroundColorDarkMode;
                    } else {
                        self.unreadStoryCountBackgroundColorDarkMode = self.unreadStoryCountBackgroundColor;
                    }

                    if (unreadStoryCountTextColorDarkMode != nil) {
                        self.unreadStoryCountTextColorDarkMode = unreadStoryCountTextColorDarkMode;
                    } else {
                        self.unreadStoryCountTextColorDarkMode = self.unreadStoryCountBackgroundColor;
                    }

                    self.closeButtonPosition = storyViewCloseButtonPosition;
                    self.textPosition = storyViewTextPosition;

                    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
                    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
                    if (self.storyRestrictToItems > 0) {
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

                    if (self.widget != nil && self.widget.groupStoryCategories) {
                        for (CPStory *story in self.stories) {
                            NSString *storyIdString = story.id;
                            if (storyIdString != nil) {
                                NSArray *storyIdArray = [storyIdString componentsSeparatedByString:@","];
                                NSInteger subStoryCount = storyIdArray.count;
                                story.subStoryCount = subStoryCount;

                                NSString *storyUnreadCountString = [[NSUserDefaults standardUserDefaults] stringForKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_GROUP_KEY];
                                NSArray *readStoryIdArray = @[];
                                if (storyUnreadCountString != nil) {
                                    readStoryIdArray = [storyUnreadCountString componentsSeparatedByString:@","];
                                }
                                NSInteger readCount = 0;

                                for (NSString *subStoryID in storyIdArray) {
                                    if ([readStoryIdArray containsObject:subStoryID]) {
                                        readCount++;
                                        story.opened = YES;
                                    }
                                }

                                NSInteger unreadCount = subStoryCount - readCount;
                                story.unreadCount = unreadCount;
                            }
                        }

                        [self syncUnreadStoryIds];
                    } else {
                        NSDictionary *existingMap = [defaults objectForKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_KEY];
                        for (CPStory *story in self.stories) {
                            if (story.content != nil && story.content.pages != nil) {
                                story.subStoryCount = story.content.pages.count;
                            }

                            NSString *storyId = story.id;
                            if (storyId != nil) {
                                if (existingMap != nil && [existingMap objectForKey:storyId] != nil) {
                                    NSInteger unreadCount = [existingMap[storyId] integerValue];
                                    story.unreadCount = unreadCount;
                                } else {
                                    if (story.content != nil && story.content.pages != nil) {
                                        story.unreadCount = story.content.pages.count;
                                    } else {
                                        story.unreadCount = 0;
                                    }
                                }
                            }
                        }
                    }

                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadStoryView) name:CPAppearanceModeChangedNotification object:nil];

                    [self reloadReadStories:CleverPush.getSeenStories];
                    [CleverPush addStoryView:self];

                    self.hasInitialized = YES;
                    if (self.pendingTrackShownCall) {
                        [self trackShown];
                    }
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

- (void)layoutSubviews {
    if (self.allowAutoRotation == YES) {
        [super layoutSubviews];

        CGRect collectionViewFrame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
        if (self.storyRestrictToItems > 0) {
            self.storyCollection.frame = collectionViewFrame;
        } else {
            self.storyCollection.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height + TEXT_HEIGHT);
        }

        [self checkVisibilityAndTrack];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.storyCollection.collectionViewLayout invalidateLayout];
            [self.storyCollection reloadData];
        });
    }
}

- (void)checkVisibilityAndTrack {
    if (self.superview) {
        CGRect visibleRect = self.superview.bounds;
        if (CGRectIntersectsRect(self.frame, visibleRect)) {
            [self trackShownIfNeeded];
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (self.allowAutoRotation == YES) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.storyCollection.collectionViewLayout invalidateLayout];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.storyCollection performBatchUpdates:^{
                [self.storyCollection reloadData];
            } completion:nil];
        }];
    }
}

- (void)trackShownIfNeeded {
	if (!self.autoTrackShown || self.hasTrackedShown) {
		return;
	}

  [self trackShown];
  self.hasTrackedShown = YES;
}

- (BOOL) shouldAutorotate {
    return self.allowAutoRotation;
}

#pragma mark - Set & get story widgetId
+ (void)setWidgetId:(NSString *)widgetId {
    storyWidgetId = widgetId;
}

+ (NSString*)getWidgetId {
    return storyWidgetId;
}

+ (void)setDarkModeEnabled:(BOOL)enabled {
    darkModeEnabled = enabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:CPAppearanceModeChangedNotification object:nil];
}

+ (BOOL)getDarkModeEnabled {
    return darkModeEnabled;
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
        cell.name.numberOfLines = 2;
        [cell addSubview:cell.name];
    }

    [self configureCellFrame:cell withWidth:width height:height];
    [self configureCellContent:cell atIndexPath:indexPath];
    [self configureCellAppearance:cell forIndexPath:indexPath];
}

- (void)configureCellFrame:(CPStoryCell *)cell withWidth:(CGFloat)width height:(CGFloat)height {
    CGFloat borderMargin = MAX(self.storyIconBorderMargin, 0);
    CGFloat imagePadding = borderMargin;
    CGFloat outerRingHeight = height - 5;
    CGFloat outerRingWidth = width - 5;

    if (self.storyRestrictToItems > 0) {
        cell.outerRing.frame = CGRectMake(0, 5, outerRingWidth, outerRingHeight);
        cell.outerRing.layer.cornerRadius = self.storyIconCornerRadius;

        if (self.titleVisibility && self.textPosition == CPStoryWidgetTextPositionDefault) {
            cell.outerRing.frame = CGRectMake(0, 5, outerRingWidth, height - TEXT_HEIGHT);
            cell.image.frame = CGRectMake(imagePadding, imagePadding, outerRingWidth - 2 * imagePadding, cell.outerRing.frame.size.height);
            cell.name.frame = CGRectMake(0, CGRectGetMaxY(cell.outerRing.frame), outerRingWidth, TEXT_HEIGHT);
        } else if (self.titleVisibility && (self.textPosition == CPStoryWidgetTextPositionInsideTop || self.textPosition == CPStoryWidgetTextPositionInsideBottom)) {
            cell.outerRing.frame = CGRectMake(0, 5, outerRingWidth, outerRingHeight);
            cell.image.frame = CGRectMake(0, 0, outerRingWidth, outerRingHeight);

            if (self.textPosition == CPStoryWidgetTextPositionInsideTop) {
                cell.name.frame = CGRectMake(5, 0, outerRingWidth - 10, outerRingHeight / 2);
            } else if (self.textPosition == CPStoryWidgetTextPositionInsideBottom) {
                CGFloat titleTextHeight = TEXT_HEIGHT + 10;
                cell.name.frame = CGRectMake(5, outerRingHeight - titleTextHeight, outerRingWidth - 10, titleTextHeight);
            }
        } else {
            cell.image.frame = CGRectMake(0, 0, outerRingWidth, outerRingHeight);
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
    if (![CPUtils isNullOrEmpty:self.stories[indexPath.item].content.preview.widgetSrc]) {
        imageURL = [NSURL URLWithString:self.stories[indexPath.item].content.preview.widgetSrc];
        if (darkModeEnabled) {
            imageURL = [NSURL URLWithString:self.stories[indexPath.item].content.preview.widgetDarkSrc];
        }
    }
    [cell.image setImageWithURL:imageURL];

    if (self.titleVisibility) {
        if (self.widget.groupStoryCategories) {
            cell.name.text = self.stories[indexPath.item].content.subtitle;
        } else {
            cell.name.text = self.stories[indexPath.item].title;
        }
        cell.name.textColor = self.textColor;
        if (darkModeEnabled) {
            cell.name.textColor = self.textColorDarkMode;
        }
        cell.name.font = [self fontForTitleTextSize];
    }
}

- (void)configureCellAppearance:(CPStoryCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    if (self.storyIconBorderVisibility) {
        BOOL isStoryRead = [self.readStories containsObject:self.stories[indexPath.item].id] || self.stories[indexPath.item].opened;
        CGFloat borderWidth = self.storyIconBorderWidth;
        CGColorRef borderColor = self.ringBorderColor.CGColor;

        if (darkModeEnabled) {
            borderColor = self.borderColorDarkMode.CGColor;
        }

        if (isStoryRead) {
            cell.outerRing.layer.borderWidth = borderWidth - 0.5;
            cell.outerRing.layer.borderColor = [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0].CGColor;

            if (self.widget != nil && self.widget.groupStoryCategories) {
                NSString *storyIdString = self.stories[indexPath.item].id;
                if (storyIdString) {
                    NSArray *storyIdArray = [storyIdString componentsSeparatedByString:@","];
                    NSString *storyUnreadCountString = [[NSUserDefaults standardUserDefaults] stringForKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_GROUP_KEY];
                    NSArray *readStoryIdArray = storyUnreadCountString ? [storyUnreadCountString componentsSeparatedByString:@","] : @[];

                    BOOL hasUnreadStories = NO;
                    for (NSString *subStoryID in storyIdArray) {
                        if (![readStoryIdArray containsObject:subStoryID]) {
                            hasUnreadStories = YES;
                            break;
                        }
                    }

                    if (hasUnreadStories) {
                        cell.outerRing.layer.borderWidth = borderWidth;
                        cell.outerRing.layer.borderColor = borderColor;
                    }
                }
            }
        } else {
            cell.outerRing.layer.borderWidth = borderWidth;
            cell.outerRing.layer.borderColor = borderColor;
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
        cell.unReadCount.frame = CGRectMake(CGRectGetWidth(cell.outerRing.frame) - 15, 0, 20, 20);
        cell.unReadCount.backgroundColor = self.unreadStoryCountBackgroundColor;
        cell.unReadCount.textColor = self.unreadStoryCountTextColor;
        cell.unReadCount.layer.borderWidth = 1.0;
        cell.unReadCount.layer.borderColor = [self.unreadStoryCountTextColor CGColor];

        if (darkModeEnabled) {
            cell.unReadCount.backgroundColor = self.unreadStoryCountBackgroundColorDarkMode;
            cell.unReadCount.textColor = self.unreadStoryCountTextColorDarkMode;
            cell.unReadCount.layer.borderColor = [self.unreadStoryCountTextColorDarkMode CGColor];
        } 

        if (self.stories[indexPath.item].unreadCount <= 0) {
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
    if (self.storyRestrictToItems > 0) {
        CGFloat collectionViewWidth = CGRectGetWidth(collectionView.frame);
        CGFloat collectionViewHeight = CGRectGetHeight(collectionView.frame);
        NSInteger numberOfCellsInRow = self.storyRestrictToItems;
        CGFloat totalPadding = (numberOfCellsInRow - 1) * self.storyIconSpacing;
        CGFloat availableWidth = collectionViewWidth - totalPadding;
        CGFloat cellWidth = availableWidth / numberOfCellsInRow;
        CGFloat cellHeight = collectionViewHeight;
        return CGSizeMake(cellWidth, cellHeight);
    } else {
        return CGSizeMake(self.storyIconWidth, self.storyIconHeight + TEXT_HEIGHT);
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self stopAnimationForCurrentCell];
    CPStoryCell *cell = (CPStoryCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self animateCellBorder:cell];
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
    storiesController.openedCallback = openedCallback;
    storiesController.closeButtonPosition = self.closeButtonPosition;
    storiesController.storyWidgetShareButtonVisibility = self.storyWidgetShareButtonVisibility;
    storiesController.allowAutoRotation = self.allowAutoRotation;
    storiesController.widget = self.widget;
    [storiesController loadContentWithCompletion:^{
           [self stopAnimationForCurrentCell];
           [topController presentViewController:storiesController animated:YES completion:nil];
       }];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (self.storyRestrictToItems > 0) {
        CGFloat collectionViewWidth = CGRectGetWidth(collectionView.frame);
        NSInteger numberOfCellsInRow = self.storyRestrictToItems;
        CGFloat cellWidth = (collectionViewWidth - (numberOfCellsInRow - 1) * self.storyIconSpacing) / numberOfCellsInRow;
        CGFloat totalCellWidth = cellWidth * numberOfCellsInRow + (numberOfCellsInRow - 1) * self.storyIconSpacing;
        CGFloat horizontalInset = (collectionViewWidth - totalCellWidth) / 2;
        return UIEdgeInsetsMake(0, horizontalInset, 0, horizontalInset);
    } else {
        return UIEdgeInsetsMake(0, 0, 0, 0);
    }
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

#pragma mark - Story Cell Border Animation
- (void)animateCellBorder:(CPStoryCell *)cell {
    if (![self isGradientLayerAddedToCell:cell]) {
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];

        if (darkModeEnabled) {
            gradientLayer.colors = @[(id)self.borderColorLoadingDarkMode.CGColor];
        } else {
            gradientLayer.colors = @[(id)self.borderColorLoading.CGColor];
        }

        gradientLayer.locations = @[@0.0, @0.5, @1.0];
        gradientLayer.frame = cell.outerRing.bounds;
        gradientLayer.startPoint = CGPointMake(0, 0.5);
        gradientLayer.endPoint = CGPointMake(1, 0.5);

        [cell.outerRing.layer insertSublayer:gradientLayer atIndex:0];
        cell.outerRing.layer.borderWidth = 3.0;
        cell.outerRing.layer.borderColor = [UIColor clearColor].CGColor;
    }

    CABasicAnimation *borderColorAnimation = [CABasicAnimation animationWithKeyPath:@"borderColor"];

    if (darkModeEnabled) {
        borderColorAnimation.fromValue = (id)[UIColor clearColor].CGColor;
        borderColorAnimation.toValue = (id)self.borderColorLoadingDarkMode.CGColor;
    } else {
        borderColorAnimation.fromValue = (id)[UIColor clearColor].CGColor;
        borderColorAnimation.toValue = (id)self.borderColorLoading.CGColor;
    }

    borderColorAnimation.duration = 1.0;
    borderColorAnimation.autoreverses = YES;
    borderColorAnimation.repeatCount = INFINITY;

    if (![cell.outerRing.layer animationForKey:@"borderColorAnimation"]) {
        [cell.outerRing.layer addAnimation:borderColorAnimation forKey:@"borderColorAnimation"];
    }

    previousAnimatedCell = cell;
}

- (void)stopAnimationForCurrentCell {
    if (previousAnimatedCell) {
        [previousAnimatedCell.outerRing.layer removeAnimationForKey:@"borderColorAnimation"];
        previousAnimatedCell.outerRing.layer.borderColor = [UIColor clearColor].CGColor;
        [self removeGradientLayerFromCell:previousAnimatedCell];
    }
}

- (BOOL)isGradientLayerAddedToCell:(CPStoryCell *)cell {
    for (CALayer *sublayer in cell.outerRing.layer.sublayers) {
        if ([sublayer isKindOfClass:[CAGradientLayer class]]) {
            return YES;
        }
    }
    return NO;
}

- (void)removeGradientLayerFromCell:(CPStoryCell *)cell {
    for (CALayer *sublayer in cell.outerRing.layer.sublayers) {
        if ([sublayer isKindOfClass:[CAGradientLayer class]]) {
            [sublayer removeFromSuperlayer];
            break;
        }
    }
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
                        story.opened = YES;
                        story.unreadCount = 0;
                    } else {
                        [unSeenArray addObject:story];
                        story.unreadCount = story.content.pages.count;
                        story.opened = NO;
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
        if (self.widget.groupStoryCategories) {
            for (CPStory *story in self.stories) {
                NSString *storyIdString = story.id;
                if (storyIdString != nil) {
                    NSArray *storyIdArray = [storyIdString componentsSeparatedByString:@","];
                    NSInteger subStoryCount = storyIdArray.count;
                    story.subStoryCount = subStoryCount;

                    NSString *storyUnreadCountString = [defaults stringForKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_GROUP_KEY];
                    NSArray *readStoryIdArray = @[];
                    if (storyUnreadCountString != nil) {
                        readStoryIdArray = [storyUnreadCountString componentsSeparatedByString:@","];
                    }
                    NSInteger readCount = 0;

                    for (NSString *subStoryID in storyIdArray) {
                        if ([readStoryIdArray containsObject:subStoryID]) {
                            readCount++;
                            story.opened = YES;
                        }
                    }

                    NSInteger unreadCount = subStoryCount - readCount;
                    story.unreadCount = unreadCount;
                }
            }
        } else {
            NSDictionary *existingMap = [defaults objectForKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_KEY];
            for (CPStory *story in self.stories) {
                BOOL isRead = [self.readStories containsObject:story.id];
                if (isRead) {
                    if (existingMap != nil) {
                        NSNumber *unreadCountNumber = existingMap[story.id];
                        if (unreadCountNumber != nil) {
                            story.unreadCount = [unreadCountNumber integerValue];
                            story.opened = YES;
                        } else {
                            if (story.content != nil && story.content.pages != nil) {
                                story.unreadCount = story.content.pages.count;
                            } else {
                                story.unreadCount = 0;
                            }
                            story.opened = NO;
                        }
                    } else {
                        if (story.content != nil && story.content.pages != nil) {
                            story.unreadCount = story.content.pages.count;
                        } else {
                            story.unreadCount = 0;
                        }
                        story.opened = NO;
                    }
                } else {
                    if (story.content != nil && story.content.pages != nil) {
                        story.unreadCount = story.content.pages.count;
                    } else {
                        story.unreadCount = 0;
                    }
                    story.opened = NO;
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.storyCollection reloadData];
        });
    }
}

#pragma mark - Callback function while storyview has been open-up url successfully
- (void)setOpenedCallback:(__strong CPStoryViewOpenedBlock)callback {
    openedCallback = callback;
}

#pragma mark - Dark/Light mode UI Apperance
- (void)reloadStoryView {
    if (self.widget != nil && self.stories != nil && self.stories.count > 0 && self.storyCollection != nil && CGRectGetWidth(self.storyCollection.bounds) > 0 && CGRectGetHeight(self.storyCollection.bounds) > 0) {
        if (![CPStoryView getDarkModeEnabled] && self.backgroundColorLightMode != nil) {
            self.backgroundColor = self.backgroundColorLightMode;
        } else if ([CPStoryView getDarkModeEnabled] && self.backgroundColorDarkMode != nil){
            self.backgroundColor = self.backgroundColorDarkMode;
        } else {
            self.backgroundColor = UIColor.whiteColor;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.storyCollection reloadData];
        });
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CPAppearanceModeChangedNotification object:nil];
}

#pragma mark - Tracking when story widget has been rendered
- (void)trackShown {
  if (!self.hasInitialized) {
    self.pendingTrackShownCall = YES;
    return;
  }
  self.pendingTrackShownCall = NO;

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    if (self.widget != nil) {
      NSMutableArray <NSString*>* storyIdArray = [NSMutableArray new];
      for (CPStory *story in self.stories) {
        NSString *storyIdString = story.id;
        if (storyIdString != nil) {
          if (self.widget.groupStoryCategories) {
            NSArray *currentStoryIds = [storyIdString componentsSeparatedByString:@","];
            for (NSString *storyId in currentStoryIds) {
              [storyIdArray addObject:storyId];
            }
          } else {
            [storyIdArray addObject:storyIdString];
          }
        }
      }

      [CPWidgetModule trackWidgetShown:self.widget.id withStories:storyIdArray onSuccess:nil onFailure:^(NSError * _Nullable error) {
        [CPLog error:@"Failed to mark story as shown: %@ %@", self.widget.id, error];
      }];
    }
	});
}

#pragma mark - Unread Story ID Synchronization
- (void)syncUnreadStoryIds {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *storyUnreadCountString = [userDefaults stringForKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_GROUP_KEY];

    if (storyUnreadCountString != nil && storyUnreadCountString.length > 0) {
        NSMutableSet *readStoryIds = [NSMutableSet setWithArray:[storyUnreadCountString componentsSeparatedByString:@","]];
        NSMutableString *updatedUnreadStoryIds = [NSMutableString string];

        for (CPStory *story in self.stories) {
            NSArray *storyIdArray = [story.id componentsSeparatedByString:@","];

            for (NSString *subStoryID in storyIdArray) {
                if ([readStoryIds containsObject:subStoryID]) {
                    if (updatedUnreadStoryIds.length == 0) {
                        [updatedUnreadStoryIds appendString:subStoryID];
                    } else {
                        [updatedUnreadStoryIds appendFormat:@",%@", subStoryID];
                    }
                }
            }
        }

        [userDefaults removeObjectForKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_GROUP_KEY];
        [userDefaults setObject:updatedUnreadStoryIds forKey:CLEVERPUSH_SEEN_STORIES_UNREAD_COUNT_GROUP_KEY];
        [userDefaults synchronize];
    }
}

@end
