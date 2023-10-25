#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface CleverPushSQLiteManager : NSObject

@property (nonatomic) sqlite3 *database;

+ (CleverPushSQLiteManager *)sharedManager;

- (NSString *)cleverPushDatabasePath;
- (BOOL)cleverPushDatabaseExists;
- (BOOL)createCleverPushDatabase;
- (BOOL)cleverPushDatabasetableExists:(NSString *)tableName;
- (BOOL)cleverPushDatabaseCreateTableIfNeeded;
- (BOOL)insertRecordWithBannerID:(NSString *)bannerID
                    trackEventID:(NSString *)trackEventID
                        property:(NSString *)property
                           value:(NSString *)value
                        relation:(NSString *)relation
                           count:(NSNumber*)count
                 createdDateTime:(NSString *)createdDateTime
                 updatedDateTime:(NSString *)updatedDateTime
                      from_value:(NSString *)from_value
                        to_value:(NSString *)to_value;
- (void)cleverPushDatabaseGetAllRecords:(void (^)(NSArray *records))callback;
- (BOOL)deleteRecordsOlderThanDays:(NSInteger)days;

@end
