/***************************************************************************
                                ColoredTabViewItem.m
                          -------------------
    begin                : Thu Dec  5 00:25:40 CST 2002
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

#include "Views/AttributedTabViewItem.h"

#include <AppKit/NSAttributedString.h>
#include <AppKit/NSColor.h>

@implementation AttributedTabViewItem
- (void)dealloc
{
	DESTROY(attributedLabel);
	[super dealloc];
}
- (void)drawLabel: (BOOL)shouldTruncateLabel inRect: (NSRect)tabRect
{
	id string;
	
	string = [self label];

	[self setLabel: @""];
	[super drawLabel: shouldTruncateLabel inRect: tabRect];
	[self setLabel: string]; 	
	
	[attributedLabel drawAtPoint: NSMakePoint(tabRect.origin.x, NSMaxY(tabRect) + 4)];	
}
- setLabelColor: (NSColor *)aColor
{
	if (!aColor)
	{
		[attributedLabel removeAttribute: NSForegroundColorAttributeName
		  range: NSMakeRange(0, [attributedLabel length])];
		[[self tabView] setNeedsDisplay: YES];
		return self;
	}
	
	[attributedLabel addAttribute: NSForegroundColorAttributeName value:
	  aColor range: NSMakeRange(0, [attributedLabel length])];
	
	[[self tabView] setNeedsDisplay: YES];

	return self;
}	
- setAttributedLabel: (NSAttributedString *)aString
{
	if (!aString) return self;
	
	RELEASE(attributedLabel);
	attributedLabel = [[NSMutableAttributedString alloc] initWithAttributedString:
	  aString];

	[attributedLabel addAttribute: NSFontAttributeName value:
	  [NSFont fontWithName: @"Helvetica" size: 12.0] 
	  range: NSMakeRange(0, [attributedLabel length])];
	  
	[self setLabel: [attributedLabel string]];

	[[self tabView] setNeedsDisplay: YES];

	return self;
}
- (NSAttributedString *)attributedLabel
{
	return AUTORELEASE([[NSAttributedString alloc] initWithAttributedString: 
	  attributedLabel]);
}
@end

