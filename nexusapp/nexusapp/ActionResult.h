//
//  NPActionResponse.h
//  nexuspad
//
//  Created by Ren Liu on 8/9/12.
//
//

#import "ServiceResult.h"
#import "NPEntry.h"
#import "NPFolder.h"

@interface ActionResult : ServiceResult

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *erroCode;
@property (nonatomic, strong) NSDictionary *detail;

- (id)initWithResultDict:(NSDictionary*)resultDict;

- (NPEntry*)getEntryActionResult;
- (NPFolder*)getFolderActionResult;

- (Boolean)isUpdateEntry;
- (Boolean)isDeleteEntry;
- (Boolean)isUpdateFolder;
- (Boolean)isDeleteFolder;

@end
