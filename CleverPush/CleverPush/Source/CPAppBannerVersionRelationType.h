typedef NS_ENUM(NSInteger, CPAppBannerVersionRelationType) {
    CPAppBannerTypeEquals,
    CPAppBannerTypeLessThan,
    CPAppBannerTypeGreaterThan,
    CPAppBannerTypeBetween,
    CPAppBannerTypeNotEqual,
    CPAppBannerTypeContains,
    CPAppBannerTypeNotContains
};

#define versionRelation(enum) [@[@"equals",@"lessThan",@"greaterThan",@"between",@"notEquals",@"contains",@"notContains"] objectAtIndex:enum]
