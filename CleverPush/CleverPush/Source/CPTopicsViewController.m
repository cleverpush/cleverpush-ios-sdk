#import "CPTopicsViewController.h"
#import <CleverPush/CleverPush.h>
#import "CPIntrinsicTableView.h"
#import "CPChannelTopic.h"
#import "CPTranslate.h"

@implementation CPTopicsViewController


#pragma mark - Controller Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialisedTableView];
}

#pragma mark - initialised CPIntrinsicTableView
- (void)initialisedTableView {
    tableView = [[CPIntrinsicTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.backgroundColor = UIColor.clearColor;
    tableView.userInteractionEnabled = YES;
    tableView.rowHeight = UITableViewAutomaticDimension;
    tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.001)];
    tableView.delegate = self;
    tableView.dataSource = self;
    self.view = tableView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!tableView.tableHeaderView) {
        [self tableHeaderTitle];
        [self updateDeselectState];
        [self reloadTableView];
    }
}

#pragma mark - Update Deselect flag based on the selected topics
- (void)updateDeselectState {
    if (self.topicsDialogShowUnsubscribe == YES) {
        if ([self getSelectedTopics].count == 0) {
            [CleverPush updateDeselectFlag:YES];
        } else {
            [CleverPush updateDeselectFlag:NO];
        }
    }
}

#pragma mark - Set the table header title
- (void)tableHeaderTitle {
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
    CGRect headerFrame = tableView.tableHeaderView.frame;
    tableView.tableHeaderView.frame = CGRectMake(headerFrame.origin.x, headerFrame.origin.y, headerFrame.size.width, tableView.tableHeaderView.frame.size.height + labelPaddingBottom);
}

#pragma mark - Reload Table view and manage popup height via custom delegate with the help of manageHeightLayout
- (void)reloadTableView {
    [tableView reloadData];
    [self manageHeightLayout];
}

#pragma mark - Get all the available topics with selected topics
- (id)initWithAvailableTopics:(NSArray*)topics selectedTopics:(NSArray*)userTopics hasSubscriptionTopics:(BOOL)hasTopics_ {
    self = [super init];
    if (self) {
        availableTopics = [NSMutableArray new];
        selectedTopics = [NSMutableArray arrayWithArray:userTopics];
        childTopics = [NSMutableDictionary new];
        parentTopics = [NSMutableArray new];
        hasTopics = hasTopics_;
        [self bifurcateParentChildTopics:topics];
        [self getAvailableTopics];
    }
    return self;
}

#pragma mark - Get the available topics
- (void)getAvailableTopics {
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

#pragma mark - Bifurcate Parent & Child topics
- (void)bifurcateParentChildTopics:(NSArray*)topics {
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
}

#pragma mark - Get all the selected topics
- (NSMutableArray*)getSelectedTopics {
    return selectedTopics;
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
        [CleverPush updateDeselectFlag:YES];
        [self reloadTableView];
    } else {
        [CleverPush updateDeselectFlag:NO];
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
        } else if ((!switcher.on && contains) || (switcher.on && contains) || (!switcher.on && !contains)) {
            [self setDefaultState:topicId];
        }
        hasTopics = YES;
        
        if (self.topicsDialogShowUnsubscribe == YES) {
            if ([selectedTopics count] == 0) {
                [CleverPush updateDeselectFlag:YES];
            } else {
                [CleverPush updateDeselectFlag:NO];
            }
        }
        [self reloadTableView];
    }
}

#pragma mark - set the state of the topic checked/unchecked and if the topic has parent topics, unchecked child too with that parent topics
- (void)setDefaultState:(NSString*)topicId {
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
    if (self.topicsDialogShowUnsubscribe == YES) {
        if ([CleverPush getDeselectValue] == YES) {
            return false;
        } else {
            return [self topicState:topic];
        }
    } else {
        return [self topicState:topic];
    }
}

#pragma mark - default topic state
- (BOOL)topicState:(CPChannelTopic*)topic {
    BOOL defaultUnchecked = NO;
    if (topic && [topic defaultUnchecked]) {
        defaultUnchecked = YES;
    }
    BOOL selectedState = (([selectedTopics count] == 0 && !hasTopics && !defaultUnchecked) || [selectedTopics containsObject:[topic id]]);
    return selectedState;
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
    
    UISwitch* deselectSwitch = [[UISwitch alloc] init];
    CGSize switchSize = [deselectSwitch sizeThatFits:CGSizeZero];
    deselectSwitch.frame = CGRectMake(tableView.bounds.size.width - switchSize.width - 5.0f, (44 - switchSize.height) / 2.0f, switchSize.width, switchSize.height);
    [deselectSwitch addTarget:self action:@selector(deselectEverything:) forControlEvents:UIControlEventValueChanged];
    deselectSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [headerView addSubview:deselectSwitch];
    
    if ([CleverPush getDeselectValue] == YES) {
        deselectSwitch.on = YES;
    } else {
        deselectSwitch.on = NO;
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
        UISwitch* topicSwitch = [[UISwitch alloc] init];
        CGSize switchSize = [topicSwitch sizeThatFits:CGSizeZero];
        topicSwitch.frame = CGRectMake(cell.contentView.bounds.size.width - switchSize.width - 5.0f,
                                       (cell.contentView.bounds.size.height - switchSize.height) / 2.0f,
                                       switchSize.width,
                                       switchSize.height);
        topicSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        topicSwitch.tag = topicIndex + 1;
        topicSwitch.on = [self defaultTopicState:topic];
        
        [topicSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:topicSwitch];
        
        UILabel* topicTitle = [[UILabel alloc] init];
        
        topicTitle.text = @"";
        CGRect labelFrame = CGRectInset(cell.contentView.bounds, 10.0f, 8.0f);
        labelFrame.size.width = cell.contentView.bounds.size.width / 2.0f;
        
        if ([topic parentTopic]) {
            float inset = 30.0f;
            labelFrame.size.width -= inset;
            labelFrame.origin.x += inset;
            topicSwitch.on = [self defaultTopicState:topic];
        }
        
        topicTitle.frame = labelFrame;
        topicTitle.tag = 200;
        topicTitle.backgroundColor = [UIColor clearColor];
        cell.accessibilityLabel = topicTitle.text;
        [cell.contentView addSubview:topicTitle];
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

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    if (self.topicsDialogShowUnsubscribe == NO) {
        return 0;
    } else {
        return 44;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section {
    return 0;
}

@end
