//
//  CPWKWebKitView.h
//  CleverPush
//
//  Created by Azhar - M1 on 08/04/21.
//  Copyright © 2021 CleverPush. All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPWKWebKitView : WKWebView
- (void)setHTMLContent:(NSString*)content;

@end

NS_ASSUME_NONNULL_END
