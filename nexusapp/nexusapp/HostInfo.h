//
//  HostInfo.h
//  nexuspad
//
//  Created by Ren Liu on 9/27/12.
//
//

#import <Foundation/Foundation.h>

@interface HostInfo : NSObject

@property (nonatomic, strong) NSString *appEnv;
@property BOOL isOnline;

- (NSString*)getApiUrl;
- (NSString*)getHostUrl;

+ (HostInfo*)current;

@end
