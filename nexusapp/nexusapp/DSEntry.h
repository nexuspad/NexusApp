//
//  DSEntry.h
//  NexusAppCore
//
//  Created by Ren Liu on 10/20/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DSEntry : NSManagedObject

@property (nonatomic, retain) NSString * action;
@property (nonatomic, retain) NSData * content;
@property (nonatomic, retain) NSDate * createTime;
@property (nonatomic, retain) NSDate * dateFilter;
@property (nonatomic, retain) NSString * entryId;
@property (nonatomic, retain) NSString * externalId;
@property (nonatomic, retain) NSNumber * folderId;
@property (nonatomic, retain) NSString * keyFilter;
@property (nonatomic, retain) NSDate * lastModified;
@property (nonatomic, retain) NSNumber * moduleId;
@property (nonatomic, retain) NSNumber * ownerId;
@property (nonatomic, retain) NSNumber * seqId;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSNumber * synced;
@property (nonatomic, retain) NSNumber * templateId;

@end
