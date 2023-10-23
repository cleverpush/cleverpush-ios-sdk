#import "CleverPushSQLiteManager.h"
#import "CleverPush.h"

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
                           count:(NSNumber *)count
                 createdDateTime:(NSString *)createdDateTime
                 updatedDateTime:(NSString *)updatedDateTime
                      from_value:(NSString *)from_value
                        to_value:(NSString *)to_value {
    
    NSString *tableName = @"TableBannerTrackEvent";
    
    if (![self cleverPushDatabasetableExists:tableName]) {
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
    
    sqlite3 *database;
    NSString *databasePath = [self cleverPushDatabasePath];
    
    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT count FROM %@ WHERE track_event_id = ?;", tableName];
        sqlite3_stmt *selectStatement;
        
        if (sqlite3_prepare_v2(database, [selectSQL UTF8String], -1, &selectStatement, nil) == SQLITE_OK) {
            sqlite3_bind_text(selectStatement, 1, [trackEventID UTF8String], -1, SQLITE_STATIC);
            
            if (sqlite3_step(selectStatement) == SQLITE_ROW) {
                int currentCount = sqlite3_column_int(selectStatement, 0);
                int updatedCount = currentCount + 1;
                sqlite3_finalize(selectStatement);
                
                NSString *updateSQL = [NSString stringWithFormat:
                                       @"UPDATE %@ SET count = ?, updated_date_time = ? "
                                       "WHERE track_event_id = ?;", tableName];
                
                sqlite3_stmt *updateStatement;
                
                if (sqlite3_prepare_v2(database, [updateSQL UTF8String], -1, &updateStatement, nil) == SQLITE_OK) {
                    sqlite3_bind_int(updateStatement, 1, updatedCount);
                    sqlite3_bind_text(updateStatement, 2, [updatedDateTime UTF8String], -1, SQLITE_STATIC);
                    sqlite3_bind_text(updateStatement, 3, [trackEventID UTF8String], -1, SQLITE_STATIC);
                    
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
                               "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);", tableName];
        
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

- (void)deleteCleverPushDatabase {
    NSString *databasePath = [self cleverPushDatabasePath];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:databasePath error:nil];
    NSString *protection = [fileAttributes[NSFileProtectionKey] description];
    
    sqlite3 *database;
    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        sqlite3_close(database);
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:databasePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:databasePath error:&error]) {
            NSLog(@"Database file deleted successfully.");
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_DATABASE_CREATED_TIME_KEY];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLEVERPUSH_DATABASE_CREATED_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            NSLog(@"Error deleting database file: %@", [error localizedDescription]);
        }
    } else {
        NSLog(@"Database file does not exist.");
    }
}

@end
