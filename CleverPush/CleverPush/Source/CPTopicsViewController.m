#import "CPTopicsViewController.h"
#import <CleverPush/CleverPush.h>
#import "IntrinsicTableView.h"

@implementation CPTopicsViewController

- (id)initWithAvailableTopics:(NSArray*)topics selectedTopics:(NSArray*)userTopics hasSubscriptionTopics:(BOOL)hasTopics_ {
    self = [super init];
    if (self) {
        availableTopics = [NSMutableArray new];
        selectedTopics = [NSMutableArray arrayWithArray:userTopics];
        hasTopics = hasTopics_;
        
        childTopics = [NSMutableDictionary new];
        parentTopics = [NSMutableArray new];
        for (NSDictionary *topic in topics) {
            NSString* parentTopicId = [topic objectForKey:@"parentTopic"];
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
        
        for (NSDictionary *topic in parentTopics) {
            NSString* parentTopicId = [topic objectForKey:@"_id"];
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

- (NSMutableArray*)getSelectedTopics {
    return selectedTopics;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    tableView = [[IntrinsicTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
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
        
        // add some padding
        tableView.tableHeaderView.frame = CGRectMake(tableView.tableHeaderView.frame.origin.x, tableView.tableHeaderView.frame.origin.y, tableView.tableHeaderView.frame.size.width, tableView.tableHeaderView.frame.size.height + labelPaddingBottom);
        
        [tableView reloadData];
    }
}

- (void)switchChanged:(id)sender {
    UISwitch* switcher = (UISwitch*)sender;
    NSDictionary* topic = availableTopics[(int) switcher.tag - 1];
    
    if (topic) {
        NSString* topicId = [topic objectForKey:@"_id"];
        BOOL contains = [selectedTopics containsObject:topicId];
        if (switcher.on && !contains) {
            [selectedTopics addObject:topicId];
        } else if (!switcher.on && contains) {
            [selectedTopics removeObject:topicId];
        }
        
        hasTopics = YES;
        
        [tableView reloadData];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int count = 0;
    for (NSDictionary *topic in availableTopics) {
        NSString* parentTopicId = [topic objectForKey:@"parentTopic"];
        if (!parentTopicId || [selectedTopics containsObject:parentTopicId]) {
            count += 1;
        }
    }
    return count;
}

- (NSDictionary*)getTopic:(int)row {
    int count = -1;
    for (NSDictionary *topic in availableTopics) {
        NSString* parentTopicId = [topic objectForKey:@"parentTopic"];
        if (!parentTopicId || [selectedTopics containsObject:parentTopicId]) {
            count += 1;
        }
        if (count >= row) {
            return topic;
        }
    }
    return nil;
}

- (int)getTopicIndex:(NSString*)topicId {
    int index = -1;
    for (NSDictionary *topic in availableTopics) {
        index += 1;
        NSString* topicIdCurrent = [topic objectForKey:@"_id"];
        if ([topicIdCurrent isEqualToString:topicId]) {
            return index;
        }
    }
    return -1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int row = (int)indexPath.row;
    NSDictionary *topic = [self getTopic:row];
    
    NSString* topicId = [topic objectForKey:@"_id"];
    int topicIndex = [self getTopicIndex:topicId];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    int tag = topicIndex + 1;
    UISwitch* switcher = (UISwitch*)[cell.contentView viewWithTag:tag];
    [switcher setOn:!switcher.on animated:YES];
    
    [self switchChanged:switcher];
}

- (BOOL)defaultTopicState:(NSDictionary*)topic {
    BOOL defaultUnchecked = NO;
    if (topic && [topic objectForKey:@"defaultUnchecked"]) {
        defaultUnchecked = YES;
    }
    BOOL state = (([selectedTopics count] == 0 && !hasTopics && !defaultUnchecked) || [selectedTopics containsObject:[topic objectForKey:@"_id"]]);
    return state;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    int row = (int)indexPath.row;
    NSDictionary *topic = [self getTopic:row];
    
    NSString* topicId = [topic objectForKey:@"_id"];
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
        
        if ([topic objectForKey:@"parentTopic"]) {
            float inset = 30.0f;
            labelFrame.size.width -= inset;
            labelFrame.origin.x += inset;
        }
        
        l.frame = labelFrame;
        l.tag = 200;
        l.backgroundColor = [UIColor clearColor];
        cell.accessibilityLabel = l.text;
        [cell.contentView addSubview:l];
    }
    
    UISwitch *switcher = (UISwitch*)[cell.contentView viewWithTag:(topicIndex + 1)];
    UILabel *nameLabel = (UILabel*)[cell.contentView viewWithTag:200];
    
    nameLabel.text = [topic objectForKey:@"name"];
    
    switcher.on = [self defaultTopicState:topic] ? YES : NO;
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

@end
