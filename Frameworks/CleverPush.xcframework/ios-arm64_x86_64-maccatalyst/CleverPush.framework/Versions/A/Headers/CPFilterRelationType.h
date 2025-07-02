typedef NS_ENUM(NSInteger, CPFilterRelationType) {
    CPFilterRelationTypeEquals,
    CPFilterRelationTypeLessThan,
    CPFilterRelationTypeGreaterThan,
    CPFilterRelationTypeBetween,
    CPFilterRelationTypeNotEqual,
    CPFilterRelationTypeContains,
    CPFilterRelationTypeNotContains,
    CPFilterRelationTypeContainsSubstring
};

#define filterRelationType(enum) [@[@"equals",@"lessThan",@"greaterThan",@"between",@"notEquals",@"contains",@"notContains",@"containsSubstring"] objectAtIndex:enum]
