/***************************************************************************
                                NSObjectAdditions.m
                          -------------------
    begin                : Fri Apr 11 15:10:32 CDT 2003
    copyright            : (C) 2005 by Andrew Ruder
    email                : aeruder@ksu.edu
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
	void *iterator;
#endif
	Class class;
	int z;
	int y;
	SEL sel;
	NSMutableArray *array = AUTORELEASE([NSMutableArray new]);
	
	class = [self class];

#ifdef __APPLE__	
	iterator = 0;
	while ((list = class_nextMethodList(class, &iterator)))
	{
#else
	for (list = class->methods; list != NULL; list=list->method_next)
	{
#endif
		y = list->method_count;
		for (z = 0; z < y; z++)
		{
			sel = list->method_list[z].method_name;
#ifdef __APPLE__
			[array addObject: AUTORELEASE([[NSString alloc] initWithUTF8String:
			  sel])];
#else
			[array addObject: NSStringFromSelector(sel)];
#endif
		}
	}

	return [NSArray arrayWithArray: array];
}
@end

