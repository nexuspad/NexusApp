//
//  NPManagedDocument.m
//  NexusAppCore
//
//  Created by Ren Liu on 1/4/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "NPManagedDocument.h"

@interface NPManagedDocument()
@property (nonatomic, strong) NSManagedObjectModel *npManagedObjectModel;
@end

@implementation NPManagedDocument

@synthesize npManagedObjectModel;

- (id)initWithFileURL:(NSURL *)url {
    self = [super initWithFileURL:url];
    return self;
}

// Overwrite to load the core data schema from the NexusAppCoreResource Bundle
//- (NSManagedObjectModel*)managedObjectModel {
//    if (self.npManagedObjectModel != nil) {
//        return self.npManagedObjectModel;
//    }
//    
//    NSString *staticLibraryBundlePath = [[NSBundle mainBundle] pathForResource:@"NexusAppCoreResource" ofType:@"bundle"];
//    NSURL *staticLibraryMOMURL = [[NSBundle bundleWithPath:staticLibraryBundlePath] URLForResource:@"np" withExtension:@"mom"];
//    
//    self.npManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:staticLibraryMOMURL];
//    
//    return self.npManagedObjectModel;
//}

@end
