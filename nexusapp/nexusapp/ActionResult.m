//
//  NPActionResponse.m
//  nexuspad
//
//  Created by Ren Liu on 8/9/12.
//
//

#import "ActionResult.h"
#import "NSDictionary+NPUtil.h"

@interface ActionResult ()
@end

@implementation ActionResult

@synthesize name = _name, erroCode, detail = _detail;

- (id)initWithResultDict:(NSDictionary*)resultDict
{
    self = [super init];
    
    if (self) {
        self.name = [resultDict valueForKey:@"name"];
        
        self.success = NO;
        
        if ([resultDict valueForKey:@"success"] != nil) {
            if ([[resultDict valueForKey:@"success"] isEqualToString:@"yes"]) {
                self.success = YES;
            }
        }
        
        if ([resultDict objectForKey:@"entry"] != nil && [[resultDict objectForKey:@"entry"] isKindOfClass:[NSDictionary class]]) {
            // Entry action response
            self.detail = [NSDictionary dictionaryWithDictionary:[resultDict objectForKey:@"entry"]];
            
            if ([self.detail valueForKey:ACTION_ERROR_CODE] != nil) {
                self.erroCode = [NSString stringWithString:[self.detail valueForKey:ACTION_ERROR_CODE]];
            }
            
        } else if ([resultDict objectForKey:@"folder"] != nil && [[resultDict objectForKey:@"folder"] isKindOfClass:[NSDictionary class]]) {
            // Folder action response
            self.detail = [NSDictionary dictionaryWithDictionary:[resultDict objectForKey:@"folder"]];
            
            if ([self.detail valueForKey:ACTION_ERROR_CODE] != nil) {
                self.erroCode = [NSString stringWithString:[self.detail valueForKey:ACTION_ERROR_CODE]];
            }
        }
    }
    
    return self;
}

- (NPEntry*)getEntryActionResult {
    if (self.detail == nil) return nil;

    return [NPEntry entryFromDictionary:self.detail defaultAccessInfo:nil];
}

- (NPFolder*)getFolderActionResult
{
    if (self.detail == nil) return nil;
    
    NPFolder *folder = [[NPFolder alloc] init];
    if ([self.detail objectForKeyNotNull:FOLDER_ID] != nil) {
        folder.folderId = [[self.detail valueForKey:FOLDER_ID] intValue];
    }
    if ([self.detail objectForKeyNotNull:MODULE_ID] != nil) {
        folder.moduleId = [[self.detail valueForKey:MODULE_ID] intValue];
    }
    if ([self.detail objectForKeyNotNull:FOLDER_PARENT_ID] != nil) {
        folder.parentId = [[self.detail valueForKey:FOLDER_PARENT_ID] intValue];
    }
    if ([self.detail objectForKeyNotNull:FOLDER_CODE] != nil) {
        folder.folderCode = [self.detail valueForKey:FOLDER_CODE];
    }
    if ([self.detail objectForKeyNotNull:FOLDER_NAME] != nil) {
        folder.folderName = [self.detail valueForKey:FOLDER_NAME];
    }
    
    return folder;
}

- (Boolean)isUpdateEntry {
    if ([self.name isEqualToString:ACTION_UPDATE_ENTRY]) return true;
    return false;
}

- (Boolean)isDeleteEntry {
    if ([self.name isEqualToString:@"delete_entry"]) return true;
    return false;
}

- (Boolean)isUpdateFolder {
    if ([self.name isEqualToString:@"update_folder"]) return true;
    return false;
}

- (Boolean)isDeleteFolder {
    if ([self.name isEqualToString:@"delete_folder"]) return true;
    return false;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[action name: %@] [success: %i]", self.name, self.success];
}

@end
