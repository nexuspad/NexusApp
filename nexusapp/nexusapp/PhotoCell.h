//
//  PhotoCell.h
//  nexuspad
//
//  Created by Ren Liu on 8/3/12.
//
//

#import <UIKit/UIKit.h>

@interface PhotoCell : UITableViewCell

- (void)displayFromUrl:(NSString*)imageUrlStr textValue:(NSString*)textValue;

- (void)displayFromImage:(UIImage*)image textValue:(NSString*)textValue;

@end
