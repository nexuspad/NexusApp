//
//  NPEntry.m
//  nexuspad
//
//  Created by Ren Liu on 5/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NPEntry.h"
#import "DateUtil.h"
#import "NSString+NPStringUtil.h"
#import "NSDictionary+NPUtil.h"

@implementation NPEntry

@synthesize folder = _folder, accessInfo, status, templateId;
@synthesize entryId = _entryId, syncId = _syncId, externalId = _externalId;
@synthesize title = _title;
@synthesize createTime = _createDate, modifiedTime = _modifiedDate, localModifiedTime = _localModifiedTime;
@synthesize hasAttachments = _hasAttachments, hasMappedEntries = _hasMappedEntries;
@synthesize colorLabel = _colorLabel, tags, note, location, featureValuesDict, attachments = _attachments, mappedEntries = _mappedEntries, sharing;

- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"";
        self.status = 0;
        self.folder = [[NPFolder alloc] init];
        self.accessInfo = [[AccessEntitlement alloc] init];
        self.createTime = [[NSDate alloc] init];

        return self;
    }
    
    return self;
}

- (id)initWithNPEntry:(NPEntry*)entry
{
    self = [self init];
    [self copyBasic:entry];
    return self;
}

- (NSString*)getEntryId {
    return _entryId;
}

- (void)setEntryId:(NSString *)entryId {
    if (entryId != nil) {
        _entryId = [NSString stringWithString:entryId];
    } else {
        _entryId = nil;
    }
}

- (NPFolder*)folder {
    if (_folder == nil) {
        DLog(@"############# @@@@@@@@@@@@@@@ *************");
    }
    return _folder;
}

- (void)setOwnerAccessInfo:(int)ownerId {
    self.accessInfo = [[AccessEntitlement alloc] init];
    self.accessInfo.owner = [[NPUser alloc] init];
    self.accessInfo.owner.userId = ownerId;
    self.accessInfo.viewer = self.accessInfo.owner;
}

- (NSString*)title
{
    return [_title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)isNewEntry
{
    if (self.entryId != nil && [self.entryId length] > 0 && ![self.entryId hasPrefix:@"_"])
        return NO;
    return YES;
}

- (NSString*)colorLabel
{
    if (_colorLabel == nil) {
        return @"#336699";
    }
    return _colorLabel;
}

- (int)getOwnerId {
    if (self.accessInfo != nil && self.accessInfo.owner != nil) {
        return self.accessInfo.owner.userId;
    }
    return 0;
}

- (BOOL)isEqual:(NPEntry*)other {
    if (other == self)
        return YES;

    if ([super isEqual:other])
        return YES;
    
    if (![other isKindOfClass:[NPEntry class]]) {
        return NO;
    }
    
    if (self.folder.moduleId == other.folder.moduleId && [self.entryId isEqualToString:other.entryId] &&
        [self getOwnerId] == [other getOwnerId])
    {
        return YES;
    }
    
    return NO;
}

- (NSUInteger)hash {
    return self.folder.moduleId ^ [self.entryId hash] ^ [self getOwnerId];
}

- (id)copyWithZone:(NSZone*)zone {
    NPEntry *newEntry = [[NPEntry alloc] init];
    [newEntry copyBasic:self];
    return newEntry;
}

- (void)copyBasic:(NPEntry*)entry {
    if (entry.entryId != nil) {
        self.entryId = [NSString stringWithFormat:@"%@", entry.entryId];
    }
    
    if (entry.syncId != nil) {
        self.syncId = [NSString stringWithFormat:@"%@", entry.syncId];
    }
    
    self.synced = entry.synced;
    self.status = entry.status;

    self.accessInfo = [entry.accessInfo copy];
    
    if (entry.folder != nil) {
        self.folder = [entry.folder copy];
    }

    self.templateId = entry.templateId;
    
    if (!entry.title) {
        entry.title = @"";
    }

    self.title = [NSString stringWithFormat:@"%@", entry.title];
    self.createTime = [entry.createTime copy];
    self.modifiedTime = [entry.modifiedTime copy];
    self.localModifiedTime = self.modifiedTime;
    
    self.note = [entry.note copy];
    self.colorLabel = [entry.colorLabel copy];
    self.tags = [entry.tags copy];
    
    self.webAddress = [entry.webAddress copy];
    self.location = [entry.location copy];

    self.hasAttachments = entry.hasAttachments;
    self.hasMappedEntries = entry.hasMappedEntries;
    
    self.attachments = [NSArray arrayWithArray:entry.attachments];

    self.featureValuesDict = [entry.featureValuesDict mutableCopy];
}

- (NSDictionary*)buildParamMap {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    // If the entry Id is a temp Id, set sync_id instead of entry_id.
    if (![self.entryId hasPrefix:@"_"]) {
        [params setValue:self.entryId forKey:ENTRY_ID];
    } else {
        // Send the temp entry Id as sync Id
        [params setValue:self.entryId forKey:ENTRY_SYNC_ID];
    }
    
    if (self.externalId != nil) {
        [params setValue:self.externalId forKey:EXTERNAL_ID];
    }

    [params setValue:[NSNumber numberWithInt:self.folder.moduleId] forKey:MODULE_ID];
    [params setValue:[NSNumber numberWithInt:self.folder.folderId] forKey:FOLDER_ID];
    
    [params setValue:self.title forKey:ENTRY_TITLE];
    
    if (self.note != nil) {
        [params setValue:self.note forKey:ENTRY_NOTE];
    }
    
    if (self.tags != nil) {
        [params setValue:self.tags forKey:ENTRY_TAG];
    }
    
    if (self.webAddress != nil) {
        [params setValue:self.webAddress forKey:ENTRY_WEB_ADDRESS];
    }
    
    if (self.colorLabel != nil) {
        [params setValue:self.colorLabel forKey:ENTRY_COLOR_LABEL];
    }
    
    if (self.hasAttachments) {
        [params setValue:@"1" forKey:ENTRY_HAS_UPLOADS];
    }

    if (self.hasMappedEntries) {
        [params setValue:@"1" forKey:ENTRY_HAS_MAPPED];
    }

    if (![self.accessInfo iAmOwner]) {
        [params setValue:@(self.accessInfo.owner.userId) forKey:OWNER_ID];
    }

    return params;
}

- (void)setFeatureValue:(NSString*)featureId featureValue:(id)featureValue {
    if (![NSString isBlank:featureValue]) {
        // Create a local mutable copy. self.featureValueDict is immutable.
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.featureValuesDict];
        [dict setObject:featureValue forKey:featureId];
        
        self.featureValuesDict = dict;
    }
}

- (id)getFeatureValue:(NSString*)featureId {
    if ([self.featureValuesDict objectForKeyNotNull:featureId]) {
        id value = [self.featureValuesDict objectForKey:featureId];
        if (value == nil) return nil;
        if ([value isKindOfClass:[NSString class]] && [value length] == 0) return nil;
        if ([value isKindOfClass:[NSArray class]] && [value count] == 0) return nil;
        return value;
    }
    return nil;
}

- (void)removeFeatureValue:(NSString*)featureId {
    [self.featureValuesDict removeObjectForKey:featureId];
}

// Build entry object based on the service result (NSDictionary)
+ (NPEntry*)entryFromDictionary:(NSDictionary*)entryDict defaultAccessInfo:(AccessEntitlement *)defaultAccessInfo {
    NPEntry *entry = [[NPEntry alloc] init];
    
    // Build access info
    // Ideally it should be returned from web service.
    // If it's not, we'll have to use the default accessInfo, for example, from the EntryList to set the entry's accessInfo.
    //
    if ([entryDict objectForKey:ACCESS_INFO] != nil) {
        entry.accessInfo = [[AccessEntitlement alloc] initWithDictInfo:[entryDict objectForKey:ACCESS_INFO]];
    } else if (defaultAccessInfo != nil) {
        entry.accessInfo = [defaultAccessInfo copy];
    }
    
    entry.featureValuesDict = [NSMutableDictionary dictionaryWithDictionary:entryDict];
    
    // If the individual entry record has owner_id, use it to overwrite
    if ([entryDict objectForKeyNotNull:OWNER_ID]) {
        if (entry.accessInfo == nil) {
            entry.accessInfo = [[AccessEntitlement alloc] init];
            entry.accessInfo.owner.userId = [[entryDict valueForKey:OWNER_ID] intValue];
        } else {
            entry.accessInfo.owner.userId = [[entryDict valueForKey:OWNER_ID] intValue];
        }
    }

    int moduleId = [[entryDict valueForKey:MODULE_ID] intValue];
    int folderId = [[entryDict valueForKey:FOLDER_ID] intValue];

    entry.folder = [[NPFolder alloc] initWithModuleAndFolderId:moduleId folderId:folderId accessInfo:defaultAccessInfo];
    
    if ([entryDict objectForKeyNotNull:FOLDER_NAME]) {
        entry.folder.folderName = [entryDict valueForKey:FOLDER_NAME];
    }
    
    if ([entryDict objectForKeyNotNull:TEMPLATE_ID]) {
        entry.templateId = [[entryDict valueForKey:TEMPLATE_ID] intValue];
    }

    entry.entryId = [entryDict valueForKey:ENTRY_ID];
    
    if ([entryDict objectForKeyNotNull:ENTRY_SYNC_ID]) {
        entry.syncId = [entryDict valueForKey:ENTRY_SYNC_ID];
    }
    
    if ([entryDict objectForKeyNotNull:EXTERNAL_ID]) {
        entry.externalId = [entryDict valueForKey:EXTERNAL_ID];
    }
    
    entry.title = [entryDict valueForKey:ENTRY_TITLE];
    
    if ([entryDict objectForKeyNotNull:ENTRY_CREATE_TS]) {
        NSString *createDateStr = [entryDict valueForKey:ENTRY_CREATE_TS];
        entry.createTime = [NSDate dateWithTimeIntervalSince1970:[createDateStr longLongValue]];
    }
        
    if ([entryDict objectForKeyNotNull:ENTRY_MODIFIED_TS]) {
        entry.modifiedTime = [NSDate dateWithTimeIntervalSince1970:[[entryDict valueForKey:ENTRY_MODIFIED_TS] longLongValue]];
        entry.localModifiedTime = entry.modifiedTime;
    }
    
    // Color label
    if ([entryDict objectForKeyNotNull:ENTRY_COLOR_LABEL]) {
        entry.colorLabel = [entryDict valueForKey:ENTRY_COLOR_LABEL];
    }
    
    // Tag
    if ([entryDict objectForKeyNotNull:ENTRY_TAG]) {
        entry.tags = [entryDict valueForKey:ENTRY_TAG];
    }
    
    // Web address
    if ([entryDict objectForKeyNotNull:ENTRY_WEB_ADDRESS]) {
        entry.webAddress = [entryDict valueForKey:ENTRY_WEB_ADDRESS];
    }
    
    // Note
    if ([entryDict objectForKeyNotNull:ENTRY_NOTE]) {
        entry.note = [entryDict valueForKey:ENTRY_NOTE];
    } else {
        entry.note = @"";
    }
    
    // Location
    entry.location = [[NPLocation alloc] init];

    if ([entryDict objectForKeyNotNull:LOCATION_FULL_ADDRESS]) {
        entry.location.fullAddress = [entryDict valueForKey:LOCATION_FULL_ADDRESS];
    }
    if ([entryDict objectForKeyNotNull:LOCATION_LATITUDE] && [entryDict objectForKeyNotNull:LOCATION_LONGITUDE]) {
        entry.location.latitude = [entryDict valueForKey:LOCATION_LATITUDE];
        entry.location.longitude = [entryDict valueForKey:LOCATION_LONGITUDE];
    }
    if ([entryDict objectForKeyNotNull:LOCATION_LAT_LNG]) {
        NSArray *psis = [[entryDict valueForKey:LOCATION_LONGITUDE] componentsSeparatedByString:@","];
        entry.location.latitude = psis[0];
        entry.location.longitude = psis[1];
    }

    // Status
    if ([entryDict objectForKeyNotNull:ENTRY_STATUS]) {
        entry.status = [[entryDict valueForKey:ENTRY_STATUS] intValue];
    } else {
        entry.status = ENTRY_STATUS_ACTIVE;
    }

    if ([entryDict objectForKeyNotNull:ENTRY_HAS_UPLOADS]) {
        entry.hasAttachments = YES;
    }
    
    if ([entryDict objectForKeyNotNull:ENTRY_HAS_MAPPED]) {
        entry.hasMappedEntries = YES;
    }
    
    if ([entryDict objectForKeyNotNull:ENTRY_ATTACHMENTS]) {
        NSArray *dictArr = [entryDict objectForKey:ENTRY_ATTACHMENTS];
        NSMutableArray *attachedFiles = [[NSMutableArray alloc] initWithCapacity:[dictArr count]];
        
        int i=0;
        for (NSDictionary *dict in dictArr) {
            NPUpload *file = [[NPUpload alloc] init];
            
            file.parentEntryModule = entry.folder.moduleId;
            file.parentEntryFolder = entry.folder.folderId;
            file.parentEntryId = entry.entryId;
            file.entryId = [dict valueForKey:ENTRY_ID];
            
            // The Photo TN and Photo URLs

            if ([dict objectForKeyNotNull:PHOTO_URL]) {
                file.url = [dict valueForKey:PHOTO_URL];
            }

            if ([dict objectForKeyNotNull:PHOTO_TN_URL]) {
                file.tnUrl = [dict valueForKey:PHOTO_TN_URL];
            }
            
            // File attributes
            
            if ([dict valueForKey:ATTACHMENT_FILE_NAME] != nil) {
                file.fileName = [dict valueForKey:ATTACHMENT_FILE_NAME];
            }
            
            if ([dict valueForKey:ATTACHMENT_FILE_TYPE] != nil) {
                file.fileType = [dict valueForKey:ATTACHMENT_FILE_TYPE];
            }
            
            if ([dict valueForKey:ATTACHMENT_FILE_SIZE] != nil) {
                file.fileSize = [[dict valueForKey:ATTACHMENT_FILE_SIZE] longValue];
            }
            
            if ([dict valueForKey:ATTACHMENT_FILE_LINK] != nil) {
                file.url = [dict valueForKey:ATTACHMENT_FILE_LINK];
            }
            
            file.displayIndex = i;
            i++;
            
            [attachedFiles addObject:file];
        }
        
        entry.attachments = [NSArray arrayWithArray:attachedFiles];
    }
    
    return entry;
}


- (NSString *)description {
    return [NSString stringWithFormat:@"module:%i template:%i folder:%i entryId:%@ title:%@ access owner:%d viewer:%d synced:%d",
            self.folder.moduleId, self.templateId, self.folder.folderId, self.entryId, self.title,
            self.accessInfo.owner.userId, self.accessInfo.viewer.userId, self.synced];
}


- (BOOL)isLoadedWithData {
    if (self.modifiedTime == nil) {
        return NO;
    }
    return YES;
}

+ (BOOL)validate:(NPEntry*)entry {
    if (entry.accessInfo.owner.userId == 0 || entry.folder.moduleId == 0 || entry.templateId == not_assigned) {
        return NO;
    } else {
        return YES;
    }
}

@end
