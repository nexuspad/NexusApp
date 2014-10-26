//
//  FeatureDetailViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AddressEditorViewController.h"
#import "NPLocation.h"

@interface AddressEditorViewController ()
@property (nonatomic, strong) NPLocation *address;
@property (weak, nonatomic) IBOutlet UITextField *streetAddressInputField;
@property (weak, nonatomic) IBOutlet UITextField *cityInputField;
@property (weak, nonatomic) IBOutlet UITextField *provinceInputField;
@property (weak, nonatomic) IBOutlet UITextField *postalCodeInputField;
@property (weak, nonatomic) IBOutlet UITextField *countryTextField;
@end

@implementation AddressEditorViewController

@synthesize address = _address;
@synthesize streetAddressInputField = _streetAddressInputField;
@synthesize cityInputField = _cityInputField;
@synthesize provinceInputField = _provinceInputField;
@synthesize postalCodeInputField = _postalCodeInputField;
@synthesize countryTextField = _countryTextField;

// Clicking on the Done button
- (IBAction)cancelAddress:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneAddress:(id)sender
{
    if ([self.streetAddressInputField.text length] != 0) {
        self.address.streetAddress = [NSString stringWithString:self.streetAddressInputField.text];
    } else {
        self.address.streetAddress = @"";
    }

    if ([self.cityInputField.text length] != 0) {
        self.address.city = [NSString stringWithString:self.cityInputField.text];
    } else {
        self.address.city = @"";
    }
    
    if ([self.provinceInputField.text length] != 0) {
        self.address.province = [NSString stringWithString:self.provinceInputField.text];
    } else {
        self.address.province = @"";
    }
    
    if ([self.postalCodeInputField.text length] != 0) {
        self.address.postalCode = [NSString stringWithString:self.postalCodeInputField.text];
    } else {
        self.address.postalCode = @"";
    }
    
    if ([self.countryTextField.text length] != 0) {
        self.address.country = [NSString stringWithString:self.countryTextField.text];
    } else {
        self.address.country = @"";
    }
    
    [self.entryUpdateDelegate updateContactAddress:self.address];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.address == nil) {
        self.address = [[NPLocation alloc] init];
    }

    self.streetAddressInputField.text = self.address.streetAddress;
    self.cityInputField.text = self.address.city;
    self.provinceInputField.text = self.address.province;
    self.postalCodeInputField.text = self.address.postalCode;
    self.countryTextField.text = self.address.country;
}

- (void)viewDidUnload
{
    [self setStreetAddressInputField:nil];
    [self setCityInputField:nil];
    [self setProvinceInputField:nil];
    [self setPostalCodeInputField:nil];
    [self setCountryTextField:nil];
    [super viewDidUnload];
}

@end
