#import <Foundation/Foundation.h>
#import "CPUtils.h"

@interface CPChannelTag : NSObject

#pragma mark - Class Variables
@property (readonly, nullable) NSString *id;
@property (readonly, nullable) NSString *name;
@property (readonly, nullable) NSString *autoAssignPath;
@property (readonly, nullable) NSString *autoAssignFunction;
@property (readonly, nullable) NSString *autoAssignSelector;

@property (readonly, nullable) NSNumber* autoAssignVisits;
@property (readonly, nullable) NSNumber* autoAssignSessions;
@property (readonly, nullable) NSNumber* autoAssignSeconds;
@property (readonly, nullable) NSNumber* autoAssignDays;

@property (readonly, nullable) NSDate *createdAt;

#pragma mark - Class Methods
+ (instancetype _Nonnull)initWithJson:(nonnull NSDictionary*)json;
- (void)parseJson:(nonnull NSDictionary*)json;

@end
