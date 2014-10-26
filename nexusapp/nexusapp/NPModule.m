//
//  NameHelper.m
//  NexusAppCore
//
//  Created by Ren Liu on 12/17/12.
//  Copyright (c) 2012 Ren Liu. All rights reserved.
//

#import "NPModule.h"

@implementation NPModule

+ (NSString*)emailModuleEntry:(NPEntry*)entry
{
    if (entry.folder.moduleId == 1) {
        return NSLocalizedString(@"Email contact",);
        
    } else if (entry.folder.moduleId == 2) {
        return NSLocalizedString(@"Email event",);
        
    } else if (entry.folder.moduleId == 3) {
        return NSLocalizedString(@"Email bookmark",);
        
    } else if (entry.folder.moduleId == 4) {
        return NSLocalizedString(@"Email doc",);
        
    } else if (entry.folder.moduleId == 5) {
        return NSLocalizedString(@"Email attachment",);
        
    } else if (entry.folder.moduleId == 6) {
        if (entry.templateId == photo) {
            return NSLocalizedString(@"Email photo",);
        } else if (entry.templateId == album) {
            return NSLocalizedString(@"Email album",);
        }
        
    } else if (entry.folder.moduleId == 7) {
        return NSLocalizedString(@"Email journal",);
    }
    
    return @"";
}

+ (NSString*)getModuleCode:(int)forModuleId
{
    if (forModuleId == 1) {
        return @"contact";
        
    } else if (forModuleId == 2) {
        return @"calendar";
        
    } else if (forModuleId == 3) {
        return @"bookmark";
        
    } else if (forModuleId == 4) {
        return @"doc";
        
    } else if (forModuleId == 5) {
        return @"upload";
        
    } else if (forModuleId == 6) {
        return @"photo";
        
    } else if (forModuleId == 7) {
        return @"planner";
    }
    
    return @"";
}

+ (NSString*)getModuleEntryName:(int)forModuleId templateId:(TemplateId)templateId
{
    if (forModuleId == 1) {
        return @"contact";
        
    } else if (forModuleId == 2) {
        return @"event";
        
    } else if (forModuleId == 3) {
        return @"bookmark";
        
    } else if (forModuleId == 4) {
        return @"doc";
        
    } else if (forModuleId == 5) {
        return @"upload";
        
    } else if (forModuleId == 6) {
        if (templateId == photo) {
            return @"photo";
        } else if (templateId == album) {
            return @"album";
        }
        
    } else if (forModuleId == 7) {
        return @"journal";
    }
    
    return @"";
}

+ (int)defaultTemplate:(int)forModuleId
{
    if (forModuleId == 1) {
        return contact;
        
    } else if (forModuleId == 2) {
        return event;
        
    } else if (forModuleId == 3) {
        return bookmark;
        
    } else if (forModuleId == 4) {
        return doc;
        
    } else if (forModuleId == 5) {
        return 0;
        
    } else if (forModuleId == 6) {
        return 0;
        
    } else if (forModuleId == 7) {
        return journal;
    }
    
    return 0;
}

@end
