#import "UIImageView+CleverPush.h"

#import <objc/runtime.h>

static char kCPSessionDataTaskKey;

@implementation UIImageView (CleverPush)

- (void)setDataTask:(NSURLSessionDataTask*)dataTask {
    objc_setAssociatedObject(self, &kCPSessionDataTaskKey, dataTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURLSessionDataTask*)dataTask {
    return (NSURLSessionDataTask *)objc_getAssociatedObject(self, &kCPSessionDataTaskKey);
}

#pragma mark - Set image with URL
- (void)setImageWithURL:(NSURL*)imageURL {
    if (self.dataTask) {
        [self.dataTask cancel];
    }
    
    if (imageURL) {
        __weak typeof(self) weakSelf = self;
        self.dataTask = [[NSURLSession sharedSession] dataTaskWithURL:imageURL
                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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
