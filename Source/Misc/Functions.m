/***************************************************************************
                                Functions.m
                          -------------------
    begin                : Sun Oct 13 20:13:10 CDT 2002
    copyright            : (C) 2002 by Andy Ruder
    email                : aeruder@yahoo.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#import "Misc/Functions.h"

#import <Foundation/NSCharacterSet.h>

@implementation NSString (ContainsSpace)
- (BOOL)containsSpace
{
	NSRange aRange;

	aRange = [self rangeOfCharacterFromSet: 
	  [NSCharacterSet whitespaceCharacterSet]];
	
	if (aRange.location == NSNotFound && aRange.length == 0)
	{
		return NO;
	}
	
	return YES;
}
@end
