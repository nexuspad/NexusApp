//
//  Attachment.h
//  nexuspad
//
//  Created by Ren Liu on 8/17/12.
//
//
#import <Foundation/Foundation.h>
#import "Constants.h"
#import "AccessEntitlement.h"

@interface NPUpload : NSObject

// This is only used to carry access information for photo lightbox display
// It is assigned when thumbnail is selected in didSelectItem...
@property (nonatomic, strong) AccessEntitlement *accessInfo;

@property (nonatomic, strong) NSNumber *ownerId;

@property int moduleId;
@property int folderId;
@property (nonatomic, strong) NSString *entryId;
@property (nonatomic, strong) NSDate *createDate;

@property (nonatomic, strong) NSString *parentEntryId;
@property int parentEntryModule;
@property int parentEntryFolder;

@property (nonatomic, strong) NSString *fileName;
@property long fileSize;
@property (nonatomic, strong) NSString *fileType;
@property (nonatomic, strong) NSString *fileDownloadLink;

@property (nonatomic, strong) NSString *tnUrl;
@property (nonatomic, strong) NSString *url;

@property (nonatomic, weak) UIImage *thumbnailImage;

- (NSString*)photoUrl;

@property NSInteger displayIndex;

@end
