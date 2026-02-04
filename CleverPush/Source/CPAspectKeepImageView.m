#import "CPAspectKeepImageView.h"
#import "CPLog.h"
#import "CPUtils.h"

#import <objc/runtime.h>
#import <MobileCoreServices/MobileCoreServices.h>

static char kCPSessionDataTaskKey;
static char kCPImageURLKey;

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

- (void)setCurrentImageURL:(NSString *)urlString {
    objc_setAssociatedObject(self, &kCPImageURLKey, urlString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)currentImageURL {
    return (NSString *)objc_getAssociatedObject(self, &kCPImageURLKey);
}

#pragma mark - set image with URL with callback
- (void)setImageWithURL:(NSURL*)imageURL callback:(void(^)(BOOL))callback {
    if (self.dataTask) {
        [self.dataTask cancel];
    }
    
    if (imageURL) {
        NSString *urlString = imageURL.absoluteString;
        [self setCurrentImageURL:urlString];
        __weak typeof(self) weakSelf = self;
        self.dataTask = [[NSURLSession sharedSession] dataTaskWithURL:imageURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (![strongSelf.currentImageURL isEqualToString:urlString]) {
                return;
            }
            if (error) {
                if (error.code != NSURLErrorCancelled) {
                } else {
                    return;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback) {
                        callback(false);
                    }
                });
            }
            else {
                NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
                if (httpResponse.statusCode == 200) {
                    UIImage *image = [strongSelf imageWithData:data];
                    if (image) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            strongSelf.image = image;
                            [strongSelf updateAspectConstraint];
                            [[CPUtils sharedImageCache] setObject:image forKey:imageURL.absoluteString];
                            if (callback) {
                                callback(true);
                            }
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (callback) {
                                callback(false);
                            }
                        });
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callback) {
                            callback(false);
                        }
                    });
                }
            }
        }];
        [self.dataTask resume];
    } else {
        if (callback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(false);
            });
        }
    }
}

#pragma mark - set image with URL
- (void)setImageWithURL:(NSURL*)imageURL {
    if (self.dataTask) {
        [self.dataTask cancel];
    }
    
    if (imageURL) {
        NSString *urlString = imageURL.absoluteString;
        [self setCurrentImageURL:urlString];
        __weak typeof(self) weakSelf = self;
        self.dataTask = [[NSURLSession sharedSession] dataTaskWithURL:imageURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (![strongSelf.currentImageURL isEqualToString:urlString]) {
                return;
            }
            if (error) {
                if (error.code != NSURLErrorCancelled) {
                } else {
                    return;
                }
            }
            else {
                NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
                if (httpResponse.statusCode == 200) {
                    UIImage *image = [strongSelf imageWithData:data];
                    if (image) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            strongSelf.image = image;
                            [strongSelf updateAspectConstraint];
                            [[CPUtils sharedImageCache] setObject:image forKey:imageURL.absoluteString];
                        });
                    } else {
                    }
                } else {
                }
            }
        }];
        [self.dataTask resume];
    }
    return;
}

#pragma mark - Image Handling
- (UIImage *)imageWithData:(NSData *)data {
    if (!data) {
        return nil;
    }

    if ([self isGIFData:data]) {
        UIImage *gifImage = [self createGIFImageWithData:data];
        return gifImage;
    }

    UIImage *image = [UIImage imageWithData:data];
    return image;
}

- (BOOL)isGIFData:(NSData *)data {
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (source) {
        CFStringRef type = CGImageSourceGetType(source);
        BOOL isGIF = UTTypeConformsTo(type, kUTTypeGIF);
        CFRelease(source);
        return isGIF;
    }
    return NO;
}

- (UIImage *)createGIFImageWithData:(NSData *)data {
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);

    if (imageSource) {
        size_t frameCount = CGImageSourceGetCount(imageSource);
        NSMutableArray<UIImage *> *frames = [NSMutableArray arrayWithCapacity:frameCount];
        NSTimeInterval totalDuration = 0.0;

        for (size_t i = 0; i < frameCount; i++) {
            CGImageRef frameImageRef = CGImageSourceCreateImageAtIndex(imageSource, i, NULL);
            if (frameImageRef) {
                UIImage *frameImage = [UIImage imageWithCGImage:frameImageRef];
                [frames addObject:frameImage];

                NSDictionary *frameProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil);
                NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
                NSNumber *delayTime = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
                totalDuration += [delayTime doubleValue];
                delayTime = @(MAX([delayTime doubleValue] * 0.1, 0.01));

                CGImageRelease(frameImageRef);
            }
        }

        UIImage *gifImage = [UIImage animatedImageWithImages:frames duration:totalDuration];
        CFRelease(imageSource);
        return gifImage;
    }
    return nil;
}

@end
