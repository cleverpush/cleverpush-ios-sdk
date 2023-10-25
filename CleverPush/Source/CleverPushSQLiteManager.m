#import "CleverPushSQLiteManager.h"
#import "CleverPush.h"
#import "CPLog.h"

@implementation CleverPushSQLiteManager

static CleverPushSQLiteManager *sharedInstance = nil;
NSString *cleverPushDatabaseTable = @"TableBannerTrackEvent";
sqlite3 *database;

+ (CleverPushSQLiteManager *)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - cleverPush database methods for app banners eventFilters
- (NSString *)cleverPushDatabasePath {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *databasePath = [documentsDir stringByAppendingPathComponent:@"CleverPushDatabase.sqlite"];
    return databasePath;
}

- (BOOL)cleverPushDatabaseExists {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:[self cleverPushDatabasePath]];
}

- (BOOL)createCleverPushDatabase {
    if (sqlite3_open([[self cleverPushDatabasePath] UTF8String], &database) == SQLITE_OK) {
        sqlite3_close(database);
        return YES;
    } else {
        [CPLog debug:@"CleverPushSQLiteManager: createCleverPushDatabase: Error opening or creating the database."];
        return NO;
    }
}

- (BOOL)cleverPushDatabasetableExists:(NSString *)tableName {
    if (sqlite3_open([[self cleverPushDatabasePath] UTF8String], &database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT name FROM sqlite_master WHERE type='table' AND name='%@';", tableName];
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                sqlite3_finalize(statement);
                sqlite3_close(database);
                return YES;
            }
        }

        sqlite3_finalize(statement);
        sqlite3_close(database);
    }

    return NO;
}

- (BOOL)cleverPushDatabaseCreateTableIfNeeded {
    if (![self cleverPushDatabasetableExists:cleverPushDatabaseTable]) {
        if (sqlite3_open([[self cleverPushDatabasePath] UTF8String], &database) == SQLITE_OK) {
            NSString *createTableSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER PRIMARY KEY AUTOINCREMENT, banner_id TEXT, track_event_id TEXT, property TEXT, value TEXT, relation TEXT, count INTEGER DEFAULT 1, created_date_time TEXT, updated_date_time TEXT, from_value TEXT, to_value TEXT);", cleverPushDatabaseTable];
            char *errMsg;

            if (sqlite3_exec(database, [createTableSQL UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
                [CPLog debug:@"CleverPushSQLiteManager: cleverPushDatabaseCreateTableIfNeeded: Error creating table: %s", errMsg];
                sqlite3_free(errMsg);
                sqlite3_close(database);
                return NO;
            }

            sqlite3_close(database);
            return YES;
        }
    }
    return YES;
}

- (BOOL)insertRecordWithBannerID:(NSString *)bannerID trackEventID:(NSString *)trackEventID property:(NSString *)property value:(NSString *)value relation:(NSString *)relation count:(NSNumber *)count createdDateTime:(NSString *)createdDateTime updatedDateTime:(NSString *)updatedDateTime from_value:(NSString *)from_value to_value:(NSString *)to_value {

    if (![self cleverPushDatabasetableExists:cleverPushDatabaseTable]) {
        if (![self cleverPushDatabaseCreateTableIfNeeded]) {
            return NO;
        }
    }

    if (!count) {
        count = @(0);
    }

    if (!bannerID) bannerID = @"";
    if (!trackEventID) trackEventID = @"";
    if (!property) property = @"";
    if (!value) value = @"";
    if (!relation) relation = @"";
    if (!createdDateTime) createdDateTime = @"";
    if (!updatedDateTime) updatedDateTime = @"";
    if (!from_value) from_value = @"";
    if (!to_value) to_value = @"";

    if (sqlite3_open([[self cleverPushDatabasePath] UTF8String], &database) == SQLITE_OK) {

        NSString *selectSQL = [NSString stringWithFormat:
                               @"SELECT count FROM %@ WHERE banner_id = ? AND track_event_id = ? AND property = ? AND value = ? AND relation = ?;", cleverPushDatabaseTable];
        sqlite3_stmt *selectStatement;

        if (sqlite3_prepare_v2(database, [selectSQL UTF8String], -1, &selectStatement, nil) == SQLITE_OK) {
            sqlite3_bind_text(selectStatement, 1, [bannerID UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 2, [trackEventID UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 3, [property UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 4, [value UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 5, [relation UTF8String], -1, SQLITE_STATIC);

            if (sqlite3_step(selectStatement) == SQLITE_ROW) {
                int currentCount = sqlite3_column_int(selectStatement, 0);
                int updatedCount = currentCount + 1;
                sqlite3_finalize(selectStatement);

                NSString *updateSQL = [NSString stringWithFormat:
                                       @"UPDATE %@ SET count = ?, updated_date_time = ? "
                                       "WHERE banner_id = ? AND track_event_id = ? AND property = ? AND value = ? AND relation = ?;", cleverPushDatabaseTable];

                sqlite3_stmt *updateStatement;

                if (sqlite3_prepare_v2(database, [updateSQL UTF8String], -1, &updateStatement, nil) == SQLITE_OK) {
                    sqlite3_bind_int(updateStatement, 1, updatedCount);
                    sqlite3_bind_text(updateStatement, 2, [updatedDateTime UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(updateStatement, 3, [bannerID UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(updateStatement, 4, [trackEventID UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(updateStatement, 5, [property UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(updateStatement, 6, [value UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(updateStatement, 7, [relation UTF8String], -1, SQLITE_STATIC);


                    if (sqlite3_step(updateStatement) == SQLITE_DONE) {
                        sqlite3_finalize(updateStatement);
                        sqlite3_close(database);
                        return YES;
                    }
                }
            }
        }

        NSString *insertSQL = [NSString stringWithFormat:
                               @"INSERT INTO %@ (banner_id, track_event_id, property, value, relation, count, created_date_time, updated_date_time, from_value, to_value) "
                               "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);", cleverPushDatabaseTable];

        sqlite3_stmt *insertStatement;


        if (sqlite3_prepare_v2(database, [insertSQL UTF8String], -1, &insertStatement, nil) == SQLITE_OK) {
            sqlite3_bind_text(insertStatement, 1, [bannerID UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 2, [trackEventID UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 3, [property UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 4, [value UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 5, [relation UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_int(insertStatement, 6, 1);
            sqlite3_bind_text(insertStatement, 7, [createdDateTime UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 8, [updatedDateTime UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 9, [from_value UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 10, [to_value UTF8String], -1, SQLITE_STATIC);

            if (sqlite3_step(insertStatement) == SQLITE_DONE) {
                sqlite3_finalize(insertStatement);
                sqlite3_close(database);
                return YES;
            }
        }

        sqlite3_close(database);
    }

    return NO;
}

- (void)cleverPushDatabaseGetAllRecords:(void (^)(NSArray *records))callback {

    if (![self cleverPushDatabasetableExists:cleverPushDatabaseTable]) {
        [CPLog debug:@"CleverPushSQLiteManager: cleverPushDatabaseGetAllRecords: Table '%@' does not exist.", cleverPushDatabaseTable];
        if (callback) {
            callback(@[]);
        }
        return;
    }

    NSMutableArray *recordArray = [NSMutableArray array];

    if (sqlite3_open([[self cleverPushDatabasePath] UTF8String], &database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@;", cleverPushDatabaseTable];
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                int recordID = sqlite3_column_int(statement, 0);
                const char *bannerID = (const char *)sqlite3_column_text(statement, 1);
                const char *trackEventID = (const char *)sqlite3_column_text(statement, 2);
                const char *property = (const char *)sqlite3_column_text(statement, 3);
                const char *value = (const char *)sqlite3_column_text(statement, 4);
                const char *relation = (const char *)sqlite3_column_text(statement, 5);
                int count = sqlite3_column_int(statement, 6);
                const char *createdDateTime = (const char *)sqlite3_column_text(statement, 7);
                const char *updatedDateTime = (const char *)sqlite3_column_text(statement, 8);
                const char *from_value = (const char *)sqlite3_column_text(statement, 9);
                const char *to_value = (const char *)sqlite3_column_text(statement, 10);

                NSString *bannerIDString = [NSString stringWithUTF8String:bannerID];
                NSString *trackEventIDString = [NSString stringWithUTF8String:trackEventID];
                NSString *propertyString = [NSString stringWithUTF8String:property];
                NSString *valueString = [NSString stringWithUTF8String:value];
                NSString *relationString = [NSString stringWithUTF8String:relation];
                NSString *createdDateTimeString = [NSString stringWithUTF8String:createdDateTime];
                NSString *updatedDateTimeString = [NSString stringWithUTF8String:updatedDateTime];
                NSString *from_valueString = [NSString stringWithUTF8String:from_value];
                NSString *to_valueString = [NSString stringWithUTF8String:to_value];

                NSDictionary *record = @{
                    @"id": @(recordID),
                    @"banner_id": bannerIDString,
                    @"track_event_id": trackEventIDString,
                    @"property": propertyString,
                    @"value": valueString,
                    @"relation": relationString,
                    @"count": @(count),
                    @"created_date_time": createdDateTimeString,
                    @"updated_date_time": updatedDateTimeString,
                    @"from_value": from_valueString,
                    @"to_value": to_valueString
                };
                [recordArray addObject:record];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    }

    if (callback) {
        callback(recordArray);
    }
}

- (BOOL)deleteRecordsOlderThanDays:(NSInteger)days {
    if (sqlite3_open([[self cleverPushDatabasePath] UTF8String], &database) == SQLITE_OK) {
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970] - (days * 24 * 60 * 60);
        NSDate *dateToDelete = [NSDate dateWithTimeIntervalSince1970:timeInterval];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSString *dateToDeleteString = [dateFormatter stringFromDate:dateToDelete];
        NSString *deleteSQL = [NSString stringWithFormat:
                               @"DELETE FROM %@ WHERE created_date_time <= ?;", cleverPushDatabaseTable];
        sqlite3_stmt *deleteStatement;

        if (sqlite3_prepare_v2(database, [deleteSQL UTF8String], -1, &deleteStatement, nil) == SQLITE_OK) {
            sqlite3_bind_text(deleteStatement, 1, [dateToDeleteString UTF8String], -1, SQLITE_STATIC);
            if (sqlite3_step(deleteStatement) == SQLITE_DONE) {
                sqlite3_finalize(deleteStatement);
                sqlite3_close(database);
                return YES;
            }
        }
        sqlite3_close(database);
    }
    return NO;
}

@end
