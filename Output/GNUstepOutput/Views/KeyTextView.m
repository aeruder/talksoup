/***************************************************************************
                                TabTextView.m
                          -------------------
    begin                : Fri Apr 11 14:14:45 CDT 2003
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

#include "Views/TabTextView.h"

#include <AppKit/NSEvent.h>
#include <AppKit/NSTextStorage.h>

@implementation TabTextView
- setTabTarget: (id)aTarget
{
	tabTarget = aTarget;
	return self;
};
- setTabAction: (SEL)aSel
{
	tabAction = aSel;
	return self;
}
- setNonTabAction: (SEL)aSel
{
	nonTabAction = aSel;
	return self;
}
- (void)keyDown: (NSEvent *)theEvent
{
	NSString *characters = [theEvent characters];
	unichar character = 0;
	
	if (!tabTarget)
	{
		[super keyDown: theEvent];
		return;
	}
	
	if ([characters length] > 0)
	{
		character = [characters characterAtIndex: 0];
	}
	
	if (character != NSTabCharacter && character && nonTabAction)
	{
		NSLog(@"Non-tab pressed...");
		[tabTarget performSelector: nonTabAction withObject: self];
	}
	
	if (character == NSTabCharacter && tabAction)
	{
		[tabTarget performSelector: tabAction withObject: self];
	}
	else
	{
		[super keyDown: theEvent];
	}
}
- (void)setStringValue: (NSString *)aValue
{
	[[self textStorage] setAttributedString: 
	  AUTORELEASE([[NSAttributedString alloc] initWithString: aValue])];
	[self setSelectedRange: NSMakeRange([aValue length], 0)];
}
@end
