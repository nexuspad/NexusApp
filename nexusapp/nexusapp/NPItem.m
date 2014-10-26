//
//  BasicItem.m
//  nexuspad
//
//  Created by Ren Liu on 8/13/12.
//
//

#import "NPItem.h"
#import "Constants.h"

@implementation NPItem

@synthesize value, formattedValue, type, url, subType = _subType;

- (id)initWithType:(BasicItemTypes)itemType
{
    self = [super init];
    self.type = itemType;
    return self;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"value: %@ subtype: %@ url: %@", self.value, self.subType, self.url];
}

- (NSDictionary*)toDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:2];
    [dict setValue:self.value forKey:ENTRY_DETAIL_VALUE];
    [dict setValue:self.subType forKey:ENTRY_DETAIL_TYPE];
    
    return dict;
}

- (id)copyWithZone:(NPItem*)item
{
    NPItem *newItem = [[NPItem alloc] init];
    newItem.value = item.value;
    newItem.formattedValue = item.formattedValue;
    newItem.type = item.type;
    newItem.url = item.url;
    newItem.subType = item.subType;
    return newItem;
}

- (NSString*)subType
{
    if (_subType == nil) {
        return @"";
    }
    return _subType;
}

- (NSString*)htmlLink
{
    return [NSString stringWithFormat:@"<a href=\"%@\" style=\"font:16px Arial; font-weight:bold; text-decoration:none;\">%@</a>", self.url, self.value];
}

- (NSString*)itemPlaceholderName
{
    if (self.type == PhoneItem) {
        return NSLocalizedString(@"phone", );
    } else if (self.type == EmailItem) {
        return NSLocalizedString(@"email",);
    }
    return @"";
}

- (NSArray*)subTypeSelections
{
    if (self.type == PhoneItem) {
        return [NSArray arrayWithObjects:NSLocalizedString(@"home",),
                                         NSLocalizedString(@"mobile",),
                                         NSLocalizedString(@"work",),
                                         NSLocalizedString(@"fax",),
                                         NSLocalizedString(@"other",),
                                         nil];
    }
    
    if (self.type == EmailItem) {
        return [NSArray arrayWithObjects:NSLocalizedString(@"personal",),
                                         NSLocalizedString(@"work",),
                                         nil];
    }
    
    return nil;
}

- (NSString*)getDisplayValue {
    if (self.formattedValue.length) {
        return self.formattedValue;
    } else {
        return self.value;
    }
}

@end
