//
//  RightListMenuHelper.m
//  nexusapp
//
//  Created by Ren Liu on 11/30/13.
//
//

#import "SharerRightMenu.h"
#import "NPFolder.h"
#import "AccessEntitlement.h"
#import "UIColor+NPColor.h"
#import "NSString+NPStringUtil.h"
#import "UIImageView+WebCache.h"
#import "NPWebApiService.h"
#import "UIImageView+NPUtil.h"

static UIColor *DARK_BG_COLOR;
static UIColor *SELECTION_BG_COLOR;

@interface SharerRightMenu ()
@end

@implementation SharerRightMenu

- (id)initWithFrame:(CGRect)frame {
    self = [super init];
    
    DARK_BG_COLOR = [UIColor colorFromHexString:@"3c3c3c"];
    SELECTION_BG_COLOR = [UIColor orangeColor];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    tableView.backgroundColor = DARK_BG_COLOR;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.menuView = tableView;
    
    return self;
}

- (void)selectMenuItem:(NPUser*)selectedUser {
    UITableView *tableView = (UITableView*)self.menuView;
    NSArray *cells = [tableView visibleCells];
    
    int i = 0;
    for (UITableViewCell *cell in cells) {
        NPUser *user = [self.menuItems objectAtIndex:i];
        if (user.userId == selectedUser.userId) {
            cell.contentView.backgroundColor = SELECTION_BG_COLOR;
        } else {
            cell.contentView.backgroundColor = DARK_BG_COLOR;
        }
        
        i++;
    }
}

- (void)refreshMenuItems {
    UITableView *tableView = (UITableView*)self.menuView;
    [tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"UserCell";

    UITableViewCell *cell = nil;

    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        UIImageView *profileView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 2, 40, 40)];
        profileView.tag = 10;
        profileView.image = [UIImage imageNamed:@"avatar.png"];
        [UIImageView roundedCorner:profileView];
        [cell.contentView addSubview:profileView];
        
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(56.0, 10.0, 260.0, 20.0)];
        nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        nameLabel.textColor = [UIColor whiteColor];
        nameLabel.tag = 11;
        [cell.contentView addSubview:nameLabel];

        cell.contentView.backgroundColor = DARK_BG_COLOR;
        
        UIView *selectionColor = [[UIView alloc] init];
        selectionColor.backgroundColor = SELECTION_BG_COLOR;
        cell.selectedBackgroundView = selectionColor;
    }
    
    NPUser *user = [self.menuItems objectAtIndex:indexPath.row];

    UILabel *nl = (UILabel*)[cell viewWithTag:11];
    if (indexPath.row == 0) {
        if (self.moduleId == CALENDAR_MODULE) {
            nl.text = NSLocalizedString(@"My events",);

        } else {
            NPFolder *rootFolder = [NPFolder initRootFolder:self.moduleId
                                                 accessInfo:[[AccessEntitlement alloc] initWithOwnerAndViewer:user
                                                                                                    theViewer:user]];
            nl.text = [rootFolder displayName];
        }
        
    } else {
        nl.text = [user getDisplayName];

    }
    
    NSString *profileImageUrl = [user getProfileImageUrl];
    
    if (![NSString isBlank:profileImageUrl]) {
        UIImageView *imgv = (UIImageView*)[cell viewWithTag:10];
        [imgv sd_setImageWithURL:[NSURL URLWithString:[NPWebApiService appendAuthParams:profileImageUrl]]
                  placeholderImage:[UIImage imageNamed:@"avatar.png"]
                           options:SDWebImageProgressiveDownload];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NPUser *user = [self.menuItems objectAtIndex:indexPath.row];
    [self selectMenuItem:user];

    [self.menuDelegate didSelectedSharer:user];
}


@end
