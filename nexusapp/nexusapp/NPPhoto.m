//
//  Media.m
//  nexuspad
//
//  Created by Ren Liu on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NPPhoto.h"
#import "NSDictionary+NPUtil.h"

@implementation NPPhoto

@synthesize displayIndex, tnUrl = _tnUrl, photoUrl = _photoUrl, uploadImage = _uploadImage;

- (id)init
{
    self = [super init];
    if (self) {
        self.folder.moduleId = PHOTO_MODULE;
        self.templateId = photo;
        return self;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone
{
    NPPhoto *photo = [[NPPhoto alloc] init];
    [photo copyBasic:self];
    photo.tnUrl = self.tnUrl;
    photo.photoUrl = self.photoUrl;
    photo.uploadImage = [self.uploadImage copy];

    return photo;
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

+ (NPPhoto*)photoFromEntry:(NPEntry*)entry
{
    if ([entry isKindOfClass:[NPPhoto class]]) {
        return (NPPhoto*)entry;
    }
    
    NPPhoto *photo = [[NPPhoto alloc] initWithNPEntry:entry];
    
    // This is for getting the TN information for individual photos in photo list
    if ([entry.featureValuesDict objectForKey:PHOTO_TN_URL] != nil && [entry.featureValuesDict objectForKey:PHOTO_URL] != nil) {
        if ([entry.featureValuesDict objectForKeyNotNull:PHOTO_TN_URL]) {
            photo.tnUrl = [entry.featureValuesDict valueForKey:PHOTO_TN_URL];
        }
        
        if ([entry.featureValuesDict objectForKeyNotNull:PHOTO_URL]) {
            photo.photoUrl = [entry.featureValuesDict valueForKey:PHOTO_URL];
        }
        
        photo.uploadImage = [[NPUpload alloc] init];
        photo.uploadImage.tnUrl = [photo.tnUrl copy];
        photo.uploadImage.url = [photo.photoUrl copy];
        photo.uploadImage.parentEntryModule = PHOTO_MODULE;
        photo.uploadImage.parentEntryFolder = photo.folder.folderId;
        photo.uploadImage.parentEntryId = [photo.entryId copy];
        
        // AccessEntitlement gets trickled down
        photo.uploadImage.accessInfo = photo.accessInfo;
    }
    
    return photo;
}

@end
