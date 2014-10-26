//
//  NSString+NPOutput.h
//  nexuspad
//
//  Created by Ren Liu on 8/13/12.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (NPStringUtil)

+ (BOOL)isBlank:(NSString*)theString;
+ (BOOL)isNotBlank:(NSString*)theString;

+ (NSString*)compressLineBreak:(NSString*)inputStr;

+ (BOOL)isValidEmail:(NSString *)checkString;

- (BOOL)stringContains:(NSString*)checkString;

- (NSString*)stripOffNonNumerics;

+ (NSString*)convertDataToJsonString:(id)data;

+ (NSString*)displayBytes:(double)bytes;

+ (NSString*)formatPhoneNumber:(NSString*)phoneNumber;

+ (NSString*)convertStringForPosting:(NSString*)string;

+ (NSString*)prependHttp:(NSString*)url;

+ (NSString*)displayUrl:(NSString*)url;

+ (UIColor*)textColorOnBackground:(UIColor*)bgColor;

+ (NSString *)genRandString:(int)len;

+ (NSString*)compressWhitespaces:(NSString*)string;

- (NSString *)reducedToWidth:(CGFloat)width withFont:(UIFont *)font;

@end
