//
//  DocNoteEditorViewController.h
//  nexusapp
//
//  Created by Ren Liu on 8/15/13.
//
//

#import "EntryEditorViewController.h"
#import "NPDoc.h"

@interface DocNoteEditorViewController : EntryEditorViewController <UIPopoverControllerDelegate>

@property (nonatomic, strong) NPDoc *doc;
- (IBAction)saveDoc:(id)sender;
@end
