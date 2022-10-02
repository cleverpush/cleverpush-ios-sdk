#import <UIKit/UIKit.h>

@interface UIColor(HexString)

#pragma mark - Initialised UIColor by hex string
+ (UIColor *) colorWithHexString: (NSString *) hexString;

#pragma mark - Initialised UIColor at specific range of the string
+ (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length;

@end
