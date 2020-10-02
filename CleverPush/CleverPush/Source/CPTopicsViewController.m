#import "CPTopicsViewController.h"
#import <CleverPush/CleverPush.h>

@interface CPTopicsViewController ()

@end

@implementation CPTopicsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat x = 0;
    CGFloat y = 50;
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height - 50;
    CGRect tableFrame = CGRectMake(x, y, width, height);

    UITableView *tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];

    tableView.estimatedRowHeight = 45;
    tableView.scrollEnabled = YES;
    tableView.showsVerticalScrollIndicator = YES;
    tableView.userInteractionEnabled = YES;
    tableView.bounces = YES;

    tableView.delegate = self;
    tableView.dataSource = self;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"newFriendCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    cell.textLabel.text = @"Test";
    cell.textLabel.font = [cell.textLabel.font fontWithSize:20];

    return cell;
}

 - (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"detailsView" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     if ([segue.identifier isEqualToString:@"detailsView"])
     {

         NSLog(@"segue"); //check to see if method is called, it is NOT called upon cell touch

         NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
         ///more code to prepare next view controller....
     }
}


@end
