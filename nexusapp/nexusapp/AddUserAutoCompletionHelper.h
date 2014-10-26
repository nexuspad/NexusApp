//
//  AddUserAutoCompletionHelper.h
//  nexusapp
//
//  Created by Ren Liu on 11/26/13.
//
//

#import <Foundation/Foundation.h>
#import "MLPAutoCompleteTextField.h"

@interface AddUserAutoCompletionHelper : NSObject <MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate>

@property (strong, nonatomic) MLPAutoCompleteTextField *userNameOrEmailTextField;
@property (strong, nonatomic) UILabel *userEmailLabel;

- (id)initWithTextField:(UITextField*)textField;

@end
