//
//  ColorPaletteView.m
//  nexuspad
//
//  Created by Ren Liu on 9/13/12.
//
//

#import "ColorPaletteView.h"
#import "ViewDisplayHelper.h"
#import "UIBarButtonItem+NPUtil.h"

static float colorLabelSize = 50.0;
static float TOOLBAR_HEIGHT = 32.0;

@interface ColorPaletteView ()
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) NSArray *colors;
@property int rows;
@property int cols;
@end

@implementation ColorPaletteView


- (id)initWithToolBar:(UIView*)parentView
{
    // Labels are laid out 6x5. Each label is 50x50.
    // The height is 250 + 44 (toolbar)
    CGRect initialRect = CGRectMake(0.0f, [ViewDisplayHelper screenHeight], [ViewDisplayHelper screenWidth], 294.0f);

    self = [super initWithFrame:initialRect];
    
    self.frame = initialRect;
    self.backgroundColor = [UIColor colorWithRed:255.0/256 green:255.0/265 blue:255.0/256 alpha:0.6];
    

    // Create a tool bar on top
    self.toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0.0, 0.0, [ViewDisplayHelper screenWidth], TOOLBAR_HEIGHT)];

    // Transparent toolbar
    [self.toolbar setBarStyle:UIBarStyleDefault];
    self.toolbar.translucent = YES;
    
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *closeItem = [UIBarButtonItem barItemWithImage:[UIImage imageNamed:@"arrow-down-black.png"]
                                                            target:self
                                                            action:@selector(cancel)];

    NSMutableArray* toolbarItems = [NSMutableArray array];
    
    [toolbarItems addObject:spacer];
    [toolbarItems addObject:closeItem];
    self.toolbar.items = toolbarItems;

    [self addSubview:self.toolbar];
    
    self.rows = initialRect.size.width/colorLabelSize;
    self.cols = (initialRect.size.height - 44.0)/colorLabelSize;
    
    [self addTiles];

    return self;
}


- (void)addTiles
{
    [self availableColors];
    
    float xOffset = 6.0;
    float yOffset = 44.0;               // Give space for toolbar

    int idx = 0;
    for (int i=0; i<self.rows; i++) {
        for (int j=0; j<self.cols; j++) {
            
            float x = i * (colorLabelSize + 1) + xOffset;
            float y = yOffset + j * (colorLabelSize + 1);

            CGRect rect = CGRectMake(x, y, colorLabelSize, colorLabelSize);
            NSString *colorHexStr = [self.colors objectAtIndex:idx++];
            
            ColorTile *colorTile = [[ColorTile alloc] initWithColor:rect hexColor:colorHexStr];
            
            colorTile.userInteractionEnabled = YES;
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapColorLabel:)];
            tap.delegate = self;
            [colorTile addGestureRecognizer:tap];
            
            [self addSubview:colorTile];
        }
    }
}

- (void)tapColorLabel:(UITapGestureRecognizer*)sender
{
    UILabel *colorLabel = (UILabel*)sender.view;
    [self.delegate setSelectedValue:colorLabel];
}

- (void)cancel
{
    [self slideOff];
}

- (void)slideOff
{
    self.isVisible = NO;
    CGRect offScreen = CGRectMake(0.0f, [ViewDisplayHelper screenHeight] + 20, [ViewDisplayHelper screenWidth], 294.0f);
    [UIView beginAnimations:@"animateTableView" context:nil];
    [UIView setAnimationDuration:0.4];
    [self setFrame:offScreen];
    [UIView commitAnimations];
}

- (void)slideIn:(UIView*)parentView
{
    self.isVisible = YES;
    [UIView beginAnimations:@"animateTableView" context:nil];
    [UIView setAnimationDuration:0.5];
    float yPos = parentView.frame.size.height - 304.0f;
    [self setFrame:CGRectMake(0.0f, yPos, [ViewDisplayHelper screenWidth], 304.0f)];
    
    [UIView commitAnimations];
}


- (void)availableColors
{
    NSMutableArray *allColors = [[NSMutableArray alloc] init];
    
    [allColors addObject:@"334433"];
    [allColors addObject:@"3366aa"];
    [allColors addObject:@"6699aa"];
    [allColors addObject:@"aabbbb"];
    [allColors addObject:@"778877"];
    [allColors addObject:@"77aa77"];
    [allColors addObject:@"aabbbb"];
    [allColors addObject:@"887777"];
    [allColors addObject:@"808000"];
    [allColors addObject:@"669999"];
    [allColors addObject:@"77bbcc"];
    [allColors addObject:@"556622"];
    [allColors addObject:@"334411"];
    [allColors addObject:@"aabb88"];
    [allColors addObject:@"99aa33"];
    [allColors addObject:@"556622"];
    [allColors addObject:@"447700"];
    [allColors addObject:@"aa7711"];
    [allColors addObject:@"886611"];
    [allColors addObject:@"996633"];
    [allColors addObject:@"665533"];
    [allColors addObject:@"ccaa88"];
    [allColors addObject:@"666655"];
    [allColors addObject:@"bb0000"];
    [allColors addObject:@"cc5500"];
    [allColors addObject:@"ffaa00"];
    [allColors addObject:@"eebb22"];
    [allColors addObject:@"aa8899"];
    [allColors addObject:@"ff5500"];
    [allColors addObject:@"ab2671"];
    [allColors addObject:@"9643a5"];
    [allColors addObject:@"d96666"];
    [allColors addObject:@"ad2d2d"];
    [allColors addObject:@"e6804d"];
    [allColors addObject:@"991111"];
    [allColors addObject:@"f9ea99"];
    [allColors addObject:@"b1ddf3"];
    [allColors addObject:@"eecd86"];
    [allColors addObject:@"d5d0b0"];
    [allColors addObject:@"ebebeb"];
    [allColors addObject:@"cdffff"];
    
    self.colors = [NSArray arrayWithArray:allColors];
}
@end
