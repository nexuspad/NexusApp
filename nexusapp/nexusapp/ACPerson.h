//
//  ACPerson.h
//  nexusapp
//
//  Created by Ren Liu on 1/10/14.
//
//

#import "NPPerson.h"
#import "MLPAutoCompletionObject.h"

// An extension of NPPerson that conforms to MLPAutoCompletionObject protocal
@interface ACPerson : NPPerson <MLPAutoCompletionObject>

+ (ACPerson*)acPersonFromEntry:(NPPerson*)npPerson;

@end
