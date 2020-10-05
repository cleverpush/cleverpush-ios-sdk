#import "CPTopicsViewController.h"
#import <CleverPush/CleverPush.h>

@interface CPTopicsViewController ()

@end

@implementation CPTopicsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:tableView];
    NSDictionary *views = NSDictionaryOfVariableBindings(tableView);
    
     [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"H:|-8-[tableView]-8-|" options:0 metrics:nil views:views]];
     [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[tableView]-8-|" options:0 metrics:nil views:views]];
    

    tableView.scrollEnabled = YES;
    tableView.showsVerticalScrollIndicator = YES;
    tableView.userInteractionEnabled = YES;
    tableView.bounces = YES;
    tableView.rowHeight = UITableViewAutomaticDimension;
    tableView.estimatedRowHeight = UITableViewAutomaticDimension;

    tableView.delegate = self;
    tableView.dataSource = self;

}

- (void) switchChanged:(id)sender {
    UISwitch* switcher = (UISwitch*)sender;
    // BOOL value = switcher.on;
    // Store the value and/or respond appropriately
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    UISwitch* switcher = (UISwitch*)[cell.contentView viewWithTag:100];
    [switcher setOn:!switcher.on animated:YES];
    [self switchChanged:switcher];
}

- (UITableViewCell*) tableView:(UITableView*) tableView cellForRowAtIndexPath:(NSIndexPath*) indexPath {
    static NSString* cellIdentifier = @"switchCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        UISwitch* s = [[UISwitch alloc] init];
        CGSize switchSize = [s sizeThatFits:CGSizeZero];
        s.frame = CGRectMake(cell.contentView.bounds.size.width - switchSize.width - 5.0f,
                             (cell.contentView.bounds.size.height - switchSize.height) / 2.0f,
                             switchSize.width,
                             switchSize.height);
        s.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        s.tag = 100;
        [s addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:s];

        UILabel* l = [[UILabel alloc] init];
        l.text = @"Notifications";
        CGRect labelFrame = CGRectInset(cell.contentView.bounds, 10.0f, 8.0f);
        labelFrame.size.width = cell.contentView.bounds.size.width / 2.0f;
        l.font = [UIFont boldSystemFontOfSize:17.0f];
        l.frame = labelFrame;
        l.backgroundColor = [UIColor clearColor];
        cell.accessibilityLabel = @"Notifications";
        [cell.contentView addSubview:l];
    }
    
    ((UISwitch*)[cell.contentView viewWithTag:100]).on = YES; // "value" is whatever the switch should be set to
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

@end
