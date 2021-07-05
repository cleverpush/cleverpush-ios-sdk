#import <Foundation/Foundation.h>
#import "CPStoryContent.h"

NS_ASSUME_NONNULL_BEGIN
@interface CPStory : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *channel;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *slug;
@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSString *views;
@property (nonatomic, strong) NSString *completions;
@property (nonatomic, strong) NSString *widgetViews;
@property (nonatomic, strong) NSString *clicks;
@property (nonatomic, strong) NSString *viewsWidget;
@property (nonatomic, strong) NSString *viewsOrganic;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *validatedAt;
@property (nonatomic, readwrite) BOOL valid;
@property (nonatomic, readwrite) BOOL published;
@property (nonatomic, strong) CPStoryContent *content;
@property (nonatomic, strong) NSMutableArray<NSString*> *redirectUrls;
@property (nonatomic, strong) NSMutableArray<NSString*> *fontFamilies;
@property (nonatomic, strong) NSMutableArray<NSString*> *keywords;

- (id)initWithJson:(NSDictionary*)json;

@end
NS_ASSUME_NONNULL_END
