/***************************************************************************
                                Functions.m
                          -------------------
    begin                : Sat Apr  5 22:21:33 CST 2003
    copyright            : (C) 2003 by Andy Ruder
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

#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSCharacterSet.h>
 
static NSArray *get_first_word(NSString *arg)
{
	NSRange aRange;
	NSString *first, *rest;
	id white = [NSCharacterSet whitespaceCharacterSet];

	arg = [arg stringByTrimmingCharactersInSet: white];
	  
	if ([arg length] == 0)
	{
		return [NSArray arrayWithObjects: nil];
	}

	aRange = [arg rangeOfCharacterFromSet: white];

	if (aRange.location == NSNotFound && aRange.length == 0)
	{
		return [NSArray arrayWithObjects: arg, nil];
	}
	
	rest = [[arg substringFromIndex: aRange.location]
	  stringByTrimmingCharactersInSet: white];
	
	first = [arg substringToIndex: aRange.location];

	return [NSArray arrayWithObjects: first, rest, nil];
}

@implementation NSString (Separation)
- separateIntoNumberOfArguments: (int)num
{
	NSMutableArray *array = AUTORELEASE([NSMutableArray new]);
	id object;
        int temp;
        id string = self;
	
	if (num <= 1)
	{
		return [NSArray arrayWithObject: [string 
		  stringByTrimmingCharactersInSet: 
		    [NSCharacterSet whitespaceCharacterSet]]];
	}
	if (num == 2)
	{
		return get_first_word(string);
	}
	
	while (num != 1)
	{
		object = get_first_word(string);
		temp = [object count];
		switch(temp)
		{
			case 0:
				return [NSArray arrayWithObjects: nil];
			case 1:
				[array addObject: [object objectAtIndex: 0]];
				return array;
			case 2:
				string = [object objectAtIndex: 1];
				[array addObject: [object objectAtIndex: 0]];
				num--;
		}
	}
	[array addObject: string];
	return array;
}
@end
