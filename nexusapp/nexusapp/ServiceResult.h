//
//  ServiceResult.h
//  NexusAppCore
//
//  Created by Ren Liu on 12/26/12.
//  Copyright (c) 2012 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Constants.h"

@interface ServiceResult : NSObject

@property BOOL success;

@property (nonatomic, strong) NSString *message;
@property int code;
@property (nonatomic, strong) NSDictionary *body;

- (id)initWithData:(NSDictionary*)data;
- (id)initWithCodeAndMessage:(int)code message:(NSString*)message;

- (BOOL)isEntryDetailResponse;
- (BOOL)isEntryListResponse;
- (BOOL)isEntryActionResponse;

- (BOOL)isFolderDetailResponse;
- (BOOL)isFolderListResponse;
- (BOOL)isFolderActionResponse;

@end
