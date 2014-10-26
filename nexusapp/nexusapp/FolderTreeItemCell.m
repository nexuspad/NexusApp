//
//  FolderListCell.m
//  nexusapp
//
//  Created by Ren Liu on 10/15/13.
//
//

#import "FolderTreeItemCell.h"
#import "UIColor+NPColor.h"
#import "NPWebApiService.h"
#import "UIImageView+WebCache.h"

@interface FolderTreeItemCell ()
@property (nonatomic, strong) UIButton *subFolderButn;
@property (nonatomic, strong) UIButton *calendarViewButn;
@end

// A UITableViewCell customization that put the accessory view in the right place
@implementation FolderTreeItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)layoutSubviews {
    if (self.folder.moduleId == CALENDAR_MODULE) {
        if ([self.folder.accessInfo iAmOwner]) {
            if (self.folder.folderId != ROOT_FOLDER) {
                UIGraphicsBeginImageContext(CGSizeMake(15.0f, 15.0f));
                CGContextRef contextRef = UIGraphicsGetCurrentContext();
                CGContextSetFillColorWithColor(contextRef, [[UIColor colorFromHexString:self.folder.colorLabel] CGColor]);
                CGContextFillEllipseInRect(contextRef,(CGRectMake (0.f, 0.f, 15.0f, 15.0f)));
                UIImage *dot = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                self.imageView.image = dot;
            } else {
                self.imageView.image = nil;
            }
            
        } else {
            if (self.folder.folderId == ROOT_FOLDER) {
                [self.imageView sd_setImageWithURL:[NSURL URLWithString:[NPWebApiService appendAuthParams:self.folder.accessInfo.owner.profileImageUrl]]
                               placeholderImage:[UIImage imageNamed:@"avatar.png"]
                                        options:SDWebImageProgressiveDownload];
            } else {
                self.imageView.image = nil;
            }
        }        
    } else {
        if (self.folder.folderId == ROOT_FOLDER) {
            if ([self.folder.accessInfo iAmOwner]) {
                self.imageView.image = [UIImage imageNamed:@"icon-folder.png"];
            } else {
                [self.imageView sd_setImageWithURL:[NSURL URLWithString:[NPWebApiService appendAuthParams:self.folder.accessInfo.owner.profileImageUrl]]
                               placeholderImage:[UIImage imageNamed:@"avatar.png"]
                                        options:SDWebImageProgressiveDownload];
            }
            
        } else {
            if (self.lastItemInTree) {
                self.imageView.image = [UIImage imageNamed:@"icon-folder-tree-last.png"];
            } else {
                self.imageView.image = [UIImage imageNamed:@"icon-folder-tree.png"];
            }
        }
    }
    
//    if (self.folder.moduleId == CALENDAR_MODULE) {
//        [self.accessoryView setFrame:CGRectMake(self.frame.size.width - 40.0, 0, 40.0, 40.0)];
//
//    } else {
//        [self.accessoryView setFrame:CGRectMake(self.frame.size.width - 60.0, 0, 60.0, 40.0)];
//        [self.editingAccessoryView setFrame:CGRectMake(self.frame.size.width - 60.0, 0, 60.0, 40.0)];
//    }
    
    [super layoutSubviews];

}


- (void)setSubfolderButton:(id)target action:(SEL)action {
    /*
     * We user folder Id to set the accessory view tag.
     * We don't user row Id here so we don't have to deal with the case when row Id is the ROOT folder.
     */
    if (self.folder.folderId != ROOT_FOLDER) {
        self.subFolderButn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.subFolderButn.frame = CGRectMake(self.contentView.frame.size.width - 70.0f, 2.0f, 60.0f, 40.0f);
        [self.subFolderButn setBackgroundImage:[UIImage imageNamed:@"subfolder.png"] forState:UIControlStateNormal];
        
        self.subFolderButn.tag = self.folder.folderId;
        [self.subFolderButn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        
        if ([self.folder.accessInfo iAmOwner]) {
            if (self.folder.subFolders.count > 0) {
                [self.contentView addSubview:self.subFolderButn];
                
            } else {
                [self removeSubFolderButton:self.contentView];
            }
            
        } else {
            if (self.folder.subFolders.count > 0) {
                [self.contentView addSubview:self.subFolderButn];
            } else {
                [self removeSubFolderButton:self.contentView];
            }
        }
    } else {
        [self removeSubFolderButton:self.contentView];
    }
}


- (void)setCalendarViewButton:(id)target action:(SEL)action {
    /*
     * We user folder Id to set the accessory view tag.
     * We don't user row Id here so we don't have to deal with the case when row Id is the ROOT folder.
     */
    if (self.folder.folderId != ROOT_FOLDER) {
        self.calendarViewButn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.calendarViewButn.frame = CGRectMake(self.contentView.frame.size.width - 70.0f, 2.0f, 60.0f, 40.0f);

        if (!self.folder.isCalendarHidden) {
            [self.calendarViewButn setImage:[UIImage imageNamed:@"checkmark.png"] forState:UIControlStateNormal];
            self.calendarViewButn.tag = self.folder.folderId;
            [self.calendarViewButn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
            
        } else {
            [self.calendarViewButn setImage:[UIImage imageNamed:@"minus.png"] forState:UIControlStateNormal];
            self.calendarViewButn.tag = self.folder.folderId;
            [self.calendarViewButn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        }
        
        [self.contentView addSubview:self.calendarViewButn];

    } else {
        [self removeSubFolderButton:self.contentView];
    }
}


- (void)removeSubFolderButton:(UIView*)containerView {
    for (UIView *subView in [containerView subviews]) {
        if ([subView isKindOfClass:[UIButton class]]) {
            [subView removeFromSuperview];
        }
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
