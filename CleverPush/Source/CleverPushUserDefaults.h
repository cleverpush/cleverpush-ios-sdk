#define CLEVERPUSH_NOTIFICATIONS_KEY @"CleverPush_NOTIFICATIONS"
#define CLEVERPUSH_READ_NOTIFICATIONS_KEY @"CleverPush_READ_NOTIFICATIONS"
#define CLEVERPUSH_LAST_NOTIFICATION_ID_KEY @"CleverPush_LAST_NOTIFICATION_ID"
#define CLEVERPUSH_NOTIFICATION_CATEGORIES_KEY @"CleverPush_NOTIFICATION_CATEGORIES"

#define CLEVERPUSH_CHANNEL_ID_KEY @"CleverPush_CHANNEL_ID"
#define CLEVERPUSH_APP_OPENS_KEY @"CleverPush_APP_OPENS"

#define CLEVERPUSH_APP_REVIEW_SHOWN_KEY @"CleverPush_APP_REVIEW_SHOWN"

#define CLEVERPUSH_LAST_CHECKED_TIME_KEY @"CleverPush_LAST_CHECKED_TIME"
#define CLEVERPUSH_LAST_CHECKED_TIME_AUTO_SHOWED_KEY @"CleverPush_LAST_CHECKED_TIME_AUTO_SHOWED"

#define CLEVERPUSH_SUBSCRIPTION_ID_KEY @"CleverPush_SUBSCRIPTION_ID"
#define CLEVERPUSH_SUBSCRIPTION_CREATED_AT_KEY @"CleverPush_SUBSCRIPTION_CREATED_AT"
#define CLEVERPUSH_SUBSCRIPTION_LAST_SYNC_KEY @"CleverPush_SUBSCRIPTION_LAST_SYNC"
#define CLEVERPUSH_DEVICE_TOKEN_KEY @"CleverPush_DEVICE_TOKEN"
#define CLEVERPUSH_SUBSCRIPTION_TOPICS_KEY @"CleverPush_SUBSCRIPTION_TOPICS"
#define CLEVERPUSH_SUBSCRIPTION_TOPICS_VERSION_KEY @"CleverPush_SUBSCRIPTION_TOPICS_VERSION"
#define CLEVERPUSH_SUBSCRIPTION_TAGS_KEY @"CleverPush_SUBSCRIPTION_TAGS"
#define CLEVERPUSH_SUBSCRIPTION_LANGUAGE_KEY @"CleverPush_SUBSCRIPTION_LANGUAGE"
#define CLEVERPUSH_SUBSCRIPTION_COUNTRY_KEY @"CleverPush_SUBSCRIPTION_COUNTRY"
#define CLEVERPUSH_SUBSCRIPTION_ATTRIBUTES_KEY @"CleverPush_SUBSCRIPTION_ATTRIBUTES"

#define CLEVERPUSH_UNSUBSCRIBED_KEY @"CLEVERPUSH_UNSUBSCRIBED_KEY"

#define CLEVERPUSH_TOPICS_DIALOG_PENDING_KEY @"CleverPush_TOPICS_DIALOG_PENDING"
#define CLEVERPUSH_DESELECT_ALL_KEY @"CleverPush_DESELECT_ALL"

#define CLEVERPUSH_INCREMENT_BADGE_KEY @"CleverPush_INCREMENT_BADGE"
#define CLEVERPUSH_BADGE_COUNT_KEY @"CleverPush_BADGE_COUNT"
#define CLEVERPUSH_SHOW_NOTIFICATIONS_IN_FOREGROUND_KEY @"CleverPush_SHOW_NOTIFICATIONS_IN_FOREGROUND"
#define CLEVERPUSH_MAXIMUM_NOTIFICATION_COUNT @"CleverPush_MAXIMUM_NOTIFICATION_COUNT"

#define CLEVERPUSH_SHOWN_APP_BANNERS_KEY @"CleverPush_SHOWN_APP_BANNERS"
#define CLEVERPUSH_APP_BANNER_SESSIONS_KEY @"CleverPush_APP_BANNER_SESSIONS"
#define CLEVERPUSH_APP_BANNER_VISIBLE_KEY @"CleverPush_APP_BANNER_VISIBLE"
#define CLEVERPUSH_APP_BANNERS_DISABLED_KEY @"CleverPush_APP_BANNERS_DISABLED"

#define CLEVERPUSH_SEEN_STORIES_KEY @"CleverPush_SEEN_STORIES"

#define CLEVERPUSH_DATABASE_CREATED_KEY @"CleverPush_DATABASE_CREATED_AT_KEY"
#define CLEVERPUSH_DATABASE_CREATED_TIME_KEY @"CleverPush_DATABASE_CREATED_TIME_KEY"

#define CLEVERPUSH_DEEP_LINKS_STORED_URLS_KEY @"CleverPush_DEEP_LINKS_STORED_URLS"

#define CHECK_FILTER_EQUAL_TO(key, v)                  ([key compare:v options:NSNumericSearch] == NSOrderedSame)
#define CHECK_FILTER_GREATER_THAN(key, v)              ([key compare:v options:NSNumericSearch] == NSOrderedDescending)
#define CHECK_FILTER_GREATER_THAN_OR_EQUAL_TO(key, v)  ([key compare:v options:NSNumericSearch] != NSOrderedAscending)
#define CHECK_FILTER_LESS_THAN(key, v)                 ([key compare:v options:NSNumericSearch] == NSOrderedAscending)
#define CHECK_FILTER_LESS_THAN_OR_EQUAL_TO(key, v)     ([key compare:v options:NSNumericSearch] != NSOrderedDescending)
