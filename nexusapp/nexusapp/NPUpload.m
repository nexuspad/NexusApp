//
//  Attachment.m
//  nexuspad
//
//  Created by Ren Liu on 8/17/12.
//
//

#import "NPUpload.h"

@implementation NPUpload

@synthesize moduleId, folderId, entryId, createDate, parentEntryId, parentEntryModule, parentEntryFolder, fileType, fileName, fileDownloadLink, tnUrl, url, displayIndex, thumbnailImage, accessInfo;

- (id)init
{
    self = [super init];
    if (self) {
        self.moduleId = UPLOAD_MODULE;
        self.folderId = 0;
        return self;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone
{
    NPUpload *att = [[NPUpload alloc] init];
    att.moduleId = self.moduleId;
    att.folderId = self.folderId;
    
    if (self.entryId != nil) {
        att.entryId = [NSString stringWithString:self.entryId];
    }
    
    if (self.createDate != nil) {
        att.createDate = [self.createDate copy];
    }
    
    att.parentEntryId = [NSString stringWithString:self.parentEntryId];
    att.parentEntryModule = self.parentEntryModule;
    att.parentEntryFolder = self.parentEntryFolder;
    
    if (self.fileType != nil) {
        att.fileType = [NSString stringWithString:self.fileType];        
    }

    if (self.fileName != nil) {
        att.fileName = [NSString stringWithString:self.fileName];
    }
    
    if (self.url != nil) {
        att.url = [NSString stringWithString:self.url];
    }

    att.displayIndex = self.displayIndex;
    
    return att;
}

- (NSString*)photoUrl
{
    return self.url;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"filename: %@ filetype: %@  tn: %@  url: %@",
                self.fileName, self.fileType, self.tnUrl, self.url];
}

@end
