#import "CPSQLiteManager.h"
#import "CleverPush.h"
#import "CPLog.h"

@implementation CPSQLiteManager

static CPSQLiteManager *sharedInstance = nil;
NSString *databaseTable = @"cleverpush_table_banner_track_event";
sqlite3 *database;

+ (CPSQLiteManager *)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - get the database path
- (NSString *)databasePath {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *databasePath = [documentsDir stringByAppendingPathComponent:@"CleverPushDatabase.sqlite"];
    return databasePath;
}

#pragma mark - to check if the database exists or not
- (BOOL)databaseExists {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:[self databasePath]];
}

#pragma mark - to create the database
- (BOOL)createDatabase {
    if (sqlite3_open([[self databasePath] UTF8String], &database) == SQLITE_OK) {
        sqlite3_close(database);
        return YES;
    } else {
        [CPLog debug:@"CPSQLiteManager: createDatabase: Error opening or creating the database."];
        return NO;
    }
}

#pragma mark - to check if the database table exists or not
- (BOOL)databaseTableExists:(NSString *)tableName {
    if (sqlite3_open([[self databasePath] UTF8String], &database) == SQLITE_OK) {
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
- (BOOL)createTable {
    if (![self databaseTableExists:databaseTable]) {
        if (sqlite3_open([[self databasePath] UTF8String], &database) == SQLITE_OK) {
            NSString *createTableSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER PRIMARY KEY AUTOINCREMENT, bannerId TEXT, eventId TEXT, property TEXT, value TEXT, relation TEXT, count INTEGER DEFAULT 1, createdAt TEXT, updatedAt TEXT, fromValue TEXT, toValue TEXT);", databaseTable];
            char *errMsg;

            if (sqlite3_exec(database, [createTableSQL UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
                [CPLog debug:@"CPSQLiteManager: createTable: Error creating table: %s", errMsg];
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
- (BOOL)insert:(NSString *)bannerID eventId:(NSString *)eventId property:(NSString *)property value:(NSString *)value relation:(NSString *)relation count:(NSNumber *)count createdAt:(NSString *)createdAt updatedAt:(NSString *)updatedAt fromValue:(NSString *)fromValue toValue:(NSString *)toValue {

    if (![self databaseTableExists:databaseTable]) {
        if (![self createTable]) {
            return NO;
        }
    }

    if (!count) {
        count = @(0);
    }
    if (!bannerID) bannerID = @"";
    if (!eventId) eventId = @"";
    if (!property) property = @"";
    if (!value) value = @"";
    if (!relation) relation = @"";
    if (!createdAt) createdAt = @"";
    if (!updatedAt) updatedAt = @"";
    if (!fromValue) fromValue = @"";
    if (!toValue) toValue = @"";

    if (sqlite3_open([[self databasePath] UTF8String], &database) == SQLITE_OK) {

        NSString *selectSQL = [NSString stringWithFormat:
                               @"SELECT count FROM %@ WHERE bannerId = ? AND eventId = ? AND property = ? AND value = ? AND relation = ?;",
                               databaseTable];
        sqlite3_stmt *selectStatement;

        if (sqlite3_prepare_v2(database, [selectSQL UTF8String], -1, &selectStatement, nil) == SQLITE_OK) {
            sqlite3_bind_text(selectStatement, 1, [bannerID UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 2, [eventId UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 3, [property UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 4, [value UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 5, [relation UTF8String], -1, SQLITE_STATIC);

            if (sqlite3_step(selectStatement) == SQLITE_ROW) {
                int currentCount = sqlite3_column_int(selectStatement, 0);
                int updatedCount = currentCount + 1;
                sqlite3_finalize(selectStatement);

                NSString *updateSQL = [NSString stringWithFormat:
                                       @"UPDATE %@ SET count = ?, updatedAt = ? "
                                       "WHERE bannerId = ? AND eventId = ? AND property = ? AND value = ? AND relation = ?;", databaseTable];
                sqlite3_stmt *updateStatement;

                if (sqlite3_prepare_v2(database, [updateSQL UTF8String], -1, &updateStatement, nil) == SQLITE_OK) {
                    sqlite3_bind_int(updateStatement, 1, updatedCount);
                    sqlite3_bind_text(updateStatement, 2, [updatedAt UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(updateStatement, 3, [bannerID UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(updateStatement, 4, [eventId UTF8String], -1, SQLITE_STATIC);
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
                               @"INSERT INTO %@ (bannerId, eventId, property, value, relation, count, createdAt, updatedAt, fromValue, toValue) "
                               "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);", databaseTable];
        sqlite3_stmt *insertStatement;

        if (sqlite3_prepare_v2(database, [insertSQL UTF8String], -1, &insertStatement, nil) == SQLITE_OK) {
            sqlite3_bind_text(insertStatement, 1, [bannerID UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(insertStatement, 2, [eventId UTF8String], -1, SQLITE_STATIC);
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
- (NSArray<CPAppBannerEventFilters *> *)getAllRecords {
    NSMutableArray<CPAppBannerEventFilters *> *recordArray = [NSMutableArray array];

    if (![self databaseTableExists:databaseTable]) {
        [CPLog debug:@"CPSQLiteManager: getAllRecords: Table '%@' does not exist.", databaseTable];
        return recordArray;
    }

    if (sqlite3_open([[self databasePath] UTF8String], &database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@;", databaseTable];
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
    if (sqlite3_open([[self databasePath] UTF8String], &database) == SQLITE_OK) {
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970] - (days * 24 * 60 * 60);

        NSDate *dateToDelete = [NSDate dateWithTimeIntervalSince1970:timeInterval];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *dateToDeleteString = [dateFormatter stringFromDate:dateToDelete];
        NSString *deleteSQL = [NSString stringWithFormat:
                               @"DELETE FROM %@ WHERE createdAt <= ?;", databaseTable];
        sqlite3_stmt *deleteStatement;

        if (sqlite3_prepare_v2(database, [deleteSQL UTF8String], -1, &deleteStatement, nil) == SQLITE_OK) {
            sqlite3_bind_text(deleteStatement, 1, [dateToDeleteString UTF8String], -1, SQLITE_STATIC);
            if (sqlite3_step(deleteStatement) == SQLITE_DONE) {
                sqlite3_finalize(deleteStatement);
                sqlite3_close(database);
                return YES;
            } else {
                [CPLog debug:@"CPSQLiteManager: deleteDataBasedOnRetentionDays: Failed to execute the delete statement: %s", sqlite3_errmsg(database)];
            }
        } else {
            [CPLog debug:@"CPSQLiteManager: deleteDataBasedOnRetentionDays: Failed to prepare the delete statement: %s", sqlite3_errmsg(database)];
        }
        sqlite3_close(database);
    } else {
        [CPLog debug:@"CPSQLiteManager: deleteDataBasedOnRetentionDays: Failed to open the database: %s", sqlite3_errmsg(database)];
    }
    return NO;
}

@end
