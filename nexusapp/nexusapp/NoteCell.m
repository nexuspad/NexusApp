//
//  NoteCell.m
//  nexuspad
//
//  Created by Ren Liu on 8/24/12.
//
//

#import "NoteCell.h"

@interface NoteCell ()
@end

@implementation NoteCell

@synthesize noteFont;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.detailTextLabel != nil) {
        if ([self.detailTextLabel.text length] > 0) {
            self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
            self.detailTextLabel.numberOfLines = 0;

            NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:self.detailTextLabel.text
                                                                                 attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]}];
            
            CGRect calcRect = [attributedText boundingRectWithSize:CGSizeMake(self.detailTextLabel.frame.size.width, CGFLOAT_MAX)
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                           context:nil];
            
            CGSize noteSize = calcRect.size;

            CGRect rect = self.frame;
            
            if (noteSize.height < 44) {
                rect.size.height = 52.0;
            } else {
                rect.size.height = noteSize.height + 15.0;      // Add some paddings.
            }
            
            self.frame = rect;
        }

    } else {
        if ([self.textLabel.text length] > 0) {
            self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            self.textLabel.numberOfLines = 0;
            
            if (self.noteFont == nil) {
                self.noteFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            }
            
            self.textLabel.font = self.noteFont;

            NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:self.textLabel.text
                                                                                 attributes:@{NSFontAttributeName:self.noteFont}];
            
            CGRect calcRect = [attributedText boundingRectWithSize:CGSizeMake(self.textLabel.frame.size.width, CGFLOAT_MAX)
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                           context:nil];
            
            CGSize noteSize = calcRect.size;

            CGRect rect = self.frame;
            
            if (noteSize.height < 44) {
                rect.size.height = 52.0;
            } else {
                rect.size.height = noteSize.height + 15.0;      // Add some paddings.
            }
            
            self.frame = rect;
        }
    }
}

@end
