#import <UIKit/UIKit.h>
#import <SWTableViewCell.h>

#import "CreateStudyGroupTableViewController.h"

@interface StudyGroupsTableViewCell : SWTableViewCell
@property (nonatomic, weak) IBOutlet UILabel *classNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;

@end
