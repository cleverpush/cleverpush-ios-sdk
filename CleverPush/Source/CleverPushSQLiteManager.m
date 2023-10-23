#import "CleverPushSQLiteManager.h"

@implementation CleverPushSQLiteManager

static CleverPushSQLiteManager *sharedInstance = nil;

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
    sqlite3 *database;
    NSString *databasePath = [self cleverPushDatabasePath];

    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        sqlite3_close(database);
        return YES;
    } else {
        NSLog(@"Error opening or creating the database.");
        return NO;
    }
}

- (BOOL)cleverPushDatabasetableExists:(NSString *)tableName {
    sqlite3 *database;
    NSString *databasePath = [self cleverPushDatabasePath];

    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
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
    NSString *tableName = @"TableBannerTrackEvent";

    if (![self cleverPushDatabasetableExists:tableName]) {
        sqlite3 *database;
        NSString *databasePath = [self cleverPushDatabasePath];

        if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
            NSString *createTableSQL = [NSString stringWithFormat:
                                        @"CREATE TABLE IF NOT EXISTS %@ ("
                                        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                                        "banner_id TEXT, "
                                        "track_event_id TEXT, "
                                        "property TEXT, "
                                        "value TEXT, "
                                        "relation TEXT, "
                                        "count INTEGER DEFAULT 1, "
                                        "created_date_time TEXT, "
                                        "updated_date_time TEXT, "
                                        "from_value TEXT, "
                                        "to_value TEXT"
                                        ");", tableName];

            char *errMsg;

            if (sqlite3_exec(database, [createTableSQL UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
                NSLog(@"Error creating table: %s", errMsg);
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


- (BOOL)insertRecordWithBannerID:(NSString *)bannerID
                  trackEventID:(NSString *)trackEventID
                      property:(NSString *)property
                         value:(NSString *)value
                     relation:(NSString *)relation
                        count:(int)count
             createdDateTime:(NSString *)createdDateTime
             updatedDateTime:(NSString *)updatedDateTime
                     fromValue:(NSString *)fromValue
                       toValue:(NSString *)toValue {
    if (!_database) {
        NSLog(@"Database is not open. Please open the database first.");
        return NO;
    }

    NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO TableBannerTrackEvent (banner_id, track_event_id, property, value, relation, count, created_date_time, updated_date_time, from_value, to_value) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"];

    sqlite3_stmt *statement;

    if (sqlite3_prepare_v2(_database, [insertSQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [bannerID UTF8String], -1, SQLITE_STATIC);
        sqlite3_bind_text(statement, 2, [trackEventID UTF8String], -1, SQLITE_STATIC);
        sqlite3_bind_text(statement, 3, [property UTF8String], -1, SQLITE_STATIC);
        sqlite3_bind_text(statement, 4, [value UTF8String], -1, SQLITE_STATIC);
        sqlite3_bind_text(statement, 5, [relation UTF8String], -1, SQLITE_STATIC);
        sqlite3_bind_int(statement, 6, count);
        sqlite3_bind_text(statement, 7, [createdDateTime UTF8String], -1, SQLITE_STATIC);
        sqlite3_bind_text(statement, 8, [updatedDateTime UTF8String], -1, SQLITE_STATIC);
        sqlite3_bind_text(statement, 9, [fromValue UTF8String], -1, SQLITE_STATIC);
        sqlite3_bind_text(statement, 10, [toValue UTF8String], -1, SQLITE_STATIC);

        if (sqlite3_step(statement) != SQLITE_DONE) {
            NSLog(@"Error inserting record: %s", sqlite3_errmsg(_database));
            sqlite3_finalize(statement);
            return NO;
        }

        sqlite3_finalize(statement);
        return YES;
    } else {
        NSLog(@"Error preparing statement: %s", sqlite3_errmsg(_database));
        return NO;
    }
}

- (void)cleverPushDatabaseGetAllRecords:(void (^)(NSArray *records))callback {
    NSString *tableName = @"TableBannerTrackEvent";

    if (![self cleverPushDatabasetableExists:tableName]) {
        NSLog(@"Table '%@' does not exist.", tableName);
        if (callback) {
            callback(@[]);
        }
        return;
    }

    sqlite3 *database;
    NSString *databasePath = [self cleverPushDatabasePath];
    NSMutableArray *recordArray = [NSMutableArray array];

    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@;", tableName];
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


@end
