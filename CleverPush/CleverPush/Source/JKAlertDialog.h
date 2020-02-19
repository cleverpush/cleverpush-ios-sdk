#import <UIKit/UIKit.h>
typedef enum ButtonType
{
    Button_OK,
    Button_CANCEL,
    Button_OTHER
    
}ButtonType;

@class JKAlertDialogItem;
typedef void(^JKAlertDialogHandler)(JKAlertDialogItem *item);


@interface JKAlertDialog : UIView
{
    UIView *_coverView;
    UIView *_alertView;
    
    UIScrollView *_buttonScrollView;
    UIScrollView *_contentScrollView;
    
    NSMutableArray *_items;
    NSString *_title;
    NSString *_message;

}

@property(assign,nonatomic)CGFloat buttonWidth;
@property(strong,nonatomic)UIView *contentView;

- (instancetype)init;
- (void)show;
- (void)dismiss;
- (void)reLayout;

@end


@interface JKAlertDialogItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic) ButtonType type;
@property (nonatomic) NSUInteger tag;
@property (nonatomic, copy) JKAlertDialogHandler action;
@end
