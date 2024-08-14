#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

- (IBAction)btnHandlerSubscriptionOn:(id)sender;
- (IBAction)btnHandlerSubscribeOff:(id)sender;
- (IBAction)btnHandlergetSubscriptionID:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *lblStatusDisplay;
@property (weak, nonatomic) IBOutlet UITextField *txtLiveActivityName;

@end
