//
//  RightListMenuHelper.h
//  nexusapp
//
//  Created by Ren Liu on 11/30/13.
//
//

#import <Foundation/Foundation.h>
#import "NPUser.h"
#import "SlideMenu.h"

@interface SharerRightMenu : SlideMenu <UITableViewDataSource, UITableViewDelegate>

@property int moduleId;
@property (nonatomic, strong) NSArray *menuItems;

- (id)initWithFrame:(CGRect)frame;

- (void)selectMenuItem:(NPUser*)selectedUser;

- (void)refreshMenuItems;

@end
