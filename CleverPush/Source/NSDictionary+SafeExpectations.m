#import "NSDictionary+SafeExpectations.h"

@interface NSDictionary (SafeExpectations_Private)
- (NSString *)stringWithObject:(id)obj;
- (NSNumber *)numberWithObject:(id)obj usingFormatter:(NSNumberFormatter *)numberFormatter;
- (NSArray *)arrayWithObject:(id)obj;
- (NSDictionary *)dictionaryWithObject:(id)obj;
+ (NSNumberFormatter *)posixNumberFormatter;
@end

@implementation NSDictionary (SafeExpectations)

- (NSString *)cleverPushStringForKey:(id)key {
    id obj = [self cleverPushSafeObjectForKey:key];
    return [self stringWithObject:obj];
}

- (NSNumber *)cleverPushNumberForKey:(id)key {
    id obj = [self cleverPushSafeObjectForKey:key];
    return [self numberWithObject:obj usingFormatter:[[self class] posixNumberFormatter]];
}

- (NSNumber *)cleverPushNumberForKey:(id)key usingFormatter:(NSNumberFormatter *)numberFormatter {
    id obj = [self cleverPushSafeObjectForKey:key];
    return [self numberWithObject:obj usingFormatter:numberFormatter];
}

- (NSArray *)cleverPushArrayForKey:(id)key {
    id obj = [self cleverPushSafeObjectForKey:key];
    return [self arrayWithObject:obj];
}

- (NSDictionary *)cleverPushDictionaryForKey:(id)key {
    id obj = [self cleverPushSafeObjectForKey:key];
    return [self dictionaryWithObject:obj];
}

- (id)cleverPushSafeObjectForKey:(id)key {
    NSAssert(key != nil, @"nil key");
    return [self objectForKey:key];
}

- (id)cleverPushObjectForKeyPath:(NSString *)keyPath {
    id object = self;
    NSArray *keyPaths = [keyPath componentsSeparatedByString:@"."];
    for (NSString *currentKeyPath in keyPaths) {
        if (![object isKindOfClass:[NSDictionary class]])
            object = nil;

        object = [object objectForKey:currentKeyPath];

        if (object == nil)
            break;
    }
    return object;
}

- (NSString *)cleverPushStringForKeyPath:(id)keyPath {
    id obj = [self cleverPushObjectForKeyPath:keyPath];
    return [self stringWithObject:obj];

}

- (NSNumber *)cleverPushNumberForKeyPath:(id)keyPath {
    id obj = [self cleverPushObjectForKeyPath:keyPath];
    return [self numberWithObject:obj usingFormatter:[[self class] posixNumberFormatter]];
}

- (NSNumber *)cleverPushNumberForKeyPath:(id)keyPath usingFormatter:(NSNumberFormatter *)numberFormatter{
    id obj = [self cleverPushObjectForKeyPath:keyPath];
    return [self numberWithObject:obj usingFormatter:numberFormatter];
}

- (NSArray *)cleverPushArrayForKeyPath:(id)keyPath {
    id obj = [self cleverPushObjectForKeyPath:keyPath];
    return [self arrayWithObject:obj];
}

- (NSDictionary *)cleverPushDictionaryForKeyPath:(id)keyPath {
    id obj = [self cleverPushObjectForKeyPath:keyPath];
    return [self dictionaryWithObject:obj];
}

@end

@implementation NSDictionary (SafeExpectations_Private)

+ (NSNumberFormatter *)posixNumberFormatter {
    static dispatch_once_t onceToken;
    static NSNumberFormatter *posixFormatter;
    dispatch_once(&onceToken, ^{
        posixFormatter = [[NSNumberFormatter alloc] init];
        [posixFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    });
    return posixFormatter;
}

- (NSString *)stringWithObject:(id)obj {
    NSString *string = obj;

    if (![string isKindOfClass:[NSString class]] && [string respondsToSelector:@selector(stringValue)])
        string = [string performSelector:@selector(stringValue)];

    if (![string isKindOfClass:[NSString class]])
        string = nil;

    return string;
}

- (NSNumber *)numberWithObject:(id)obj usingFormatter:(NSNumberFormatter *)numberFormatter{

    if ([obj isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)obj;
    }

    if ([obj isKindOfClass:[NSString class]]) {
        NSNumber *number = [numberFormatter numberFromString:(NSString *)obj];
        return number;
    }

    return nil;
}

- (NSArray *)arrayWithObject:(id)obj {
    NSArray *array = obj;

    if (![array isKindOfClass:[NSArray class]]) {
        array = nil;
    }

    return array;
}

- (NSDictionary *)dictionaryWithObject:(id)obj {
    NSDictionary *dictionary = obj;

    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        dictionary = nil;
    }

    return dictionary;
}

@end
