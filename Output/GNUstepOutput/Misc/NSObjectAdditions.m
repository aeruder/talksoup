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

#import "Misc/NSObjectAdditions.h"

#import <Foundation/NSArray.h>

#ifdef __APPLE__
#include <objc/objc-class.h>
#endif

@implementation NSObject (Introspection)
+ (NSArray *)methodsDefinedForClass
{
	struct objc_method_list *list;
#ifdef __APPLE__
	struct objc_method_list **out_list;
#endif
	Class class;
	int z;
	int y;
	SEL sel;
	NSMutableArray *array = AUTORELEASE([NSMutableArray new]);
	
	class = [self class];

#ifdef __APPLE__	
	for (out_list = class->methodLists; *out_list != 0; out_list++)
	{
		list = *out_list;
#else
	for (list = class->methods; list != NULL; list=list->method_next)
	{
#endif
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

