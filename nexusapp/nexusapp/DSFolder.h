//
//  DSFolder.h
//  NexusAppCore
//
//  Created by Ren Liu on 10/17/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DSFolder : NSManagedObject

@property (nonatomic, retain) NSString * action;
@property (nonatomic, retain) NSString * colorLabel;
@property (nonatomic, retain) NSNumber * folderId;
@property (nonatomic, retain) NSString * folderName;
@property (nonatomic, retain) NSDate * lastModified;
@property (nonatomic, retain) NSNumber * moduleId;
@property (nonatomic, retain) NSNumber * ownerId;
@property (nonatomic, retain) NSNumber * parentId;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSNumber * synced;

@end
