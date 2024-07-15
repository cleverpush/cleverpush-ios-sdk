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
- (BOOL)insert:(NSString *)bannerId eventId:(NSString *)eventId property:(NSString *)property value:(NSString *)value relation:(NSString *)relation count:(NSNumber*)count createdDateTime:(NSString *)createdDateTime updatedDateTime:(NSString *)updatedDateTime fromValue:(NSString *)fromValue toValue:(NSString *)toValue;
- (BOOL)insert:(NSString *)bannerId eventId:(NSString *)eventId property:(NSString *)property value:(NSString *)value relation:(NSString *)relation count:(NSNumber *)count createdDateTime:(NSString *)createdDateTime updatedDateTime:(NSString *)updatedDateTime fromValue:(NSString *)fromValue toValue:(NSString *)toValue eventProperty:(NSString *)eventProperty eventValue:(NSString *)eventValue eventRelation:(NSString *)eventRelation; 
- (BOOL)updateCountForEventWithId:(NSString *)eventId eventValue:(NSString *)eventValue eventProperty:(NSString *)eventProperty updatedDateTime:(NSString *)updatedDateTime;
- (NSArray<CPAppBannerEventFilters *> *)getRecordsForEvent:(NSString *)bannerId eventId:(NSString *)eventId property:(NSString *)property value:(NSString *)value relation:(NSString *)relation fromValue:(NSString *)fromValue toValue:(NSString *)toValue eventProperty:(NSString *)eventProperty eventValue:(NSString *)eventValue eventRelation:(NSString *)eventRelation;
- (BOOL)deleteDataBasedOnRetentionDays:(NSInteger)days;
- (NSArray<CPAppBannerEventFilters *> *)getAllRecords;

@end
