//
//  EventListViewCell.m
//  nexusapp
//
//  Created by Ren Liu on 2/5/13.
//
//
#import <QuartzCore/QuartzCore.h>

#import "EventListViewCell.h"
#import "UIColor+NPColor.h"
#import "DateUtil.h"

@interface EventListViewCell()
@property (nonatomic, strong) NSString *eventColorLabel;
@end
@implementation EventListViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        // The weekday and date label
        UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 8.0, 65.0, 40.0)];
        label1.tag = 20;
        label1.numberOfLines = 2;
        label1.lineBreakMode = NSLineBreakByWordWrapping;
        label1.font = [UIFont boldSystemFontOfSize:11.0];
        label1.layer.cornerRadius = 4;
        [self.contentView addSubview:label1];
        
        float titleLableWidth = self.contentView.frame.size.width - 6.0 - 75.0 - 4.0;   // color label width, lable 1 width, and a little padding
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(85.0, 5.0, titleLableWidth, 22.0)];
        titleLabel.tag = 30;
        titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        [self.contentView addSubview:titleLabel];
        
        // The time label
        UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(85.0, 33.0, titleLableWidth, 14.0)];
        label2.tag = 40;
        label2.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        label2.textColor = [UIColor darkGrayColor];
        [self.contentView addSubview:label2];
    }
    
    return self;
}

// Overwrite this method so the color label is preserved when the cell is selected.
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    UILabel *timeLabelLeft = (UILabel*)[self.contentView viewWithTag:20];
    UIColor *bgColor = [UIColor colorFromHexString:self.eventColorLabel];
    timeLabelLeft.textColor = [NSString textColorOnBackground:bgColor];
    timeLabelLeft.backgroundColor = bgColor;
}

- (void)showEvent:(NPEvent*)evt
{
    // Time on the left label
    NSString *timeText1 = [NSString stringWithFormat:@" %@\n %@", [DateUtil displayWeekday:evt.startTime], [DateUtil displayDate:evt.startTime]];
    
    // Time on the bottom of the row
    NSString *timeText2 = [NSString stringWithFormat:@"%@", evt.eventTimeText];
    
    self.eventColorLabel = [evt.colorLabel copy];
    
    UILabel *timeLabelLeft = (UILabel*)[self.contentView viewWithTag:20];
    timeLabelLeft.text = timeText1;
    UIColor *bgColor = [UIColor colorFromHexString:evt.colorLabel];
    timeLabelLeft.textColor = [NSString textColorOnBackground:bgColor];
    timeLabelLeft.backgroundColor = bgColor;
    
    UILabel *titleLabel = (UILabel*)[self.contentView viewWithTag:30];
    titleLabel.text = evt.title;
    
    NSDate *compareDate = [DateUtil startOfDate:[NSDate date]];
    
    if ([evt isPastEventToDate:compareDate]) {
        titleLabel.textColor = [UIColor grayColor];
    } else {
        titleLabel.textColor = [UIColor blackColor];
    }
    
    UILabel *timeLabelBottom = (UILabel*)[self.contentView viewWithTag:40];
    timeLabelBottom.text = timeText2;
    
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 5., 66.0, 44.0)];
    label1.numberOfLines = 2;
    label1.lineBreakMode = NSLineBreakByWordWrapping;
    label1.text = timeText1;
}

@end
