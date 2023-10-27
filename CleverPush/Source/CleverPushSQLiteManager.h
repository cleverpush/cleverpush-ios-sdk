#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "CPAppBannerEventFilters.h"

@interface CleverPushSQLiteManager : NSObject

@property (nonatomic) sqlite3 *database;

+ (CleverPushSQLiteManager *)sharedManager;

- (NSString *)cleverPushDatabasePath;
- (BOOL)cleverPushDatabaseExists;
- (BOOL)createCleverPushDatabase;
- (BOOL)cleverPushDatabasetableExists:(NSString *)tableName;
- (BOOL)createCleverPushDatabaseTable;
- (BOOL)insert:(NSString *)bannerID trackEventID:(NSString *)trackEventID property:(NSString *)property value:(NSString *)value relation:(NSString *)relation count:(NSNumber*)count createdAt:(NSString *)createdAt updatedAt:(NSString *)updatedAt fromValue:(NSString *)fromValue toValue:(NSString *)toValue;
- (BOOL)deleteDataBasedOnRetentionDays:(NSInteger)days;
- (NSArray<CPAppBannerEventFilters *> *)getcleverPushDatabaseAllRecords;

@end
