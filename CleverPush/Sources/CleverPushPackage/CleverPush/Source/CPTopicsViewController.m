#import "CPTopicsViewController.h"
#import <CleverPush/CleverPush.h>
#import "CPIntrinsicTableView.h"
#import "CPChannelTopic.h"
#import "CPTranslate.h"
#import "CPTopicDialogCell.h"

static CGFloat const CPTopicHeight = 44;
static CGFloat const CPTopicCellLeading = 5.0;
static CGFloat const CPTopicHeightDivider = 2.0f;
static CGFloat const CPConstraints = 30.0;

@implementation CPTopicsViewController

#pragma mark - Controller Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialisedTableView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [CPUtils updateLastTopicCheckedTime];
}

#pragma mark - initialised CPIntrinsicTableView
- (void)initialisedTableView {
    tableView = [[CPIntrinsicTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.backgroundColor = UIColor.clearColor;
    NSBundle *bundle = [CPUtils getAssetsBundle];
    if (bundle) {
        UINib *nib = [UINib nibWithNibName:@"CPTopicDialogCell" bundle:bundle];
        [tableView registerNib:nib forCellReuseIdentifier:@"CPTopicDialogCell"];
    }
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
    }
}

#pragma mark - Update Deselect flag based on the selected topics
- (void)updateInitialDeselectState {
    if (self.topicsDialogShowUnsubscribe == YES) {
        if ([self getSelectedTopics].count == 0) {
            [CleverPush updateDeselectFlag:YES];
        } else if (![CleverPush getDeselectValue]) {
            [CleverPush updateDeselectFlag:NO];
        } else {
            [self setAllTopicsUnchecked];
        }
    }
    [self reloadTableView];
}

#pragma mark - Sets all topics to be unchecked
- (void)setAllTopicsUnchecked {
    [selectedTopics removeAllObjects];
    for (CPChannelTopic *topic in availableTopics) {
        topic.defaultUnchecked = YES;
    }
    hasTopics = NO;
}

#pragma mark - Set the table header title
- (void)tableHeaderTitle {
    int labelPaddingBottom = 15;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, CPConstraints)];
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
    [self updateInitialDeselectState];
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
        [self setAllTopicsUnchecked];
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
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, CPTopicHeight)];
    
    UISwitch* deselectSwitch = [[UISwitch alloc] init];
    CGSize switchSize = [deselectSwitch sizeThatFits:CGSizeZero];
    deselectSwitch.frame = CGRectMake(tableView.bounds.size.width - (switchSize.width + CPTopicCellLeading), (CPTopicHeight - switchSize.height) / CPTopicHeightDivider, switchSize.width, switchSize.height);
    
    if ([CleverPush getNormalTintColor]) {
        deselectSwitch.onTintColor = [CleverPush getNormalTintColor];
    } else {
        deselectSwitch.onTintColor = [UIColor systemGreenColor];
    }
    
    [deselectSwitch addTarget:self action:@selector(deselectEverything:) forControlEvents:UIControlEventValueChanged];
    [headerView addSubview:deselectSwitch];
    
    if ([CleverPush getDeselectValue] == YES) {
        deselectSwitch.on = YES;
    } else {
        deselectSwitch.on = NO;
    }
    
    UILabel* deselectEverything = [[UILabel alloc] init];
    deselectEverything.text = [CPTranslate translate:@"deselectEverything"];
    deselectEverything.frame = CGRectMake(CPTopicCellLeading, (CPTopicHeight - switchSize.height) / CPTopicHeightDivider, tableView.bounds.size.width - (switchSize.width + CPTopicCellLeading), switchSize.height);
    [headerView addSubview:deselectEverything];
    
    return headerView;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    CPTopicDialogCell *cell = (CPTopicDialogCell *)[tableView dequeueReusableCellWithIdentifier:@"CPTopicDialogCell"];
    cell.backgroundColor = [UIColor clearColor];
    NSBundle *bundle = [CPUtils getAssetsBundle];
    NSArray *nibs = [[NSArray alloc]init];
    if (bundle) {
        nibs = [[bundle loadNibNamed:@"CPTopicDialogCell" owner:self options:nil] lastObject];
    } else {
        nibs = [[[NSBundle mainBundle] loadNibNamed:@"CPTopicDialogCell" owner:nil options:nil] lastObject];
    }
    if (cell == nil) {
        cell = nibs[0];
    }
    int row = (int)indexPath.row;
    CPChannelTopic *topic = [self getTopic:row];
    
    NSString* topicId = [topic id];
    int topicIndex = [self getTopicIndex:topicId];
    
    cell.operatableSwitch.tag = topicIndex + 1;
    cell.operatableSwitch.on = [self defaultTopicState:topic] ? YES : NO;
    [cell.operatableSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    if ([CleverPush getNormalTintColor]) {
        cell.operatableSwitch.onTintColor = [CleverPush getNormalTintColor];
    } else {
        cell.operatableSwitch.onTintColor = [UIColor systemGreenColor];
    }
    if ([topic parentTopic]) {
        float inset = CPConstraints;
        cell.leadingConstraints.constant = inset;
        cell.operatableSwitch.on = [self defaultTopicState:topic];
    } else {
        float inset = CPTopicCellLeading;
        cell.leadingConstraints.constant = inset;
    }
    NSDate *addedCacheDelay = [[topic createdAt] dateByAddingTimeInterval:+60*60];
    NSComparisonResult result;
    result = [addedCacheDelay compare:[CPUtils getLastTopicCheckedTime]];
    
    if (self.topicsDialogShowWhenNewAdded && result == NSOrderedDescending) {
        cell.topicHighlighter.hidden = NO;
        if ([CleverPush getBrandingColor]) {
            cell.topicHighlighter.textColor = [CleverPush getBrandingColor];
        } else {
            cell.topicHighlighter.textColor = [UIColor systemBlueColor];
        }
    } else {
        cell.topicHighlighter.hidden = YES;
    }
    
    cell.titleText.text = [topic name];
    cell.titleText.tag = 200;
    cell.titleText.backgroundColor = [UIColor clearColor];
    cell.accessibilityLabel = cell.titleText.text;
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

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    if (self.topicsDialogShowUnsubscribe == NO) {
        return 0;
    } else {
        return CPTopicHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section {
    return 0;
}

@end
