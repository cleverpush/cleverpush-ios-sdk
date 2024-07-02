#import "CPSQLiteManager.h"
#import "CleverPush.h"
#import "CPLog.h"

@implementation CPSQLiteManager {
    NSRecursiveLock *_databaseLock;
}

static CPSQLiteManager *sharedInstance = nil;
NSString *databaseTable = @"cleverpush_tracked_events";
sqlite3 *database;

+ (CPSQLiteManager *)sharedManager {
    static dispatch_once_t onceToken;
    static CPSQLiteManager *sharedInstance = nil;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        [sharedInstance updateDatabaseSchemaIfNeeded];
    });

    return sharedInstance;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _databaseLock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

#pragma mark - to get the database path
- (NSString *)databasePath {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *databasePath = [documentsDir stringByAppendingPathComponent:@"CleverPushDatabase.sqlite"];
    return databasePath;
}

#pragma mark - to check if the database exists or not
- (BOOL)databaseExists {
    [_databaseLock lock];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exists = [fileManager fileExistsAtPath:[self databasePath]];

    [_databaseLock unlock];
    return exists;
}

#pragma mark - to create the database
- (BOOL)createDatabase {
    [_databaseLock lock];
    BOOL success = NO;

    if (sqlite3_open([[self databasePath] UTF8String], &database) == SQLITE_OK) {
        sqlite3_close(database);
        success = YES;
    } else {
        [CPLog debug:@"CPSQLiteManager: createDatabase: Error opening or creating the database."];
    }

    [_databaseLock unlock];
    return success;
}

#pragma mark - to check if the database table exists or not
- (BOOL)databaseTableExists:(NSString *)tableName {
    [_databaseLock lock];
    BOOL tableExists = NO;

    if (sqlite3_open([[self databasePath] UTF8String], &database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT name FROM sqlite_master WHERE type='table' AND name='%@';", tableName];
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                tableExists = YES;
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(database);
    }

    [_databaseLock unlock];
    return tableExists;
}

#pragma mark - to create the database table if needed
- (BOOL)createTable {
    [_databaseLock lock];
    BOOL success = YES;

    if (![self databaseTableExists:databaseTable]) {
        if (sqlite3_open([[self databasePath] UTF8String], &database) == SQLITE_OK) {
            NSString *createTableSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER PRIMARY KEY AUTOINCREMENT, bannerId TEXT, eventId TEXT, property TEXT, value TEXT, relation TEXT, count INTEGER DEFAULT 1, createdDateTime TEXT, updatedDateTime TEXT, fromValue TEXT, toValue TEXT, eventProperty TEXT, eventValue TEXT, eventRelation TEXT);", databaseTable];
            char *errMsg;

            if (sqlite3_exec(database, [createTableSQL UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
                [CPLog debug:@"CPSQLiteManager: createTable: Error creating table: %s", errMsg];
                sqlite3_free(errMsg);
                success = NO;
            }

            sqlite3_close(database);
        }
    }

    [_databaseLock unlock];
    return success;
}

#pragma mark - to update the database schema if needed
- (void)updateDatabaseSchemaIfNeeded {
    [_databaseLock lock];
    if (sqlite3_open([[self databasePath] UTF8String], &database) == SQLITE_OK) {
        NSArray *newColumns = @[@"eventProperty", @"eventValue", @"eventRelation"];
        for (NSString *column in newColumns) {
            NSString *checkColumnSQL = [NSString stringWithFormat:@"PRAGMA table_info(%@);", databaseTable];
            sqlite3_stmt *statement;
            BOOL columnExists = NO;

            if (sqlite3_prepare_v2(database, [checkColumnSQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    NSString *existingColumnName = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 1)];
                    if ([existingColumnName isEqualToString:column]) {
                        columnExists = YES;
                        break;
                    }
                }
            }
            sqlite3_finalize(statement);

            if (!columnExists) {
                NSString *addColumnSQL = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ TEXT;", databaseTable, column];
                char *errMsg;
                if (sqlite3_exec(database, [addColumnSQL UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
                    sqlite3_free(errMsg);
                }
            }
        }
        sqlite3_close(database);
    }
    [_databaseLock unlock];
}

#pragma mark - to insert the record in the database
- (BOOL)insert:(NSString *)bannerId eventId:(NSString *)eventId property:(NSString *)property value:(NSString *)value relation:(NSString *)relation count:(NSNumber *)count createdDateTime:(NSString *)createdDateTime updatedDateTime:(NSString *)updatedDateTime fromValue:(NSString *)fromValue toValue:(NSString *)toValue {
    return [self insert:bannerId eventId:eventId property:property value:value relation:relation count:count createdDateTime:createdDateTime updatedDateTime:updatedDateTime fromValue:fromValue toValue:toValue eventProperty:@"" eventValue:@"" eventRelation:@""];
}

- (BOOL)insert:(NSString *)bannerId eventId:(NSString *)eventId property:(NSString *)property value:(NSString *)value relation:(NSString *)relation count:(NSNumber *)count createdDateTime:(NSString *)createdDateTime updatedDateTime:(NSString *)updatedDateTime fromValue:(NSString *)fromValue toValue:(NSString *)toValue eventProperty:(NSString *)eventProperty eventValue:(NSString *)eventValue eventRelation:(NSString *)eventRelation {

    [_databaseLock lock];
    BOOL success = NO;

    if (![self databaseTableExists:databaseTable]) {
        [_databaseLock unlock];
        return NO;
    }

    if (!count) {
        count = @(0);
    }
    if (!bannerId) bannerId = @"";
    if (!eventId) eventId = @"";
    if (!property) property = @"";
    if (!value) value = @"";
    if (!relation) relation = @"";
    if (!createdDateTime) createdDateTime = @"";
    if (!updatedDateTime) updatedDateTime = @"";
    if (!fromValue) fromValue = @"";
    if (!toValue) toValue = @"";
    if (!eventProperty) eventProperty = @"";
    if (!eventValue) eventValue = @"";
    if (!eventRelation) eventRelation = @"";

    if (sqlite3_open([[self databasePath] UTF8String], &database) == SQLITE_OK) {
        NSString *selectSQL = [NSString stringWithFormat:
                               @"SELECT 1 FROM %@ WHERE bannerId = ? AND eventId = ? AND property = ? AND value = ? AND relation = ? AND eventProperty = ? AND eventValue = ? AND eventRelation = ? LIMIT 1;", databaseTable];
        sqlite3_stmt *selectStatement;

        if (sqlite3_prepare_v2(database, [selectSQL UTF8String], -1, &selectStatement, nil) == SQLITE_OK) {
            sqlite3_bind_text(selectStatement, 1, [bannerId UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 2, [eventId UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 3, [property UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 4, [value UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 5, [relation UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 6, [eventProperty UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 7, [eventValue UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(selectStatement, 8, [eventRelation UTF8String], -1, SQLITE_STATIC);

            BOOL recordExists = sqlite3_step(selectStatement) == SQLITE_ROW;
            sqlite3_finalize(selectStatement);

            if (!recordExists) {
                NSString *insertSQL = [NSString stringWithFormat:
                                       @"INSERT INTO %@ (bannerId, eventId, property, value, relation, count, createdDateTime, updatedDateTime, fromValue, toValue, eventProperty, eventValue, eventRelation) "
                                       "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);", databaseTable];
                sqlite3_stmt *insertStatement;

                if (sqlite3_prepare_v2(database, [insertSQL UTF8String], -1, &insertStatement, nil) == SQLITE_OK) {
                    sqlite3_bind_text(insertStatement, 1, [bannerId UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(insertStatement, 2, [eventId UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(insertStatement, 3, [property UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(insertStatement, 4, [value UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(insertStatement, 5, [relation UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_int(insertStatement, 6, count.intValue);
                    sqlite3_bind_text(insertStatement, 7, [createdDateTime UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(insertStatement, 8, [updatedDateTime UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(insertStatement, 9, [fromValue UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(insertStatement, 10, [toValue UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(insertStatement, 11, [eventProperty UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(insertStatement, 12, [eventValue UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(insertStatement, 13, [eventRelation UTF8String], -1, SQLITE_STATIC);

                    if (sqlite3_step(insertStatement) == SQLITE_DONE) {
                        success = YES;
                    } else {
                        [CPLog debug:@"CPSQLiteManager: insert: Error inserting into the database."];
                    }
                    sqlite3_finalize(insertStatement);
                }
            }
        }

        sqlite3_close(database);
    }

    [_databaseLock unlock];
    return success;
}


#pragma mark - to update the record in the database
- (BOOL)updateCountForEventWithId:(NSString *)eventId eventValue:(NSString *)eventValue eventProperty:(NSString *)eventProperty updatedDateTime:(NSString *)updatedDateTime {
    [_databaseLock lock];
    BOOL success = NO;

    if (![self databaseTableExists:databaseTable]) {
        [_databaseLock unlock];
        return NO;
    }

    if (sqlite3_open([[self databasePath] UTF8String], &database) == SQLITE_OK) {
        NSString *updateSQL = [NSString stringWithFormat:
                               @"UPDATE %@ SET count = count + 1, updatedDateTime = ? "
                               "WHERE eventId = ? AND eventValue = ? AND eventProperty = ?;", databaseTable];

        sqlite3_stmt *updateStatement;

        if (sqlite3_prepare_v2(database, [updateSQL UTF8String], -1, &updateStatement, nil) == SQLITE_OK) {
            sqlite3_bind_text(updateStatement, 1, [updatedDateTime UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(updateStatement, 2, [eventId UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(updateStatement, 3, [eventValue UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(updateStatement, 4, [eventProperty UTF8String], -1, SQLITE_STATIC);

            if (sqlite3_step(updateStatement) == SQLITE_DONE) {
                success = YES;
            }
            sqlite3_finalize(updateStatement);
        }

        sqlite3_close(database);
    }

    [_databaseLock unlock];
    return success;
}

#pragma mark - to get all the records from database
- (NSArray<CPAppBannerEventFilters *> *)getAllRecords {
    NSMutableArray<CPAppBannerEventFilters *> *recordArray = [NSMutableArray array];

    [_databaseLock lock];

    if (![self databaseTableExists:databaseTable]) {
        [CPLog debug:@"CPSQLiteManager: getAllRecords: Table '%@' does not exist.", databaseTable];
        [_databaseLock unlock];
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
                    @"createdDateTime": (const char *)sqlite3_column_text(statement, 7) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 7)] : @"",
                    @"updatedDateTime": (const char *)sqlite3_column_text(statement, 8) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 8)] : @"",
                    @"fromValue": (const char *)sqlite3_column_text(statement, 9) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 9)] : @"",
                    @"toValue": (const char *)sqlite3_column_text(statement, 10) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 10)] : @"",
                    @"eventProperty": (const char *)sqlite3_column_text(statement, 11) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 11)] : @"",
                    @"eventValue": (const char *)sqlite3_column_text(statement, 12) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 12)] : @"",
                    @"eventRelation": (const char *)sqlite3_column_text(statement, 13) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 13)] : @"",
                };
                CPAppBannerEventFilters *record = [[CPAppBannerEventFilters alloc] initWithJson:recordDict];
                [recordArray addObject:record];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(database);
    }

    [_databaseLock unlock];
    return recordArray;
}

#pragma mark - to get particular the records from database for the particular event
- (NSArray<CPAppBannerEventFilters *> *)getRecordsForEvent:(NSString *)bannerId eventId:(NSString *)eventId property:(NSString *)property value:(NSString *)value relation:(NSString *)relation fromValue:(NSString *)fromValue toValue:(NSString *)toValue eventProperty:(NSString *)eventProperty
    eventValue:(NSString *)eventValue eventRelation:(NSString *)eventRelation {

    NSMutableArray<CPAppBannerEventFilters *> *recordArray = [NSMutableArray array];

    [_databaseLock lock];

    if (![self databaseTableExists:databaseTable]) {
        [CPLog debug:@"CPSQLiteManager: getRecordsForEvent: Table '%@' does not exist.", databaseTable];
        [_databaseLock unlock];
        return recordArray;
    }

    sqlite3 *database;
    if (sqlite3_open([[self databasePath] UTF8String], &database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE bannerId = ? AND eventId = ? AND property = ? AND value = ? AND relation = ? AND fromValue = ? AND toValue = ? AND eventProperty = ? AND eventValue = ? AND eventRelation = ?;", databaseTable];
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [bannerId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [eventId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [property UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [value UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, [relation UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 6, [fromValue UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 7, [toValue UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 8, [eventProperty UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 9, [eventValue UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 10, [eventRelation UTF8String], -1, SQLITE_TRANSIENT);

            while (sqlite3_step(statement) == SQLITE_ROW) {
                NSDictionary *recordDict = @{
                    @"banner" : (const char *)sqlite3_column_text(statement, 1) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 1)] : @"",
                    @"event": (const char *)sqlite3_column_text(statement, 2) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 2)] : @"",
                    @"property": (const char *)sqlite3_column_text(statement, 3) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 3)] : @"",
                    @"value": (const char *)sqlite3_column_text(statement, 4) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 4)] : @"",
                    @"relation": (const char *)sqlite3_column_text(statement, 5) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 5)] : @"",
                    @"count" : [NSString stringWithFormat:@"%d", sqlite3_column_int(statement, 6)] ?: @"",
                    @"createdDateTime": (const char *)sqlite3_column_text(statement, 7) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 7)] : @"",
                    @"updatedDateTime": (const char *)sqlite3_column_text(statement, 8) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 8)] : @"",
                    @"fromValue": (const char *)sqlite3_column_text(statement, 9) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 9)] : @"",
                    @"toValue": (const char *)sqlite3_column_text(statement, 10) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 10)] : @"",
                    @"eventProperty": (const char *)sqlite3_column_text(statement, 11) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 11)] : @"",
                    @"eventValue": (const char *)sqlite3_column_text(statement, 12) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 12)] : @"",
                    @"eventRelation": (const char *)sqlite3_column_text(statement, 13) ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 13)] : @"",
                };
                CPAppBannerEventFilters *record = [[CPAppBannerEventFilters alloc] initWithJson:recordDict];
                [recordArray addObject:record];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    }

    [_databaseLock unlock];

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
        NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM %@ WHERE createdDateTime <= ?;", databaseTable];
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

        sqlite3_finalize(deleteStatement);
        sqlite3_close(database);
    } else {
        [CPLog debug:@"CPSQLiteManager: deleteDataBasedOnRetentionDays: Failed to open the database: %s", sqlite3_errmsg(database)];
    }

    return NO;
}

@end
