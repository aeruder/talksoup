/***************************************************************************
                                NSObjectAdditions.m
                          -------------------
    begin                : Fri Apr 11 15:10:32 CDT 2003
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

#include "Misc/NSObjectAdditions.h"

#include <Foundation/NSArray.h>

@implementation NSObject (Introspection)
+ (NSArray *)methodsDefinedForClass
{
	MethodList *list;
	Class class;
	int z;
	int y;
	SEL sel;
	NSMutableArray *array = AUTORELEASE([NSMutableArray new]);
	
	class = [self class];
	
	for (list = class->methods; list != NULL; list=list->method_next)
	{
		y = list->method_count;
		for (z = 0; z < y; z++)
		{
			sel = list->method_list[z].method_name;
			[array addObject: NSStringFromSelector(sel)];
		}
	}

	return [NSArray arrayWithArray: array];
}
@end

