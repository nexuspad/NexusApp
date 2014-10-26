//
//  ContactVcardUploadService.h
//  NexusAppCore
//
//  Created by Ren Liu on 10/16/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "NPWebApiService.h"

/**
 * Used by AddressbookService for uploading local phone contact as VCard.
 */
@interface ContactVcardUploadService : NPWebApiService

- (void)uploadToServer:(NSData*)vcardData params:(NSMutableDictionary*)params;

@end
