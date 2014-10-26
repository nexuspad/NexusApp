//
//  NPEntry.h
//  nexuspad
//
//  Created by Ren Liu on 5/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreSettings.h"
#import "Constants.h"
#import "NPFolder.h"
#import "NPLocation.h"
#import "NPUpload.h"
#import "AccessEntitlement.h"
#import "NSString+NPStringUtil.h"
#import "EntryTemplate.h"

@interface NPEntry : NSObject

@property (nonatomic, strong) AccessEntitlement *accessInfo;

@property int status;
@property BOOL synced;

@property (nonatomic, strong) NPFolder *folder;

@property TemplateId templateId;

@property (nonatomic, strong) NSString *entryId;
@property (nonatomic, strong) NSString *externalId;
@property (nonatomic, strong) NSString *syncId;
@property (nonatomic, strong) NSString *title;

@property (nonatomic, strong) NSString *colorLabel;
@property (nonatomic, strong) NSString *tags;
@property (nonatomic, strong) NSString *note;

@property (nonatomic, strong) NSDate *createTime;
@property (nonatomic, strong) NSDate *modifiedTime;
@property (nonatomic, strong) NSDate *localModifiedTime; // This is used by UI to keep track of the content change of an entry.
@property (nonatomic, strong) NSString *webAddress;
@property (nonatomic, strong) NPLocation *location;

@property BOOL hasAttachments;
@property (nonatomic, strong) NSArray *attachments;

@property BOOL hasMappedEntries;
@property (nonatomic, strong) NSArray *mappedEntries;

@property (nonatomic, strong) NSArray *sharing;

// Name value pairs of features. Notice that the value piece is NOT an EntryDetail object.
@property (nonatomic, strong) NSMutableDictionary *featureValuesDict;


- (id)initWithNPEntry:(NPEntry*)entry;

- (void)setOwnerAccessInfo:(int)ownerId;

- (NSString*)getEntryId;
- (void)setEntryId:(NSString *)entryId;

- (BOOL)isNewEntry;

- (void)setFeatureValue:(NSString*)featureId featureValue:(id)featureValue;
- (id)getFeatureValue:(NSString*)featureId;
- (void)removeFeatureValue:(NSString*)featureId;

- (void)copyBasic:(NPEntry*)entry;

- (NSDictionary*)buildParamMap;

- (BOOL)isLoadedWithData;

// Populate the entry object using the name value pairs from the data service. The entry detail is populated in a "raw" form.
+ (NPEntry*)entryFromDictionary:(NSDictionary*)entryDict defaultAccessInfo:(AccessEntitlement*)defaultAccessInfo;

+ (BOOL)validate:(NPEntry*)entry;

@end
