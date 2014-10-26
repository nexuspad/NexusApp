//
//  AddUserAutoCompletionHelper.m
//  nexusapp
//
//  Created by Ren Liu on 11/26/13.
//
//

#import "AddressbookService.h"
#import "AddUserAutoCompletionHelper.h"
#import "NPPerson.h"
#import "ACPerson.h"
#import "UILabel+NPUtil.h"
#import "NSString+NPStringUtil.h"

@interface AddUserAutoCompletionHelper ()
// addressbook is a dictionary with display name and email as key, NPPerson as value.
@property (nonatomic, strong) NSMutableDictionary *addressbook;
@end

@implementation AddUserAutoCompletionHelper

- (id)initWithTextField:(UITextField*)textField {
    self = [super init];
    
    self.userNameOrEmailTextField = (MLPAutoCompleteTextField*)textField;

    self.userNameOrEmailTextField.returnKeyType = UIReturnKeyDone;    // The delegate for the Done key should be in the view controller

    [self.userNameOrEmailTextField setAutoCompleteTableAppearsAsKeyboardAccessory:YES];
    self.userNameOrEmailTextField.autoCompleteDataSource = self;
    self.userNameOrEmailTextField.autoCompleteDelegate = self;
    
    self.userNameOrEmailTextField.autoCompleteTableBorderColor = [UIColor clearColor];
    self.userNameOrEmailTextField.autoCompleteTableBackgroundColor = [UIColor colorWithRed:220.0/255 green:223.0/255 blue:226.0/255 alpha:0.9];
    self.userNameOrEmailTextField.autoCompleteFontSize = 16.0;

    [self getFullAddressbook];

    return self;
}


#pragma mark - MLPAutoCompleteTextField DataSource

- (NSArray *)autoCompleteTextField:(MLPAutoCompleteTextField *)textField possibleCompletionsForString:(NSString *)keyword {
    if (self.addressbook.count == 0) {
        [self getFullAddressbook];
    }

    NSMutableArray *suggestions = [[NSMutableArray alloc] init];
    
    if (self.addressbook.count > 0) {
        NSArray *allKeys = [self.addressbook allKeys];
        for (NSString *key in allKeys) {
            if ([key hasPrefix:keyword]) {
                [suggestions addObject:[ACPerson acPersonFromEntry:[self.addressbook objectForKey:key]]];
            }
        }
    }
    
    if (suggestions.count == 0) {
        textField.autoCompleteTableView.userInteractionEnabled = NO;    // In this way, the sharer table below the ac view can still
                                                                        // receive touch event.
    } else {
        textField.autoCompleteTableView.userInteractionEnabled = YES;
    }

    // The suggestions is an array of string with format: email;displayName, or just email.
    return suggestions;
}


#pragma mark - MLPAutoCompleteTextField Delegate

- (BOOL)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
          shouldConfigureCell:(UITableViewCell *)cell
       withAutoCompleteString:(NSString *)autocompleteString
         withAttributedString:(NSAttributedString *)boldedString
        forAutoCompleteObject:(id<MLPAutoCompletionObject>)autocompleteObject
            forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [cell.imageView setImage:[UIImage imageNamed:@"avatar.png"]];

    if (autocompleteObject != nil) {
        ACPerson *p = (ACPerson*)autocompleteObject;
        NSString *displayName = [p addressBookTitle];
        NSString *email = [p getEmail];
        
        if (displayName.length == 0 || [displayName isEqualToString:email]) {
            cell.textLabel.text = email;
            cell.detailTextLabel.text = @"";

        } else {
            cell.textLabel.text = displayName;
            cell.detailTextLabel.text = email;
        }
    }

    // Returns NO so the rest of MLPAutoCompleteTextField won't continue
    return NO;
}

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
  didSelectAutoCompleteString:(NSString *)selectedString
       withAutoCompleteObject:(id<MLPAutoCompletionObject>)selectedObject
            forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (selectedObject) {
        NSLog(@"selected object from autocomplete menu %@ with string %@", selectedObject, [selectedObject autocompleteString]);
        ACPerson *p = (ACPerson*)selectedObject;
        textField.text = [p getEmail];
    }
}

// Build an addressbook with email and display name as key
- (void)getFullAddressbook {
    DLog(@"Get full addressbook.");
    NSArray *personArr = [[AddressbookService instance] getAddressbook];
    
    // Addressbook was built in PhoneContactSyncService, and has email as key and displayname as value
    // We need to create additional entries with displayname as key as well.
    // In this way we can do keyword matching on both emails and displaynames
    
    NSMutableDictionary *addessbookTmp = [[NSMutableDictionary alloc] initWithCapacity:personArr.count*2];
    for (NPPerson *person in personArr) {
        NSString *displayName = [person addressBookTitle];
        NSString *email = [person getEmail];

        if (displayName.length == 0) {
            [addessbookTmp setObject:[ACPerson acPersonFromEntry:person] forKey:email];
        } else {
            [addessbookTmp setObject:[ACPerson acPersonFromEntry:person] forKey:email];
            [addessbookTmp setObject:[ACPerson acPersonFromEntry:person] forKey:displayName];
        }

        [addessbookTmp setObject:[ACPerson acPersonFromEntry:person] forKey:email];
    }

    // Sort the keys and store in self.addressbook
    NSArray *sortedKeys = [[addessbookTmp allKeys] sortedArrayUsingSelector: @selector(compare:)];
    self.addressbook = [[NSMutableDictionary alloc] initWithCapacity:addessbookTmp.count];
    
    for (NSString *key in sortedKeys) {
        [self.addressbook setObject:[addessbookTmp valueForKey:key] forKey:key];
    }
}

@end
