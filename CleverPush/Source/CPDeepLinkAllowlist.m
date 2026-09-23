#import "CPDeepLinkAllowlist.h"
#import "CleverPush.h"
#import "CPLog.h"

@implementation CPDeepLinkAllowlistRule

- (instancetype)initWithScheme:(NSString *)scheme host:(NSString *)host {
    self = [super init];
    if (self) {
        _scheme = [scheme copy];
        _host = [host copy];
    }
    return self;
}

@end

@implementation CPDeepLinkAllowlist

static NSArray<CPDeepLinkAllowlistRule *> *cachedRules;
static NSObject *rulesLock;

+ (void)initialize {
    if (self == [CPDeepLinkAllowlist class]) {
        rulesLock = [NSObject new];
    }
}

+ (void)resetCachedRules {
    @synchronized (rulesLock) {
        cachedRules = nil;
    }
}

+ (BOOL)allowsURLString:(NSString *)urlString {
    return [self matchesURLString:urlString rules:[self rules]];
}

+ (BOOL)matchesURLString:(NSString *)urlString rules:(NSArray<CPDeepLinkAllowlistRule *> *)rules {
    if (urlString.length == 0 || rules.count == 0) {
        return NO;
    }

    NSURL *url = [NSURL URLWithString:[urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    if (!url || url.scheme.length == 0) {
        return NO;
    }

    NSString *scheme = [url.scheme lowercaseString];
    NSString *host = url.host.length > 0 ? [url.host lowercaseString] : nil;

    for (CPDeepLinkAllowlistRule *rule in rules) {
        if (rule.scheme.length == 0 || ![rule.scheme isEqualToString:scheme]) {
            continue;
        }
        if ([self hostMatchesRuleHost:rule.host urlHost:host]) {
            return YES;
        }
    }
    return NO;
}

+ (NSArray<CPDeepLinkAllowlistRule *> *)rules {
    @synchronized (rulesLock) {
        if (cachedRules != nil) {
            return cachedRules;
        }
        NSArray<CPDeepLinkAllowlistRule *> *loaded = [self loadRules];
        cachedRules = [loaded copy];
        [CPLog debug:@"DeepLinkAllowlist: loaded %lu deep link rule(s)", (unsigned long)cachedRules.count];
        return cachedRules;
    }
}

+ (NSArray<CPDeepLinkAllowlistRule *> *)loadRules {
    NSMutableArray<CPDeepLinkAllowlistRule *> *rules = [NSMutableArray array];

    NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    if ([urlTypes isKindOfClass:[NSArray class]]) {
        for (NSDictionary *urlType in urlTypes) {
            if (![urlType isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            NSArray *schemes = urlType[@"CFBundleURLSchemes"];
            if (![schemes isKindOfClass:[NSArray class]]) {
                continue;
            }
            for (NSString *scheme in schemes) {
                NSString *normalizedScheme = [self normalize:scheme];
                if (normalizedScheme.length == 0) {
                    continue;
                }
                CPDeepLinkAllowlistRule *rule = [[CPDeepLinkAllowlistRule alloc] initWithScheme:normalizedScheme host:nil];
                if ([self isUsableRule:rule]) {
                    [rules addObject:rule];
                }
            }
        }
    }

    NSArray *configuredDomains = [CleverPush getHandleUniversalLinksInAppForDomains];
    if ([configuredDomains isKindOfClass:[NSArray class]]) {
        for (NSString *domain in configuredDomains) {
            if (![domain isKindOfClass:[NSString class]] || domain.length == 0) {
                continue;
            }
            NSString *trimmed = [domain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            BOOL schemeLess = !([trimmed hasPrefix:@"http://"] || [trimmed hasPrefix:@"https://"]);
            NSURL *domainURL = nil;
            if (!schemeLess) {
                domainURL = [NSURL URLWithString:trimmed];
            } else {
                domainURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", trimmed]];
            }
            NSString *host = [self normalize:domainURL.host ?: trimmed];
            if (host.length == 0 || [host isEqualToString:@"*"]) {
                continue;
            }
            NSString *scheme = [self normalize:domainURL.scheme.length > 0 ? domainURL.scheme : @"https"];
            CPDeepLinkAllowlistRule *httpsRule = [[CPDeepLinkAllowlistRule alloc] initWithScheme:scheme host:host];
            if ([self isUsableRule:httpsRule]) {
                [rules addObject:httpsRule];
            }
            if (schemeLess) {
                CPDeepLinkAllowlistRule *httpRule = [[CPDeepLinkAllowlistRule alloc] initWithScheme:@"http" host:host];
                if ([self isUsableRule:httpRule]) {
                    [rules addObject:httpRule];
                }
            }
        }
    }

    return rules;
}

+ (BOOL)hostMatchesRuleHost:(NSString *)ruleHost urlHost:(NSString *)urlHost {
    if (ruleHost.length == 0 || [ruleHost isEqualToString:@"*"]) {
        return YES;
    }
    if ([ruleHost isEqualToString:urlHost]) {
        return YES;
    }
    if (urlHost.length > 0 && [ruleHost hasPrefix:@"*."]
        && urlHost.length > ruleHost.length - 1
        && [urlHost hasSuffix:[ruleHost substringFromIndex:1]]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isUsableRule:(CPDeepLinkAllowlistRule *)rule {
    if (rule.scheme.length == 0) {
        return NO;
    }
    if ([rule.scheme isEqualToString:@"http"] || [rule.scheme isEqualToString:@"https"]) {
        return rule.host.length > 0 && ![rule.host isEqualToString:@"*"];
    }
    return YES;
}

+ (NSString *)normalize:(NSString *)value {
    if (value.length == 0) {
        return nil;
    }
    NSString *trimmed = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return nil;
    }
    return [trimmed lowercaseString];
}

@end
