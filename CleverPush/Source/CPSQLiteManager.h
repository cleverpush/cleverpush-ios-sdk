#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "CPAppBannerEventFilters.h"

@interface CPSQLiteManager : NSObject

@property (nonatomic) sqlite3 *database;

+ (CPSQLiteManager *)sharedManager;

- (NSString *)databasePath;
- (BOOL)databaseExists;
- (BOOL)createDatabase;
- (BOOL)databaseTableExists:(NSString *)tableName;
- (BOOL)createTable;
- (BOOL)insert:(NSString *)bannerID eventId:(NSString *)eventId property:(NSString *)property value:(NSString *)value relation:(NSString *)relation count:(NSNumber*)count createdAt:(NSString *)createdAt updatedAt:(NSString *)updatedAt fromValue:(NSString *)fromValue toValue:(NSString *)toValue;
- (BOOL)deleteDataBasedOnRetentionDays:(NSInteger)days;
- (NSArray<CPAppBannerEventFilters *> *)getAllRecords;

@end
