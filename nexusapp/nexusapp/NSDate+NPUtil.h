//
//  NSDate+NPUtil.h
//  nexusapp
//
//  Created by Ren Liu on 5/19/14.
//
//

#import <Foundation/Foundation.h>

@interface NSDate (NPUtil)

/**
 Returns a new date with first second of the day of the receiver.
 */
- (NSDate *)beginningOfDay;

/**
 Returns a new date with the last second of the day of the receiver.
 */
- (NSDate *)endOfDay;

///------------------------------------------
/// @name Calculating Beginning / End of Week
///------------------------------------------

/**
 Returns a new date with first second of the first weekday of the receiver, taking into account the current calendar's `firstWeekday` property.
 */
- (NSDate *)beginningOfWeek;

/**
 Returns a new date with last second of the last weekday of the receiver, taking into account the current calendar's `firstWeekday` property.
 */
- (NSDate *)endOfWeek;

///-------------------------------------------
/// @name Calculating Beginning / End of Month
///-------------------------------------------

/**
 Returns a new date with the first second of the first day of the month of the receiver.
 */
- (NSDate *)beginningOfMonth;

/**
 Returns a new date with the last second of the last day of the month of the receiver.
 */
- (NSDate *)endOfMonth;

///------------------------------------------
/// @name Calculating Beginning / End of Year
///------------------------------------------

/**
 Returns a new date with the first second of the first day of the year of the receiver.
 */
- (NSDate *)beginningOfYear;

/**
 Returns a new date with the last second of the last day of the year of the receiver.
 */
- (NSDate *)endOfYear;

@end
