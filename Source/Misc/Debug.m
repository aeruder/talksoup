/***************************************************************************
                                Debug.m
                          -------------------
    begin                : Wed Mar 13 00:20:02 UTC 2002
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


#import "Misc/Debug.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>

static Class *class_list = 0;
static int size = 30;

static int find_index_class(Class x)
{
	int iter;

	for (iter = 0; iter < size; iter++)
	{
		if (class_list[iter] == x)
		{
			return iter;
		}
	}

	return -1;
}
			
@implementation DebugObject
+ (void)initialize
{
	class_list = calloc(size, sizeof(Class));
}
+ (void)debugClass
{
	int iter;

	iter = find_index_class(Nil);

 	if (iter != -1) class_list[iter] = self;
}
+ (void)stopDebugClass
{
	int iter;
	
	iter = find_index_class(self);
	
	if (iter != -1) class_list[iter] = Nil;
}		
+ allocWithZone: (NSZone *)zone
{
	id obj;
	
	obj = [super allocWithZone: zone];

	if (find_index_class(self) == -1) return obj;

	NSLog(@"%@(%p) Allocated(1)", NSStringFromClass(self), obj);
	
	return obj;
}
- retain
{
	[super retain];
	
	if (find_index_class(isa) == -1) return self;

	NSLog(@"%@(%p) Retained(%d) : %@", NSStringFromClass(isa), self,
	  NSExtraRefCount(self) + 1, [self description]);
	
	return self;
}
- (oneway void)release
{
	if (find_index_class(isa) == -1)
	{
		[super release];
		return;
	}

	NSLog(@"%@(%p) Released(%d) : %@", NSStringFromClass(isa), self,
	  NSExtraRefCount(self),
	  [self description]);
	
	[super release];
}
- (void)dealloc
{
	if (find_index_class(isa) == -1)
	{	
		[super dealloc];
		return;
	}

	NSLog(@"%@(%p) Deallocated", NSStringFromClass(isa), self);

	[super dealloc];
}
@end
