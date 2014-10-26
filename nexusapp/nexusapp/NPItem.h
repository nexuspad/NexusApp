//
//  BasicItem.h
//  nexuspad
//
//  Created by Ren Liu on 8/13/12.
//
//

#import <Foundation/Foundation.h>

typedef enum {PhoneItem, EmailItem} BasicItemTypes;

@interface NPItem : NSObject

@property BasicItemTypes type;

@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong) NSString *formattedValue;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *subType;

- (id)initWithType:(BasicItemTypes)type;

- (NSDictionary*)toDictionary;
- (NSString*)htmlLink;

- (NSString*)itemPlaceholderName;
- (NSArray*)subTypeSelections;

- (NSString*)getDisplayValue;

@end
