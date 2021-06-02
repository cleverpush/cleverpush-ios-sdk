#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CPUtils : NSObject

#pragma mark - Utilities singleton functions
+ (NSString*)downloadMedia:(NSString*)urlString;
+ (NSDictionary *)dictionaryWithPropertiesOfObject:(id)obj;
+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;
+ (NSString *)hexStringFromColor:(UIColor *)color;
+ (BOOL)fontFamilyExists:(NSString*)fontFamily;
+ (BOOL)isEmpty:(id)thing;

@end