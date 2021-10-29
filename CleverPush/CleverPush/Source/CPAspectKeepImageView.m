#import "CPAspectKeepImageView.h"

#import <objc/runtime.h>

static char kCPSessionDataTaskKey;

@implementation CPAspectKeepImageView
{
    NSLayoutConstraint *_aspectContraint;
}

#pragma mark - Initialise with UIImage
- (instancetype)initWithImage:(nullable UIImage *)image
{
    self = [super initWithImage:image];
    [self initInternal];
    return self;
}

#pragma mark - Initialise with UIImage and Highlighted UIImage
- (instancetype)initWithImage:(nullable UIImage *)image highlightedImage:(nullable UIImage *)highlightedImage
{
    self = [super initWithImage:image highlightedImage:highlightedImage];
    [self initInternal];
    return self;
}

#pragma mark - set the contentMode of the UIImageView
- (void)initInternal
{
    self.contentMode = UIViewContentModeScaleAspectFit;
    [self updateAspectConstraint];
}

#pragma mark - set the image
- (void)setImage:(UIImage *)image
{
    [super setImage:image];
    [self updateAspectConstraint];
}

#pragma mark - Update constraints based on the aspect ratio of the Image
- (void)updateAspectConstraint
{
    CGSize imageSize = self.image.size;
    CGFloat aspectRatio = imageSize.height > 0.0f
    ? imageSize.width / imageSize.height
    : 0.0f;
    if (_aspectContraint.multiplier != aspectRatio)
    {
        [self removeConstraint:_aspectContraint];
        
        _aspectContraint =
        [NSLayoutConstraint constraintWithItem:self
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self
                                     attribute:NSLayoutAttributeHeight
                                    multiplier:aspectRatio
                                      constant:0.f];
        
        _aspectContraint.priority = UILayoutPriorityRequired;
        
        [self addConstraint:_aspectContraint];
    }
}

#pragma mark - set data task
- (void)setDataTask:(NSURLSessionDataTask*)dataTask {
    objc_setAssociatedObject(self, &kCPSessionDataTaskKey, dataTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURLSessionDataTask*)dataTask {
    return (NSURLSessionDataTask *)objc_getAssociatedObject(self, &kCPSessionDataTaskKey);
}

#pragma mark - set image with URL with callback
- (void)setImageWithURL:(NSURL*)imageURL callback:(void(^)(BOOL))callback {
    if (self.dataTask) {
        [self.dataTask cancel];
    }
    
    if (imageURL) {
        __weak typeof(self) weakSelf = self;
        self.dataTask = [[NSURLSession sharedSession] dataTaskWithURL:imageURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (error) {
                NSLog(@"ERROR: %@", error);
                callback(false);
            }
            else {
                NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
                if (200 == httpResponse.statusCode) {
                    UIImage * image = [UIImage imageWithData:data];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        strongSelf.image = image;
                        [strongSelf updateAspectConstraint];
                        callback(true);
                    });
                } else {
                    NSLog(@"Couldn't load image at URL: %@", imageURL);
                    NSLog(@"HTTP %ld", (long)httpResponse.statusCode);
                    callback(false);
                }
            }
        }];
        [self.dataTask resume];
    }
    callback(false);

    return;
}

#pragma mark - set image with URL
- (void)setImageWithURL:(NSURL*)imageURL {
    if (self.dataTask) {
        [self.dataTask cancel];
    }
    
    if (imageURL) {
        __weak typeof(self) weakSelf = self;
        self.dataTask = [[NSURLSession sharedSession] dataTaskWithURL:imageURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (error) {
                NSLog(@"ERROR: %@", error);
            }
            else {
                NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
                if (200 == httpResponse.statusCode) {
                    UIImage * image = [UIImage imageWithData:data];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        strongSelf.image = image;
                        [strongSelf updateAspectConstraint];
                    });
                } else {
                    NSLog(@"Couldn't load image at URL: %@", imageURL);
                    NSLog(@"HTTP %ld", (long)httpResponse.statusCode);
                }
            }
        }];
        [self.dataTask resume];
    }
    return;
}

@end
