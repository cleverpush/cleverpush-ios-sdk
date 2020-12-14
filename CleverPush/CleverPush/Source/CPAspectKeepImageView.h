#import <UIKit/UIKit.h>

@interface CPAspectKeepImageView : UIImageView

- (void)setImageWithURL:(NSURL*)imageURL;
- (instancetype)initWithImage:(nullable UIImage *)image;
- (instancetype)initWithImage:(nullable UIImage *)image highlightedImage:(nullable UIImage *)highlightedImage;

@end
