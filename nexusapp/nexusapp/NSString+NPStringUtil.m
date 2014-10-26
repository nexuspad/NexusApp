//
//  NSString+NPOutput.m
//  nexuspad
//
//  Created by Ren Liu on 8/13/12.
//
//

#import "NSString+NPStringUtil.h"

@implementation NSString (NPStringUtil)

+ (BOOL)isBlank:(NSString*)theString
{
    if (([theString isKindOfClass:[NSString class]] || theString == nil) && (theString == (id)[NSNull null] || [theString length] == 0))
        return YES;
    return NO;
}

+ (BOOL)isNotBlank:(NSString*)theString {
    return ![self isBlank:theString];
}

+ (NSString*)compressLineBreak:(NSString*)inputStr
{
    NSArray *pieces = [inputStr componentsSeparatedByString:@"\n"];
    NSMutableArray *resultArr = [[NSMutableArray alloc] init];
    
    for (NSString *piece in pieces) {
        if ([piece length] > 0) {
            [resultArr addObject:piece];
        }
    }
    
    return [resultArr componentsJoinedByString:@"\n"];
}

+ (BOOL)isValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

- (BOOL)stringContains:(NSString*)checkString {
    NSRange rng = [self rangeOfString:checkString options:0];
    return rng.location != NSNotFound;
}

- (NSString*)stripOffNonNumerics {
    return [self stringByReplacingOccurrencesOfString:@"[^0-9]"
                                           withString:@""
                                              options:NSRegularExpressionSearch
                                                range:NSMakeRange(0, [self length])];

}

+ (NSString*)convertDataToJsonString:(id)data
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data
                                                       options:0                     //NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (!jsonData) {
        NSLog(@"Failed to generate json data for recur info: %@ Error: %@", [data description], error);
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (NSString*)displayBytes:(double)bytes
{
    float bytesInMB = bytes/1024.0/1024.0;
    if (bytesInMB >= 1024) {
        return [NSString stringWithFormat:@"%.1fGB", bytesInMB/1024];
    }
    return [NSString stringWithFormat:@"%.1fMB", bytesInMB];
}

+ (NSString*)formatPhoneNumber:(NSString*)phoneNumber
{
    
    phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"(" withString:@""];
    phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
    phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
    phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"+" withString:@""];
    
    if([phoneNumber length] == 10)
    {
        NSString *formattedNumber = [NSString stringWithFormat:@"(%@) %@-%@",
                                                                [phoneNumber substringWithRange:NSMakeRange(0, 3)],
                                                                [phoneNumber substringWithRange:NSMakeRange(3, 3)],
                                                                [phoneNumber substringWithRange:NSMakeRange(6, 4)]];
        return formattedNumber;
    }
    
    return phoneNumber;
}

+ (NSString*)convertStringForPosting:(NSString*)string
{
    NSString *newString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                  (__bridge CFStringRef)string,
                                                                  NULL,
                                                                  CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"),
                                                                  kCFStringEncodingUTF8);
    if (newString) {
        return newString;
    }
    return @"";    
}

+ (NSString*)prependHttp:(NSString *)url
{
    if (![[url lowercaseString] hasPrefix:@"http://"]) {
        return [NSString stringWithFormat:@"http://%@", url];
    } else {
        return url;
    }
}

+ (NSString*)displayUrl:(NSString*)url
{
    url = [url stringByReplacingOccurrencesOfString:@"http://www." withString:@""];
    url = [url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    return url;
}

+ (UIColor*)textColorOnBackground:(UIColor*)bgColor
{
    NSInteger numComponents = CGColorGetNumberOfComponents(bgColor.CGColor);
    
    if (numComponents == 4) {
        const CGFloat *components = CGColorGetComponents(bgColor.CGColor);
        CGFloat red = components[0];
        CGFloat green = components[1];
        CGFloat blue = components[2];
        
        if ( (red*0.299 + green*0.587 + blue*0.114) < 186 ) {
            return [UIColor whiteColor];
        }
    }
    
    return [UIColor blackColor];
}


+ (NSString *)genRandString:(int)len {

    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}


+ (NSString*)compressWhitespaces:(NSString*)string {
    NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
    NSPredicate *noEmptyStrings = [NSPredicate predicateWithFormat:@"SELF != ''"];
    
    NSArray *parts = [string componentsSeparatedByCharactersInSet:whitespaces];
    NSArray *filteredArray = [parts filteredArrayUsingPredicate:noEmptyStrings];

    return [filteredArray componentsJoinedByString:@" "];
}


- (NSString *)reducedToWidth:(CGFloat)width withFont:(UIFont *)font {
    
    if ([self sizeWithAttributes:@{NSFontAttributeName:font}].width <= width)
        return self;
    
    NSMutableString *string = [NSMutableString string];
    
    for (NSInteger i = 0; i < [self length]; i++) {
        
        [string appendString:[self substringWithRange:NSMakeRange(i, 1)]];
        
        if ([string sizeWithAttributes:@{NSFontAttributeName:font}].width > width) {
            
            if ([string length] == 1)
                return nil;
            
            [string deleteCharactersInRange:NSMakeRange(i, 1)];
            
            break;
        }
    }
    
    return string;
}

@end
