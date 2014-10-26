//
//  Album.m
//  NexusAppCore
//
//  Created by Ren Liu on 1/16/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "NPAlbum.h"
#import "NSDictionary+NPUtil.h"

@implementation NPAlbum

- (id)init
{
    self = [super init];
    if (self) {
        self.folder.moduleId = PHOTO_MODULE;
        self.templateId = album;
        return self;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone
{
    NPAlbum *album = [[NPAlbum alloc] init];
    [album copyBasic:self];
    album.attachments = [NSArray arrayWithArray:self.attachments];

    return album;
}

- (NSString*)tnUrl
{
    if (self.attachments.count > 0) {
        NPUpload *attachment = [self.attachments objectAtIndex:0];
        if (attachment != nil && attachment.tnUrl != nil) {
            return attachment.tnUrl;
        }
    }
    
    return @"";
}

- (NSDictionary*)buildParamMap
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[super buildParamMap]];
    
    if (self.templateId == photo) {
        [params setValue:[NSNumber numberWithInt:photo] forKey:TEMPLATE_ID];
    } else if (self.templateId == album) {
        [params setValue:[NSNumber numberWithInt:album] forKey:TEMPLATE_ID];
    }
    
    return params;
}


+ (NPAlbum*)albumFromEntry:(NPEntry*)entry
{
    if ([entry isKindOfClass:[NPAlbum class]]) {
        return (NPAlbum*)entry;
    }
    
    NPAlbum *album = [[NPAlbum alloc] initWithNPEntry:entry];
    
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    int i=0;
    
    if ([entry.featureValuesDict objectForKey:ALBUM_PHOTOS] != nil) {
        NSArray *dictArr = [entry.featureValuesDict objectForKey:ALBUM_PHOTOS];
        
        for (NSDictionary *dict in dictArr) {
            NPUpload *photo = [[NPUpload alloc] init];
            
            photo.parentEntryModule = entry.folder.moduleId;
            photo.parentEntryFolder = entry.folder.folderId;
            photo.parentEntryId = entry.entryId;
            photo.entryId = [dict valueForKey:ENTRY_ID];
            
            if ([dict objectForKeyNotNull:PHOTO_TN_URL]) {
                photo.tnUrl = [dict valueForKey:PHOTO_TN_URL];
            }
            
            if ([dict objectForKeyNotNull:PHOTO_URL]) {
                photo.url = [dict valueForKey:PHOTO_URL];
            }
            
            photo.displayIndex = i;
            i++;
            
            // AccessEntitlement gets trickled down
            photo.accessInfo = album.accessInfo;
            
            [photos addObject:photo];
        }
    }

        
    // This is for legacy albums
    if ([entry.featureValuesDict objectForKey:ENTRY_ATTACHMENTS] != nil) {
        NSArray *dictArr = [entry.featureValuesDict objectForKey:ENTRY_ATTACHMENTS];
        
        for (NSDictionary *dict in dictArr) {
            NPUpload *photo = [[NPUpload alloc] init];
            
            photo.parentEntryModule = entry.folder.moduleId;
            photo.parentEntryFolder = entry.folder.folderId;
            photo.parentEntryId = entry.entryId;
            photo.entryId = [dict valueForKey:ENTRY_ID];
            
            if ([dict objectForKeyNotNull:PHOTO_TN_URL]) {
                photo.tnUrl = [dict valueForKey:PHOTO_TN_URL];
            }

            if ([dict objectForKeyNotNull:PHOTO_URL]) {
                photo.url = [dict valueForKey:PHOTO_URL];
            }
            
            photo.displayIndex = i;
            i++;
            
            // AccessEntitlement gets trickled down
            photo.accessInfo = album.accessInfo;
            
            [photos addObject:photo];
        }
    }
    
    album.attachments = [NSArray arrayWithArray:photos];
    
    return album;
}


@end
