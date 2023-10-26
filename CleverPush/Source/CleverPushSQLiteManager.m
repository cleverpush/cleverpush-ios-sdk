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

#pragma mark - get the cleverpush database path
- (NSString *)cleverPushDatabasePath {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *databasePath = [documentsDir stringByAppendingPathComponent:@"CleverPushDatabase.sqlite"];
    return databasePath;
}

#pragma mark - to check if the database exists or not
- (BOOL)cleverPushDatabaseExists {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:[self cleverPushDatabasePath]];
}

#pragma mark - to create the database
- (BOOL)createCleverPushDatabase {
    if (sqlite3_open([[self cleverPushDatabasePath] UTF8String], &database) == SQLITE_OK) {
        sqlite3_close(database);
        return YES;
    } else {
        [CPLog debug:@"CleverPushSQLiteManager: createCleverPushDatabase: Error opening or creating the database."];
        return NO;
    }
}

#pragma mark - to check if the database table exists or not
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

#pragma mark - to create the database table if needed
- (BOOL)createCleverPushDatabaseTable {
    if (![self cleverPushDatabasetableExists:cleverPushDatabaseTable]) {
        if (sqlite3_open([[self cleverPushDatabasePath] UTF8String], &database) == SQLITE_OK) {
            NSString *createTableSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER PRIMARY KEY AUTOINCREMENT, bannerId TEXT, trackEventId TEXT, property TEXT, value TEXT, relation TEXT, count INTEGER DEFAULT 1, createdAt TEXT, updatedAt TEXT, fromValue TEXT, toValue TEXT);", cleverPushDatabaseTable];
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

#pragma mark - to insert the record in the database
- (BOOL)insert:(NSString *)bannerID trackEventID:(NSString *)trackEventID property:(NSString *)property value:(NSString *)value relation:(NSString *)relation count:(NSNumber *)count createdAt:(NSString *)createdAt updatedAt:(NSString *)updatedAt fromValue:(NSString *)fromValue toValue:(NSString *)toValue {

    if (![self cleverPushDatabasetableExists:cleverPushDatabaseTable]) {
        if (![self createCleverPushDatabaseTable]) {
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
    if (!createdAt) createdAt = @"";
    if (!updatedAt) updatedAt = @"";
    if (!fromValue) fromValue = @"";
    if (!toValue) toValue = @"";

    if (sqlite3_open([[self cleverPushDatabasePath] UTF8String], &database) == SQLITE_OK) {

        NSString *selectSQL = [NSString stringWithFormat:
                               @"SELECT count FROM %@ WHERE bannerId = ? AND trackEventId = ? AND property = ? AND value = ? AND relation = ?;",
                               cleverPushDatabaseTable];

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
                                       @"UPDATE %@ SET count = ?, updatedAt = ? "
                                       "WHERE bannerId = ? AND trackEventId = ? AND property = ? AND value = ? AND relation = ?;", cleverPushDatabaseTable];

                sqlite3_stmt *updateStatement;

                if (sqlite3_prepare_v2(database, [updateSQL UTF8String], -1, &updateStatement, nil) == SQLITE_OK) {
                    sqlite3_bind_int(updateStatement, 1, updatedCount);
                    sqlite3_bind_text(updateStatement, 2, [updatedAt UTF8String], -1, SQLITE_STATIC);
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
                               @"INSERT INTO %@ (bannerId, trackEventId, property, value, relation, count, createdAt, updatedAt, fromValue, toValue) "
                               "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);", cleverPushDatabaseTable];

        sqlite3_stmt *insertStatement;

        if (sqlite3_prepare_v2(database, [insertSQL UTF8String], -1, &insertStatement, nil) == SQLITE_OK) {
            sqlite3_bind_text(insertStatement, 1, [bannerID UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 2, [trackEventID UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 3, [property UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 4, [value UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 5, [relation UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_int(insertStatement, 6, 1);
            sqlite3_bind_text(insertStatement, 7, [createdAt UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 8, [updatedAt UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 9, [fromValue UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 10, [toValue UTF8String], -1, SQLITE_STATIC);

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

#pragma mark - to get all the recrods from database
- (NSArray<CPAppBannerEventFilters *> *)getcleverPushDatabaseAllRecords {
    NSMutableArray<CPAppBannerEventFilters *> *recordArray = [NSMutableArray array];

    if (![self cleverPushDatabasetableExists:cleverPushDatabaseTable]) {
        [CPLog debug:@"CleverPushSQLiteManager: getcleverPushDatabaseAllRecords: Table '%@' does not exist.", cleverPushDatabaseTable];
        return recordArray;
    }

    if (sqlite3_open([[self cleverPushDatabasePath] UTF8String], &database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@;", cleverPushDatabaseTable];
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                NSDictionary *recordDict = @{
                    @"banner" : (const char *)sqlite3_column_text(statement, 1) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 1)] : @"",
                    @"event": (const char *)sqlite3_column_text(statement, 2) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 2)] : @"",
                    @"property": (const char *)sqlite3_column_text(statement, 3) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 3)] : @"",
                    @"value": (const char *)sqlite3_column_text(statement, 4) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 4)] : @"",
                    @"relation": (const char *)sqlite3_column_text(statement, 5) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 5)] : @"",
                    @"count" : [NSString stringWithFormat:@"%d", sqlite3_column_int(statement, 6)] ?: @"",
                    @"createdAt": (const char *)sqlite3_column_text(statement, 7) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 7)] : @"",
                    @"updatedAt": (const char *)sqlite3_column_text(statement, 8) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 8)] : @"",
                    @"fromValue": (const char *)sqlite3_column_text(statement, 9) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 9)] : @"",
                    @"toValue": (const char *)sqlite3_column_text(statement, 10) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 10)] : @"",
                };
                CPAppBannerEventFilters *record = [[CPAppBannerEventFilters alloc] initWithJson:recordDict];
                [recordArray addObject:record];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    }
    return recordArray;
}

#pragma mark - to delete the records from certain past days
- (BOOL)deleteDataBasedOnRetentionDays:(NSInteger)days {
    if (sqlite3_open([[self cleverPushDatabasePath] UTF8String], &database) == SQLITE_OK) {
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970] - (days * 24 * 60 * 60);

        NSDate *dateToDelete = [NSDate dateWithTimeIntervalSince1970:timeInterval];
        NSString *deleteSQL = [NSString stringWithFormat:
                               @"DELETE FROM %@ WHERE createdAt <= ?;", cleverPushDatabaseTable];
        sqlite3_stmt *deleteStatement;

        if (sqlite3_prepare_v2(database, [deleteSQL UTF8String], -1, &deleteStatement, nil) == SQLITE_OK) {
            sqlite3_bind_double(deleteStatement, 1, [dateToDelete timeIntervalSince1970]);
            if (sqlite3_step(deleteStatement) == SQLITE_DONE) {
                sqlite3_finalize(deleteStatement);
                sqlite3_close(database);
                return YES;
            } else {
                [CPLog debug:@"CleverPushSQLiteManager: deleteDataBasedOnRetentionDays: Failed to execute the delete statement: %s", sqlite3_errmsg(database)];
            }
        } else {
            [CPLog debug:@"CleverPushSQLiteManager: deleteDataBasedOnRetentionDays: Failed to prepare the delete statement: %s", sqlite3_errmsg(database)];
        }
        sqlite3_close(database);
    } else {
        [CPLog debug:@"CleverPushSQLiteManager: deleteDataBasedOnRetentionDays: Failed to open the database: %s", sqlite3_errmsg(database)];
    }
    return NO;
}

@end
