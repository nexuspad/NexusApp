//
//  DocNoteEditorViewController.m
//  nexusapp
//
//  Created by Ren Liu on 8/15/13.
//
//

#import "DocNoteEditorViewController.h"
#import "ViewDisplayHelper.h"
#import "EntryActionResult.h"
#import "NotificationUtil.h"
#import "UIColor+NPColor.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "UIBarButtonItem+NPUtil.h"

@interface DocNoteEditorViewController ()
@property (nonatomic, strong) UITextRange *lastSelection;

@property (nonatomic, strong) UIPopoverController *popover;

@property (nonatomic, strong) NSCache *_imageViewCache;


// demonstrating inputAccessoryView
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIBarButtonItem *photoButton;

// font toggling
@property (nonatomic, strong) UIBarButtonItem *boldButton;
@property (nonatomic, strong) UIBarButtonItem *italicButton;
@property (nonatomic, strong) UIBarButtonItem *underlineButton;
@property (nonatomic, strong) UIBarButtonItem *strikeThroughButton;
@property (nonatomic, strong) UIBarButtonItem *highlightButton;

// paragraph alignment buttons
@property (nonatomic, strong) UIBarButtonItem *leftAlignButton;
@property (nonatomic, strong) UIBarButtonItem *centerAlignButton;
@property (nonatomic, strong) UIBarButtonItem *rightAlignButton;
@property (nonatomic, strong) UIBarButtonItem *justifyAlignButton;

// indent buttons
@property (nonatomic, strong) UIBarButtonItem *increaseIndentButton;
@property (nonatomic, strong) UIBarButtonItem *decreaseIndentButton;

// lists
@property (nonatomic, strong) UIBarButtonItem *unorderedListButton;
@property (nonatomic, strong) UIBarButtonItem *orderedListButton;


// URL
@property (nonatomic, strong) UIBarButtonItem *linkButton;

@property (nonatomic, strong) UIBarButtonItem *formatButton;

// Insert Menu
@property BOOL showInsertMenu;

@property (nonatomic, retain) NSCache *imageViewCache;

@property (nonatomic, retain) UIPopoverController *formatOptionsPopover;

@property (strong, nonatomic) IBOutlet UIView *titleWrapperView;
@property (weak, nonatomic) IBOutlet UITextField *docTitleTextField;

@end

@implementation DocNoteEditorViewController

@synthesize showInsertMenu = _showInsertMenu;

@synthesize doc = _doc;

- (void)setDoc:(NPDoc*)doc {
    _doc = doc;
}

- (IBAction)saveDoc:(id)sender {
    // Clear the old values
    [_doc.featureValuesDict removeAllObjects];
    
    _doc.title = self.docTitleTextField.text;
    _doc.note = nil;
    
    DLog(@"%@", [_doc buildParamMap]);
    
    [super postEntry:_doc];
}

- (void)updateServiceResult:(id)serviceResult {
    [ViewDisplayHelper dismissWaiting:self.view];
    
    if ([serviceResult isKindOfClass:[EntryActionResult class]]) {
        EntryActionResult *actionResponse = (EntryActionResult*)serviceResult;
        
        if ([actionResponse.name isEqualToString:@"delete_attachment"]) {
            
        } else if ([actionResponse.name isEqualToString:ACTION_ADD_ENTRY] || [actionResponse.name isEqualToString:ACTION_UPDATE_ENTRY]) {
            if (actionResponse.success) {
                if (actionResponse.entry != nil) {
                    _doc.entryId = actionResponse.entry.entryId;
                }
                
                NPDoc *returnedDoc = [actionResponse.entry copy];

                if (self.afterSavingDelegate != nil) {
                    [self.afterSavingDelegate entryUpdateSaved:returnedDoc];
                }
                
                [NotificationUtil sendEntryUpdatedNotification:returnedDoc];
                [self cancelEditor:nil];
            }
        }
    }
}


- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction {
    self.entryFolder = [selectedFolder copy];
    _doc.folder.folderId = selectedFolder.folderId;
    [ViewDisplayHelper popViewControllerBottomDown:self.navigationController];
}


- (void)loadDocView {
    if (_doc.note != nil) {
        //[self.richTextEditor setHTMLString:_doc.note];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self loadDocView];
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // This is for going back to the list, not the DocNoteViewController
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.docTitleTextField.text = _doc.title;

//    self.richTextEditor.editable = YES;
//    self.richTextEditor.defaultFontFamily = @"Arial";
//    self.richTextEditor.textSizeMultiplier = 1.5;
//    self.richTextEditor.autocorrectionType = UITextAutocorrectionTypeYes;
//	
//    self.richTextEditor.attributedTextContentView.shouldDrawImages = NO;
//    self.richTextEditor.attributedTextContentView.delegate = self;
    
    NSMutableArray *buttons = [[NSMutableArray alloc] init];
    
//    UIBarButtonItem *spacer = [UIBarButtonItem spacer];
//
//    self.boldButton = [UIBarButtonItem richEditorToolbarButton:[UIImage imageNamed:@"bold.png"] target:self action:@selector(formatDidToggleBold)];
//    [buttons addObject:self.boldButton];
//    
//    self.italicButton = [UIBarButtonItem richEditorToolbarButton:[UIImage imageNamed:@"italic.png"] target:self action:@selector(formatDidToggleItalic)];
//    [buttons addObject:self.italicButton];
//    
//    self.underlineButton = [UIBarButtonItem richEditorToolbarButton:[UIImage imageNamed:@"underline.png"] target:self action:@selector(formatDidToggleUnderline)];
//    [buttons addObject:self.underlineButton];
//    
//    self.strikeThroughButton = [UIBarButtonItem richEditorToolbarButton:[UIImage imageNamed:@"strikethrough.png"] target:self action:@selector(formatDidToggleStrikethrough)];
//    [buttons addObject:self.strikeThroughButton];
//
//    [buttons addObject:spacer];
//    
//	self.leftAlignButton = [UIBarButtonItem richEditorToolbarButton:[UIImage imageNamed:@"align-left.png"] target:self action:@selector(toggleLeft:)];
//    [buttons addObject:self.leftAlignButton];
//
//    self.centerAlignButton = [UIBarButtonItem richEditorToolbarButton:[UIImage imageNamed:@"align-center.png"] target:self action:@selector(toggleCenter:)];
//    
//    self.rightAlignButton = [UIBarButtonItem richEditorToolbarButton:[UIImage imageNamed:@"align-right.png"] target:self action:@selector(toggleRight:)];
//    [buttons addObject:self.rightAlignButton];
//    
//    [buttons addObject:spacer];
    
//    self.justifyAlignButton = [UIBarButtonItem richEditorToolbarButton:[UIImage imageNamed:@"align-justified.png"] target:self action:@selector(toggleJustify:)];
//
//	self.increaseIndentButton = [UIBarButtonItem richEditorToolbarButton:[UIImage imageNamed:@"indent.png"] target:self action:@selector(increaseTabulation)];
//    [buttons addObject:self.increaseIndentButton];
//    
//	self.decreaseIndentButton = [UIBarButtonItem richEditorToolbarButton:[UIImage imageNamed:@"outdent.png"] target:self action:@selector(decreaseTabulation)];
//    [buttons addObject:self.decreaseIndentButton];
//    
//    [buttons addObject:spacer];
    
//    self.formatButton = [UIBarButtonItem richEditorToolbarButton:[UIImage imageNamed:@"more.png"] target:self action:@selector(presentFormatOptions:)];
//
//    [buttons addObject:self.formatButton];
//    
//    [buttons addObject:spacer];
//
//	self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
//    
//    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
//        self.toolbar.tintColor = [UIColor colorFromHexString:@"eeeeee"];
//    }

//	self.richTextEditor.inputAccessoryView = self.toolbar;
	[self.toolbar setItems:buttons];
    
    // notifications
//    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
//	[center addObserver:self selector:@selector(menuDidHide:) name:UIMenuControllerDidHideMenuNotification object:nil];
//
//    [center addObserver:self selector:@selector(keyboardDidShowInitAdditionalFormattingInput:) name:UIKeyboardDidShowNotification object:nil];
}
//
//- (void)viewDidAppear:(BOOL)animated {
//	[super viewDidAppear:animated];
//    
//    // Must be placed in viewDidAppear. Otherwise the DTRichTextEditor will crash.
////    [self.richTextEditor becomeFirstResponder];
//}
//
//- (void)viewDidUnload {
//    [super viewDidUnload];
//}
//
//
//#pragma mark - DTRichTextEditorViewDelegate
//
//- (BOOL)editorViewShouldBeginEditing:(DTRichTextEditorView *)editorView {
//    DLog(@".....editorViewShouldBeginEditing:");
//    return YES;
//}
//
//- (void)editorViewDidBeginEditing:(DTRichTextEditorView *)editorView
//{
//    DLog(@".....editorViewDidBeginEditing:");
//}
//
//- (BOOL)editorViewShouldEndEditing:(DTRichTextEditorView *)editorView
//{
//    DLog(@".....editorViewShouldEndEditing:");
//    return YES;
//}
//
//- (void)editorViewDidEndEditing:(DTRichTextEditorView *)editorView
//{
//    DLog(@".....editorViewDidEndEditing:");
//}
//
//- (BOOL)editorView:(DTRichTextEditorView *)editorView shouldChangeTextInRange:(NSRange)range replacementText:(NSAttributedString *)text
//{
//    DLog(@".....editorView:shouldChangeTextInRange:replacementText:");
//    
//    return YES;
//}
//
//- (void)editorViewDidChange:(DTRichTextEditorView *)editorView
//{
//    DLog(@".....editorViewDidChange:");
//}
//
//- (BOOL)editorView:(DTRichTextEditorView *)editorView canPerformAction:(SEL)action withSender:(id)sender
//{
//    DTTextRange *selectedTextRange = (DTTextRange *)editorView.selectedTextRange;
//    BOOL hasSelection = ![selectedTextRange isEmpty];
//    
//    if (action == @selector(insertStar:) || action == @selector(insertWhiteStar:)) {
//        return _showInsertMenu;
//    }
//    
//    if (_showInsertMenu) {
//        return NO;
//    }
//    
//    if (action == @selector(displayInsertMenu:)) {
//        return (!hasSelection && _showInsertMenu == NO);
//    }
//    
//    // For fun, disable selectAll:
//    if (action == @selector(selectAll:)) {
//        return NO;
//    }
//    
//    return YES;
//}

- (void)menuDidHide:(NSNotification *)notification
{
    _showInsertMenu = NO;
}

- (void)displayInsertMenu:(id)sender
{
    _showInsertMenu = YES;
    
    [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
}

//- (void)insertStar:(id)sender
//{
//    _showInsertMenu = NO;
//    
//    [self.richTextEditor insertText:@"★"];
//}
//
//- (void)insertWhiteStar:(id)sender
//{
//    _showInsertMenu = NO;
//    
//    [self.richTextEditor insertText:@"☆"];
//}
//
//- (void)formatterFinished {
//	self.richTextEditor.inputAccessoryView = self.toolbar; // restore accessory on next inputView change
//	[self.richTextEditor setInputView:nil animated:YES];
//}
//
//
///*
// * This is to initialize the formatting input view upon the appearance of the keyboard.
// */
//- (void)keyboardDidShowInitAdditionalFormattingInput:(NSNotification*)notification {
//    if (self.richTextFormattingInputView == nil) {
//        NSDictionary *attributesDictionary = [self.richTextEditor typingAttributesForRange:self.richTextEditor.selectedTextRange];
//        [attributesDictionary setValue:[self.richTextEditor fontDescriptorForRange:self.richTextEditor.selectedTextRange]
//                                forKey:@"FontDescriptor"];
//        
//        CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)[attributesDictionary objectForKey:(id)kCTParagraphStyleAttributeName];
//        DTCoreTextParagraphStyle *dtstyle = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:paragraphStyle];
//        [attributesDictionary setValue:dtstyle forKey:@"ParagraphAlignment"];
//        
//        CGRect rect = CGRectMake(0, 0, 320, 284);
//        
//        self.richTextFormattingInputView = [[RichTextFormattingInputView alloc] initWithFrameAndAttributes:rect
//                                                                                          formatAttributes:attributesDictionary
//                                                                                            formatDelegate:self];
//        
//    }
//}
//
//
//#pragma mark - DTAttributedTextContentViewDelegate
//
//- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttachment:(DTTextAttachment *)attachment frame:(CGRect)frame
//{
//    NSNumber *cacheKey = [NSNumber numberWithUnsignedInteger:[attachment hash]];
//    
//    UIImageView *imageView = [self.imageViewCache objectForKey:cacheKey];
//    
//    if (imageView) {
//        imageView.frame = frame;
//        return imageView;
//    }
//    
//    if ([attachment isKindOfClass:[DTImageTextAttachment class]]) {
//        DTImageTextAttachment *imageAttachment = (DTImageTextAttachment *)attachment;
//        
//        imageView = [[UIImageView alloc] initWithFrame:frame];
//        
//        NSString *imageUrl = [imageAttachment.attributes valueForKey:@"src"];
//        
//        if (imageUrl != nil && imageUrl.length > 0) {
//            if ([imageUrl rangeOfString:@"nexuspad.com"].location != NSNotFound) {
//                imageUrl = [NPWebApiService appendAuthParams:imageUrl];
//            }
//            
//            __weak UIImageView *weakImageViewRef = imageView;
//            
//            [imageView setImageWithURL:[NSURL URLWithString:imageUrl]
//                      placeholderImage:[UIImage imageNamed:@"placeholder.png"]
//                               options:SDWebImageProgressiveDownload
//                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
//                                 if (error != nil) {
//                                     NSLog(@"%@", [error description]);
//                                 } else {
//                                     CGSize imageSize = image.size;
//                                     if (image.size.width > 320.0) {
//                                         imageSize.width = 320.0;
//                                         imageSize.height = image.size.height * (imageSize.width / image.size.width);
//                                     }
//                                     
//                                     CGRect rect = weakImageViewRef.frame;
//                                     rect.size = imageSize;
//                                     weakImageViewRef.frame = rect;
//                                 }
//                             }];
//            
//            
////            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
////            UIImage *theImage = [UIImage imageWithData:imageData];
////            CGSize imageSize = theImage.size;
////            if (theImage.size.width > 320.0) {
////                imageSize.width = 320.0;
////                imageSize.height = theImage.size.height * (imageSize.width / theImage.size.width);
////            }
////            CGRect rect = imageView.frame;
////            rect.size = imageSize;
////            imageView.frame = rect;
////            imageView.image = theImage;
//        }
//        
//        return imageView;
//        
//    } else if ([attachment isKindOfClass:[DTIframeTextAttachment class]]) {
//        DTIframeTextAttachment *iframeAttachment = (DTIframeTextAttachment*)attachment;
//        UIWebView *iframeWebView = [[UIWebView alloc] initWithFrame:frame];
//        
//        NSString *embedUrl = [iframeAttachment.attributes valueForKey:@"src"];
//        NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:embedUrl]
//                                                 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
//        
//        [iframeWebView loadRequest:request];
//        
//        return iframeWebView;
//    }
//	
//	return nil;
//}
//
//
//- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForLink:(NSURL *)url identifier:(NSString *)identifier frame:(CGRect)frame
//{
//	DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:frame];
//	button.URL = url;
//	button.minimumHitSize = CGSizeMake(25, 25); // adjusts it's bounds so that button is always large enough
//	button.GUID = identifier;
//	
//	// use normal push action for opening URL
//	[button addTarget:self action:@selector(linkPushed:) forControlEvents:UIControlEventTouchUpInside];
//	
//	// demonstrate combination with long press
//	//UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(linkLongPressed:)];
//	//[button addGestureRecognizer:longPress];
//	
//	return button;
//}
//
//- (void)linkPushed:(id)sender {
//	// do something when a link was pushed
//}
//
//
//#pragma mark Properties
//
//- (NSCache *)imageViewCache
//{
//    if (!_imageViewCache)
//    {
//        _imageViewCache = [[NSCache alloc] init];
//    }
//    
//    return _imageViewCache;
//}
//
//
//#pragma mark - DTFormatDelegate
//- (void)formatDidSelectFont:(DTCoreTextFontDescriptor *)font
//{
//    [self.richTextEditor updateFontInRange:self.richTextEditor.selectedTextRange
//               withFontFamilyName:font.fontFamily
//                        pointSize:font.pointSize];
//}
//
//- (void)formatDidToggleBold
//{
//    [self.richTextEditor toggleBoldInRange:self.richTextEditor.selectedTextRange];
//}
//
//- (void)formatDidToggleItalic
//{
//    [self.richTextEditor toggleItalicInRange:self.richTextEditor.selectedTextRange];
//}
//
//- (void)formatDidToggleUnderline
//{
//    [self.richTextEditor toggleUnderlineInRange:self.richTextEditor.selectedTextRange];
//}
//
//- (void)formatDidToggleStrikethrough
//{
//    [self.richTextEditor toggleStrikethroughInRange:self.richTextEditor.selectedTextRange];
//}
//
//- (void)toggleHighlight:(UIBarButtonItem *)sender
//{
//	UITextRange *range = self.richTextEditor.selectedTextRange;
//	[self.richTextEditor toggleHighlightInRange:range color:[UIColor yellowColor]];
//}
//
//- (void)toggleLeft:(UIBarButtonItem *)sender
//{
//	UITextRange *range = self.richTextEditor.selectedTextRange;
//	[self.richTextEditor applyTextAlignment:kCTLeftTextAlignment toParagraphsContainingRange:range];
//}
//
//- (void)toggleCenter:(UIBarButtonItem *)sender
//{
//	UITextRange *range = self.richTextEditor.selectedTextRange;
//	[self.richTextEditor applyTextAlignment:kCTCenterTextAlignment toParagraphsContainingRange:range];
//}
//
//- (void)toggleRight:(UIBarButtonItem *)sender
//{
//	UITextRange *range = self.richTextEditor.selectedTextRange;
//	[self.richTextEditor applyTextAlignment:kCTRightTextAlignment toParagraphsContainingRange:range];
//}
//
//- (void)toggleJustify:(UIBarButtonItem *)sender
//{
//	UITextRange *range = self.richTextEditor.selectedTextRange;
//	[self.richTextEditor applyTextAlignment:kCTJustifiedTextAlignment toParagraphsContainingRange:range];
//}
//
//- (void)formatDidChangeTextAlignment:(CTTextAlignment)alignment
//{
//    UITextRange *range = self.richTextEditor.selectedTextRange;
//	[self.richTextEditor applyTextAlignment:alignment toParagraphsContainingRange:range];
//}
//
//- (void)increaseTabulation {
//	UITextRange *range = self.richTextEditor.selectedTextRange;
//	[self.richTextEditor changeParagraphLeftMarginBy:18 toParagraphsContainingRange:range];
//}
//
//- (void)decreaseTabulation {
//	UITextRange *range = self.richTextEditor.selectedTextRange;
//	[self.richTextEditor changeParagraphLeftMarginBy:-18 toParagraphsContainingRange:range];
//}
//
//- (void)toggleListType:(DTCSSListStyleType)listType
//{
//    UITextRange *range = self.richTextEditor.selectedTextRange;
//	
//	DTCSSListStyle *listStyle = [[DTCSSListStyle alloc] init];
//	listStyle.startingItemNumber = 1;
//    listStyle.position = listType;
//	listStyle.type = listType;
//	
//	[self.richTextEditor toggleListStyle:listStyle inRange:range];
//}
//
//- (void)replaceCurrentSelectionWithPhoto:(UIImage *)image {
//}
//
//- (void)applyHyperlinkToSelectedText:(NSURL *)url
//{
//    UITextRange *range = self.richTextEditor.selectedTextRange;
//    
//    [self.richTextEditor toggleHyperlinkInRange:range URL:url];
//}


#pragma mark - Presenting Format Options

@synthesize formatOptionsPopover = _formatOptionsPopover;

- (void)presentFormatOptions:(id)sender
{
//    self.richTextEditor.inputAccessoryView = nil;
//    
//    [self.richTextEditor setInputView:self.richTextFormattingInputView animated:YES];
//    
}

@end
