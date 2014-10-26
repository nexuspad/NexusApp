//
//  ColorTile.h
//  nexuspad
//
//  Created by Ren Liu on 9/14/12.
//
//

#import <UIKit/UIKit.h>

@interface ColorTile : UILabel

@property (nonatomic, strong) NSString *colorHexString;

- (id)initWithColor:(CGRect)frame hexColor:(NSString*)hexColor;

@end
