#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
@interface CPHTMLBlockCell : UITableViewCell

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webHTMLContentHeight;
@property (weak, nonatomic) IBOutlet WKWebView *webHTMLBlock;

@end
