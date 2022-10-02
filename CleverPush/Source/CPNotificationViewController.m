#import "CPNotificationViewController.h"

#define kPaddingLeft            0
#define kpaddingRight           0
#define kPaddingTop             0
#define kPaddingBottom          0

#define kTextPaddingLeft        10
#define kTextPaddingRight       10
#define kTextPaddingTop         0
#define kTextPaddingBottom      10

#define kPageIndicatorHeight    30

#define kImageCornerRadius      0.0

@interface CPNotificationViewController ()

@property (strong, nonatomic) NSMutableArray *items;
@property NSArray *carouselItems;

@end

@implementation CPNotificationViewController

@synthesize carousel;
@synthesize items;
@synthesize pageControl;
@synthesize carouselItems;

#pragma mark - Controller Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setBackgroundColor];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.carousel = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self createAndConfigCarousel];
}

#pragma mark - Set view controller's background color
- (void)setBackgroundColor {
    self.view.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];;
}

#pragma mark - Release memories of carousel
- (void)dealloc {
    carousel.delegate = nil;
    carousel.dataSource = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Initialise carousel
- (void)createAndConfigCarousel {
    carousel = [[CleverPushiCarousel alloc] initWithFrame:CGRectMake(kPaddingLeft, kPaddingTop, self.view.frame.size.width - (kPaddingLeft + kpaddingRight), self.view.frame.size.height - (kPaddingTop + kPaddingBottom))];
    carousel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    carousel.type = iCarouselTypeLinear;
    carousel.delegate = self;
    carousel.dataSource = self;
    carousel.autoscroll = -0.1;
    [self.view addSubview:carousel];
}

#pragma mark - Initialise page indicator of carousel
- (void)createPageIndicator:(NSUInteger)numberOfPages {
    UIPageControl *pc = [[UIPageControl alloc] init];
    pageControl = pc;
    pageControl.frame = CGRectMake(0, self.view.frame.size.height - kPageIndicatorHeight, self.view.frame.size.width, kPageIndicatorHeight);
    pageControl.numberOfPages = numberOfPages;
    pageControl.currentPage = 0;
    pageControl.pageIndicatorTintColor = [UIColor whiteColor];
    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    [self.view addSubview:pageControl];
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Define the counts of the carousel
- (NSInteger)numberOfItemsInCarousel:(__unused CleverPushiCarousel *)carousel {
    return (NSInteger)[self.items count];
}

#pragma mark - Define the content mode of image
- (UIViewContentMode)setImageContentMode: (NSString *)mode {
    if ([mode isEqual: @"ScaleToFill"]) {
        return UIViewContentModeScaleToFill;
    } else if ([mode isEqual: @"AspectFill"]) {
        return UIViewContentModeScaleAspectFill;
    } else if ([mode isEqual: @"AspectFit"]) {
        return UIViewContentModeScaleAspectFit;
    } else {
        return UIViewContentModeScaleAspectFill;
    }
}

#pragma mark - Initialise the and return view of the carousel
- (UIView *)carousel:(CleverPushiCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(kPaddingLeft, kPaddingTop, self.view.frame.size.width - (kPaddingLeft + kpaddingRight), self.view.frame.size.height - (kPaddingTop + kPaddingBottom))];
    imageView.image = [items objectAtIndex:index];
    imageView.contentMode = [self setImageContentMode:@"AspectFill"];
    view = imageView;
    view.layer.cornerRadius = kImageCornerRadius;
    view.layer.masksToBounds = YES;
    return view;
}

#pragma mark - Identify carousel notification and load in to the carousel
- (void)cleverpushDidReceiveNotification:(UNNotification *)notification  API_AVAILABLE(ios(10.0)) {
    if ([notification.request.content.categoryIdentifier isEqualToString:@"carousel"]) {
        [self getImages:notification];
        [self createPageIndicator:self.items.count];
        [self setCarouselTheme:[notification.request.content.userInfo  objectForKey:@"carouselTheme"]];
        if ([notification.request.content.categoryIdentifier isEqualToString:@"carousel"]) {
            self.carousel.autoscroll = 0;
        } else if ([notification.request.content.categoryIdentifier isEqualToString:@"carouselAnimation"]) {
            self.carousel.autoscroll = -0.1;
        }
        if (self.items.count == 1) {
            self.carousel.autoscroll = 0;
        }
        [self.carousel reloadData];
    }
}

#pragma mark - Set carousel theme
- (void)setCarouselTheme:(NSString *)themeName {
    if (themeName == nil) {
        return;
    }
    self.carousel.type = [self fetchCarouselThemeEnum:themeName];
}

#pragma mark - Get carousel images from the notification payload
- (void)getImages:(UNNotification *)notification API_AVAILABLE(ios(10.0)) {
    NSArray <UNNotificationAttachment *> *attachments = notification.request.content.attachments;
    [self fetchAttachmentsToImageArray:attachments];
    NSDictionary* cpNotification = [notification.request.content.userInfo objectForKey:@"notification"];
    self.carouselItems = [cpNotification objectForKey:@"carouselItems"];
    
    if (self.items.count < self.carouselItems.count) {
        NSMutableArray *images = [[NSMutableArray alloc]init];
        images = [self.items mutableCopy];
        NSMutableArray *attachmentIDs = [[NSMutableArray alloc]init];
        for(UNNotificationAttachment *attachment in attachments) {
            [attachmentIDs addObject:attachment.identifier];
        }
        [self.carouselItems enumerateObjectsUsingBlock:
         ^(NSDictionary *image, NSUInteger index, BOOL *stop) {
            if (attachmentIDs.count < index + 1 || ![[attachmentIDs objectAtIndex:index] isEqualToString:[NSString stringWithFormat:@"media_%lu.jpg", (unsigned long)index]]) {
                NSURL *imageURL = [NSURL URLWithString:[image objectForKey:@"mediaUrl"]];
                NSData *imageData = nil;
                if (imageURL != nil && imageURL.absoluteString.length != 0) {
                    imageData = [[NSData alloc] initWithContentsOfURL: imageURL];
                    UIImage *image = [UIImage imageWithData:imageData];
                    [images insertObject:image atIndex:index];
                    [attachmentIDs insertObject:[NSString stringWithFormat:@"media_%lu.jpg", (unsigned long)index] atIndex:index];
                }
            }
        }];
        self.items = images;
    }
}

#pragma mark - Get the array of attachments
- (void)fetchAttachmentsToImageArray:(NSArray *)attachments {
    NSMutableArray *itemsArray = [[NSMutableArray alloc]init];
    if (@available(iOS 10.0, *)) {
        for (UNNotificationAttachment *attachment in attachments) {
            if (attachment.URL.startAccessingSecurityScopedResource) {
                UIImage *image = [UIImage imageWithContentsOfFile:attachment.URL.path];
                if (image != nil) {
                    [itemsArray addObject:image];
                }
            }
        }
    }
    self.items = itemsArray;
}

#pragma mark - Action identifier to on dynamic next/previous button
- (void)cleverpushDidReceiveNotificationResponse:(UNNotificationResponse *)response completionHandler:(void (^)(UNNotificationContentExtensionResponseOption))completion API_AVAILABLE(ios(10.0)) {
    if ([response.actionIdentifier isEqualToString:@"next"]) {
        [carousel scrollToItemAtIndex:carousel.currentItemIndex + 1 animated:YES];
        completion(UNNotificationContentExtensionResponseOptionDoNotDismiss);
    } else if ([response.actionIdentifier isEqualToString:@"previous"]) {
        [carousel scrollToItemAtIndex:carousel.currentItemIndex - 1 animated:YES];
        completion(UNNotificationContentExtensionResponseOptionDoNotDismiss);
    } else {
        completion(UNNotificationContentExtensionResponseOptionDismissAndForwardAction);
    }
}

- (CATransform3D)carousel:(__unused CleverPushiCarousel *)carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform {
    transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
    return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * self.carousel.itemWidth);
}

#pragma mark - Carousel enumeration
- (CGFloat)carousel:(__unused CleverPushiCarousel *)icarousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value {
    switch (option)
    {
        case iCarouselOptionWrap: {
            return YES;
        }
        case iCarouselOptionSpacing: {
            if (icarousel.type == iCarouselTypeLinear) {
                return value * 1.1f;
            } else {
                return value * 1.2f;
            }
        }
        case iCarouselOptionFadeMax: {
            if (self.carousel.type == iCarouselTypeCustom)
            {
                return 0.0f;
            }
            return value;
        }
        case iCarouselOptionShowBackfaces:
        case iCarouselOptionRadius:
        case iCarouselOptionAngle:
        case iCarouselOptionArc:
        case iCarouselOptionTilt:
        case iCarouselOptionCount:
        case iCarouselOptionFadeMin:
        case iCarouselOptionFadeMinAlpha:
        case iCarouselOptionFadeRange:
        case iCarouselOptionOffsetMultiplier:
        case iCarouselOptionVisibleItems: {
            return value;
        }
    }
}

#pragma mark - Trigger event when index is going to change of carousel
- (void)carouselCurrentItemIndexDidChange:(CleverPushiCarousel *)icarousel {
    pageControl.currentPage = icarousel.currentItemIndex;
}

#pragma mark - Get the theme of the carousel
- (iCarouselType)fetchCarouselThemeEnum:(NSString *)themeName {
    if ([themeName isEqualToString:@"linear"]) {
        return iCarouselTypeLinear;
    } else if([themeName isEqualToString:@"rotary"]) {
        return iCarouselTypeRotary;
    } else if([themeName isEqualToString:@"invertedRotary"]) {
        return iCarouselTypeInvertedRotary;
    } else if([themeName isEqualToString:@"cylinder"]) {
        return iCarouselTypeCylinder;
    } else if([themeName isEqualToString:@"invertedCylinder"]) {
        return iCarouselTypeInvertedCylinder;
    } else if([themeName isEqualToString:@"wheel"]) {
        return iCarouselTypeWheel;
    } else if([themeName isEqualToString:@"invertedWheel"]) {
        return iCarouselTypeInvertedWheel;
    } else if([themeName isEqualToString:@"coverFlow1"]) {
        return iCarouselTypeCoverFlow;
    } else if([themeName isEqualToString:@"coverFlow2"]) {
        return iCarouselTypeCoverFlow2;
    } else if([themeName isEqualToString:@"timeMachine"]) {
        return iCarouselTypeTimeMachine;
    } else if([themeName isEqualToString:@"invertedTimeMachine"]) {
        return iCarouselTypeInvertedTimeMachine;
    } else {
        return iCarouselTypeLinear;
    }
}

@end
