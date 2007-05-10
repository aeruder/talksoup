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

@implementation AttributedTabViewItem
- (void)drawLabel: (BOOL)shouldTruncateLabel inRect: (NSRect)tabRect
{
	id string;
	
	string = [self label];
	[self setLabel: @""];
	[super drawLabel: shouldTruncateLabel inRect: tabRect];
	[self setLabel: string];
	
	[attributedLabel drawInRect: tabRect];
	
	[string drawInRect: tabRect];
}
- setAttributedLabel: (NSAttributedString *)aString
{
	if (aString == attributedLabel) return self;
	
	RELEASE(attributedLabel);
	attributedLabel = RETAIN(aString);

	[[self tabView] setNeedsDisplay: YES];

	[self setLabel: [attributedLabel string]];

	return self;
}
- (NSAttributedString *)attributedLabel
{
	return attributedLabel;
}
@end

