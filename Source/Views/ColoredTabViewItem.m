/***************************************************************************
                                ColoredTabViewItem.m
                          -------------------
    begin                : Thu Dec  5 00:25:40 CST 2002
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

#import "Views/ColoredTabViewItem.h"

#import <AppKit/NSColor.h>

@implementation ColoredTabViewItem
- (void)drawLabel: (BOOL)shouldTruncateLabel inRect: (NSRect)tabRect
{
	id string;
	
	string = [self label];
	[self setLabel: @""];
	[super drawLabel: shouldTruncateLabel inRect: tabRect];
	[self setLabel: string];
	
	if (color)
	{
		string = AUTORELEASE(([[NSAttributedString alloc] initWithString:
		  [self label] attributes: [NSDictionary dictionaryWithObjectsAndKeys:
		    color, NSForegroundColorAttributeName,
			[[self tabView] font], NSFontAttributeName,
		    nil]]));
	}
	else
	{
		string = AUTORELEASE(([[NSAttributedString alloc] initWithString:
		  [self label] attributes: [NSDictionary dictionaryWithObjectsAndKeys:
		   [NSColor blackColor], NSForegroundColorAttributeName,
		   [[self tabView] font], NSFontAttributeName,
		   nil]]));
	}

	[string drawInRect: tabRect];
}
- setLabelColor: (NSColor *)aColor
{
	if (aColor == color) return self;
	
	RELEASE(color);
	color = RETAIN(aColor);

	[[self tabView] setNeedsDisplay: YES];

	return self;
}
- (NSColor *)labelColor
{
	return color;
}
@end

