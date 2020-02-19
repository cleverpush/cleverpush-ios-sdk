#import <Foundation/Foundation.h>

@interface DirectDownloadDelegate : NSObject <NSURLSessionDataDelegate> {
    NSError* error;
    NSURLResponse* response;
    BOOL done;
    NSFileHandle* outputHandle;
}
@property (readonly, getter=isDone) BOOL done;
@property (readonly) NSError* error;
@property (readonly) NSURLResponse* response;

@end

@interface NSURLSession (DirectDownload)
+ (NSString *)downloadItemAtURL:(NSURL *)url toFile:(NSString *)localPath error:(NSError **)error;
@end
