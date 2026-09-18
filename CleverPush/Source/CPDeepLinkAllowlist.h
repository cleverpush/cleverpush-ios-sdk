#ifndef CPDeepLinkAllowlist_h
#define CPDeepLinkAllowlist_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPDeepLinkAllowlistRule : NSObject
@property (nonatomic, copy, readonly) NSString *scheme;
@property (nonatomic, copy, readonly, nullable) NSString *host;
- (instancetype)initWithScheme:(NSString *)scheme host:(NSString * _Nullable)host;
@end

@interface CPDeepLinkAllowlist : NSObject

+ (BOOL)allowsURLString:(NSString *)urlString;
+ (BOOL)matchesURLString:(NSString *)urlString rules:(NSArray<CPDeepLinkAllowlistRule *> *)rules;
+ (NSArray<CPDeepLinkAllowlistRule *> *)rules;
+ (void)resetCachedRules;

@end

NS_ASSUME_NONNULL_END

#endif
