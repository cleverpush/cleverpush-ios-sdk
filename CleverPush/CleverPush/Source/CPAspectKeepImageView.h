#import <UIKit/UIKit.h>

@interface CPAspectKeepImageView : UIImageView

#pragma mark - Class Methods
- (void)setImageWithURL:(NSURL*_Nonnull)imageURL;
- (instancetype _Nonnull )initWithImage:(nullable UIImage *)image;
- (instancetype _Nonnull )initWithImage:(nullable UIImage *)image highlightedImage:(nullable UIImage *)highlightedImage;

@end
