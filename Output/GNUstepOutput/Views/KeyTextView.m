/***************************************************************************
                                KeyTextView.m
                          -------------------
    begin                : Fri Apr 11 14:14:45 CDT 2003
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

#import "Views/KeyTextView.h"

#import <AppKit/NSEvent.h>
#import <AppKit/NSTextStorage.h>

@implementation KeyTextView
- setKeyTarget: (id)aTarget
{
	keyTarget = aTarget;
	return self;
};
- setKeyAction: (SEL)aSel
{
	keyAction = aSel;
	return self;
}
- (void)keyDown: (NSEvent *)theEvent
{
	BOOL (*function)(id, SEL, NSEvent *, id);
	
	if (!keyTarget || !keyAction)
	{
		[super keyDown: theEvent];
		return;
	}
	
	function = (BOOL (*)(id, SEL, NSEvent *, id))
	   [keyTarget methodForSelector: keyAction];
	
	if (function)
	{
		if ((function(keyTarget, keyAction, theEvent, self)))
			[super keyDown: theEvent];
	}
	else
	{
		[super keyDown: theEvent];
	}
}
- (void)setStringValue: (NSString *)aValue
{
	[self setString: aValue]; 
	[self setSelectedRange: NSMakeRange([aValue length], 0)];
}
@end
