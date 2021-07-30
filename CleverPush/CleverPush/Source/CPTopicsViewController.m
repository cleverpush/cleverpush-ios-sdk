#import "CPTopicsViewController.h"
#import <CleverPush/CleverPush.h>
#import "CPIntrinsicTableView.h"
#import "CPChannelTopic.h"
#import "CPTranslate.h"

@implementation CPTopicsViewController

#pragma mark - Get all the available topics with selected topics
- (id)initWithAvailableTopics:(NSArray*)topics selectedTopics:(NSArray*)userTopics hasSubscriptionTopics:(BOOL)hasTopics_ {
    self = [super init];
    if (self) {
        availableTopics = [NSMutableArray new];
        selectedTopics = [NSMutableArray arrayWithArray:userTopics];
        hasTopics = hasTopics_;
        
        childTopics = [NSMutableDictionary new];
        parentTopics = [NSMutableArray new];
        for (CPChannelTopic *topic in topics) {
            NSString* parentTopicId = [topic parentTopic];
            if (!parentTopicId) {
                [parentTopics addObject:topic];
            } else {
                NSMutableArray *childArray = [childTopics objectForKey:parentTopicId];
                if (!childArray) {
                    childArray = [NSMutableArray new];
                }
                [childArray addObject:topic];
                [childTopics setValue:childArray forKey:parentTopicId];
            }
        }
        
        for (CPChannelTopic *topic in parentTopics) {
            NSString* parentTopicId = [topic id];
            [availableTopics addObject:topic];
            NSMutableArray *childArray = [childTopics objectForKey:parentTopicId];
            if (childArray) {
                for (NSDictionary *childTopic in childArray) {
                    [availableTopics addObject:childTopic];
                }
            }
        }
    }
    return self;
}

#pragma mark - Get all the selected topics
- (NSMutableArray*)getSelectedTopics {
    return selectedTopics;
}

#pragma mark - Controller Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    tableView = [[CPIntrinsicTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.backgroundColor = UIColor.clearColor;
    
    tableView.userInteractionEnabled = YES;
    tableView.rowHeight = UITableViewAutomaticDimension;
    tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.001)];
    
    tableView.delegate = self;
    tableView.dataSource = self;
    
    if (self.topicsDialogShowUnsubscribe == YES) {
        if ([self getSelectedTopics].count == 0) {
            [self updateDeselectFlag:YES];
        } else {
            [self updateDeselectFlag:NO];
        }
    }
    self.view = tableView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!tableView.tableHeaderView) {
        int labelPaddingBottom = 15;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        
        titleLabel.numberOfLines = 0;
        [titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
        
        titleLabel.text = self.title;
        [titleLabel sizeToFit];
        titleLabel.frame = CGRectMake(0, 0, tableView.frame.size.width, titleLabel.frame.size.height);
        
        tableView.tableHeaderView = [[UIView alloc] initWithFrame:titleLabel.frame];
        [tableView.tableHeaderView addSubview:titleLabel];
        tableView.scrollEnabled = NO;
        // add some padding
        tableView.tableHeaderView.frame = CGRectMake(tableView.tableHeaderView.frame.origin.x, tableView.tableHeaderView.frame.origin.y, tableView.tableHeaderView.frame.size.width, tableView.tableHeaderView.frame.size.height + labelPaddingBottom);
        
        [tableView reloadData];
        
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [self manageHeightLayout];
}

#pragma mark - Deselect Everything while switching off the switch
- (void)deselectEverything:(id)sender {
    UISwitch* switcher = (UISwitch*)sender;
    
    if (switcher.on) {
        [selectedTopics removeAllObjects];
        for (CPChannelTopic *topic in availableTopics) {
            topic.defaultUnchecked = YES;
        }
        hasTopics = NO;
        [self updateDeselectFlag:YES];
        [tableView reloadData];
        [self manageHeightLayout];
    } else {
        if ([self getSelectedTopics].count == 0) {
            [self updateDeselectFlag:NO];
        }
        else {
            [self updateDeselectFlag:NO];
        }
    }
}

#pragma mark - update UserDefaults while toggled deselect switch
- (void)updateDeselectFlag:(BOOL)value{
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"CleverPush_DESELECT_ALL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - retrieve Deselect value from UserDefaults
- (BOOL)getDeselectValue{
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"CleverPush_DESELECT_ALL"] != nil) {
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"CleverPush_DESELECT_ALL"]) {
            return NO;
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}

#pragma mark - manage height of the DWAlertView
- (void)manageHeightLayout{
    id<ManageHeight> strongDelegate = self.delegate;
    [strongDelegate rearrangeHeight];
}

#pragma mark - Handle the switch event when toggle the switch or Select/Deselect table raw.
- (void)switchChanged:(id)sender {
    UISwitch* switcher = (UISwitch*)sender;
    CPChannelTopic* topic = availableTopics[(int) switcher.tag - 1];
    
    if (topic) {
        NSString* topicId = [topic id];
        BOOL contains = [selectedTopics containsObject:topicId];
        if (switcher.on && !contains) {
            [selectedTopics addObject:topicId];
            
        } else if (!switcher.on && contains) {
            [selectedTopics removeObject:topicId];
            for (CPChannelTopic *topicone in availableTopics) {
                NSString* parentTopicId = [topicone parentTopic];
                if (parentTopicId != nil) {
                    if (topicId == parentTopicId) {
                        BOOL contains = [selectedTopics containsObject:[topicone id]];
                        if (contains) {
                            NSString* topiconeId = [topicone id];
                            
                            [selectedTopics removeObject:topiconeId];
                            topicone.defaultUnchecked = YES;
                        }
                    }
                }
            }
        } else if (switcher.on && contains) {
            [selectedTopics removeObject:topicId];
            for (CPChannelTopic *topicone in availableTopics) {
                NSString* parentTopicId = [topicone parentTopic];
                if (parentTopicId != nil) {
                    if (topicId == parentTopicId) {
                        BOOL contains = [selectedTopics containsObject:[topicone id]];
                        if (contains) {
                            NSString* topiconeId = [topicone id];
                            
                            [selectedTopics removeObject:topiconeId];
                            topicone.defaultUnchecked = YES;
                        }
                    }
                }
            }
        } else if (!switcher.on && !contains) {
            [selectedTopics removeObject:topicId];
            for (CPChannelTopic *topicone in availableTopics) {
                NSString* parentTopicId = [topicone parentTopic];
                if (parentTopicId != nil) {
                    if (topicId == parentTopicId) {
                        BOOL contains = [selectedTopics containsObject:[topicone id]];
                        if (contains) {
                            NSString* topiconeId = [topicone id];
                            
                            [selectedTopics removeObject:topiconeId];
                            topicone.defaultUnchecked = YES;
                        }
                    }
                }
            }
        }
        
        hasTopics = YES;
        if (self.topicsDialogShowUnsubscribe == YES) {
            if ([selectedTopics count] == 0) {
                [self updateDeselectFlag:YES];
            } else {
                [self updateDeselectFlag:NO];
            }
        }
        [tableView reloadData];
        [self manageHeightLayout];
    }
}

#pragma mark - get the details of individual topic.
- (CPChannelTopic*)getTopic:(int)row {
    int count = -1;
    for (CPChannelTopic *topic in availableTopics) {
        NSString* parentTopicId = [topic parentTopic];
        if (!parentTopicId || [selectedTopics containsObject:parentTopicId]) {
            count += 1;
        }
        if (count >= row) {
            return topic;
        }
    }
    return nil;
}

#pragma mark - get the index of topic.
- (int)getTopicIndex:(NSString*)topicId {
    int index = -1;
    for (CPChannelTopic *topic in availableTopics) {
        index += 1;
        NSString* topicIdCurrent = [topic id];
        if ([topicIdCurrent isEqualToString:topicId]) {
            return index;
        }
    }
    return -1;
}

#pragma mark - get the default state of the current topic.
- (BOOL)defaultTopicState:(CPChannelTopic*)topic {
    BOOL defaultUnchecked = NO;
    if (topic && [topic defaultUnchecked]) {
        defaultUnchecked = YES;
    }
    BOOL state = (([selectedTopics count] == 0 && !hasTopics && !defaultUnchecked) || [selectedTopics containsObject:[topic id]]);
    return state;
}

#pragma mark - Delegate & DataSource List of the subscription.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int count = 0;
    
    for (CPChannelTopic *topic in availableTopics) {
        NSString* parentTopicId = [topic parentTopic];
        if (!parentTopicId || [selectedTopics containsObject:parentTopicId]) {
            count += 1;
        }
    }
    return count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 44)];
    
    UISwitch* s = [[UISwitch alloc] init];
    CGSize switchSize = [s sizeThatFits:CGSizeZero];
    s.frame = CGRectMake(tableView.bounds.size.width - switchSize.width - 5.0f, (44 - switchSize.height) / 2.0f, switchSize.width, switchSize.height);
    [s addTarget:self action:@selector(deselectEverything:) forControlEvents:UIControlEventValueChanged];
    s.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [headerView addSubview:s];
    
    if ([self getDeselectValue] == YES) {
        s.on = YES;
    } else {
        s.on = NO;
    }
    
    UILabel* deselectEverything = [[UILabel alloc] init];
    deselectEverything.text = [CPTranslate translate:@"deselectEverything"];
    deselectEverything.frame = CGRectMake(10.0, (44 - switchSize.height) / 2.0f, tableView.bounds.size.width - (10 + switchSize.width), switchSize.height);
    [headerView addSubview:deselectEverything];
    
    return headerView;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    int row = (int)indexPath.row;
    CPChannelTopic *topic = [self getTopic:row];
    
    NSString* topicId = [topic id];
    int topicIndex = [self getTopicIndex:topicId];
    
    NSString* cellIdentifier = [NSString stringWithFormat:@"switchCell-%@", topicId];
    
    // NSLog(@"cellForRowAtIndexPath: %@ %d", cellIdentifier, topicIndex);
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.backgroundColor = UIColor.clearColor;
        UISwitch* s = [[UISwitch alloc] init];
        CGSize switchSize = [s sizeThatFits:CGSizeZero];
        s.frame = CGRectMake(cell.contentView.bounds.size.width - switchSize.width - 5.0f,
                             (cell.contentView.bounds.size.height - switchSize.height) / 2.0f,
                             switchSize.width,
                             switchSize.height);
        s.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        s.tag = topicIndex + 1;
        s.on = [self defaultTopicState:topic];
        
        [s addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:s];
        
        UILabel* l = [[UILabel alloc] init];
        
        l.text = @"";
        CGRect labelFrame = CGRectInset(cell.contentView.bounds, 10.0f, 8.0f);
        labelFrame.size.width = cell.contentView.bounds.size.width / 2.0f;
        
        if ([topic parentTopic]) {
            float inset = 30.0f;
            labelFrame.size.width -= inset;
            labelFrame.origin.x += inset;
            s.on = [self defaultTopicState:topic];
            
        }
        
        l.frame = labelFrame;
        l.tag = 200;
        l.backgroundColor = [UIColor clearColor];
        cell.accessibilityLabel = l.text;
        [cell.contentView addSubview:l];
    }
    
    UISwitch *switcher = (UISwitch*)[cell.contentView viewWithTag:(topicIndex + 1)];
    UILabel *nameLabel = (UILabel*)[cell.contentView viewWithTag:200];
    
    nameLabel.text = [topic name];
    
    switcher.on = [self defaultTopicState:topic] ? YES : NO;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int row = (int)indexPath.row;
    CPChannelTopic *topic = [self getTopic:row];
    
    NSString* topicId = [topic id];
    int topicIndex = [self getTopicIndex:topicId];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    int tag = topicIndex + 1;
    UISwitch* switcher = (UISwitch*)[cell.contentView viewWithTag:tag];
    [switcher setOn:!switcher.on animated:YES];
    
    [self switchChanged:switcher];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section{
    
    if (self.topicsDialogShowUnsubscribe == NO) {
        return 0;
    } else {
        return 44;
    }
}

@end
