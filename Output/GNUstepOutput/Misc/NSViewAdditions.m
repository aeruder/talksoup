/***************************************************************************
                          NSViewAdditions.m
                          -------------------
    begin                : Thu Jul 14 02:37:49 CDT 2005
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

#import "Misc/NSViewAdditions.h"
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator.h>

NSString *object_description(NSView *object)
{
	return [object description];
}

NSString *object_description_resizing(NSView *object)
{
	NSMutableString *margins = AUTORELEASE([NSMutableString new]);
	unsigned *mask;
	NSString *str[] = { @"<", @">", @"v", @"^", @"=", @"|", nil };
	unsigned masks[] = { NSViewMinXMargin, NSViewMaxXMargin,
	  NSViewMinYMargin, NSViewMaxYMargin, NSViewWidthSizable,
	  NSViewHeightSizable };
	NSString **test;
	unsigned rlsmask;

	rlsmask = [object autoresizingMask];

	for (test = str, mask = masks; *test != nil; test++, mask++) 
	{
		if (*mask & rlsmask)
			[margins appendString: *test];
	}

	return [NSString stringWithFormat: @"%@ MASK:%@ SUBVIEWS:%@", [object description],
	  margins, ([object autoresizesSubviews]) ? @"YES" : @"NO"];
}

NSString *build_hierarchy(NSString *(*desc)(NSView *object),id object, int level)
{
	int x;
	NSMutableString *mystring;
	id o1;
	id views;
	NSEnumerator *iter;

	mystring = [NSMutableString new];
	for (x = 0; x < level * 2; x++)
	{
		[mystring appendString: @"."];
	}

	[mystring appendString: [NSString stringWithFormat: @"%@\n",
	  desc(object)]];
	views = [object subviews];
	iter = [views objectEnumerator];
	while ((o1 = [iter nextObject]))
	{
		[mystring appendString: build_hierarchy(desc, o1, level+1)];
	}

	o1 = [NSString stringWithString: mystring];
	RELEASE(mystring);

	return o1;
}

@implementation NSView (View_Debugging_GNUstepOutput)
- (NSString *)viewHierarchy
{
	return [self viewHierarchyWithFunction: object_description];
}
- (NSString *)viewHierarchyWithResizingInfo
{
	return [self viewHierarchyWithFunction: object_description_resizing];
}
- (NSString *)viewHierarchyWithFunction: (NSString *(*)(NSView *obj))descFunction
{
	NSMutableString *hierarchy = AUTORELEASE([NSMutableString new]);
	id temparray;
	NSEnumerator *iter;
	id object;
	unsigned index;

	object = self;
	[hierarchy setString: 
	  [NSString stringWithFormat: @"View Hierarchy for %@\n", 
	  [self description]]];
	index = [hierarchy length];
	do {
		[hierarchy insertString: [NSString stringWithFormat: @"%@\n",
		  descFunction(object)] atIndex: index];
	} while ((object != [object superview]) && (object = [object superview]));

	temparray = [self subviews];
	iter = [temparray objectEnumerator];
	while ((object = [iter nextObject]))
	{
		[hierarchy appendString: build_hierarchy(descFunction, object, 1)];
	}

	return [hierarchy substringToIndex: [hierarchy length] - 1];
}
@end
