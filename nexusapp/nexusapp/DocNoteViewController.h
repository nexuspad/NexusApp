//
//  DocNoteViewController.h
//  nexusapp
//
//  Created by Ren Liu on 8/15/13.
//
//

#import "EntryDetailViewController.h"
#import "ZSSRichTextEditor.h"
#import "NPDoc.h"

//@interface DocNoteViewController : EntryDetailViewController <UICollectionViewDelegate,
//                                                                UICollectionViewDataSource,
//                                                                UIGestureRecognizerDelegate,
//                                                                UIActionSheetDelegate>

@interface DocNoteViewController : ZSSRichTextEditor <UICollectionViewDelegate,
                                                        UICollectionViewDataSource,
                                                        UIGestureRecognizerDelegate,
                                                        UIActionSheetDelegate>

@property (nonatomic, strong) NPDoc *doc;

@end
