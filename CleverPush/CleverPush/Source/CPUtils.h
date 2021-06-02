#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CPUtils : NSObject

#pragma mark - Utilities singleton functions
+ (NSString*)downloadMedia:(NSString*)urlString;
+ (NSDictionary *)dictionaryWithPropertiesOfObject:(id)obj;
+ (BOOL)isPortrait;
+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;
+ (NSString *)hexStringFromColor:(UIColor *)color;

@end
