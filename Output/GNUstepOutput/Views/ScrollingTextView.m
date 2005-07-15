/***************************************************************************
                                ScrollingTextView.m
                          -------------------
    begin                : Tue Nov  5 22:24:03 CST 2002
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

#import "Views/ScrollingTextView.h"

#import <AppKit/NSClipView.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSView.h>
#import <Foundation/NSGeometry.h>

#include <math.h>

@implementation ScrollingTextView
- (void)pageUp
{
	NSRect vis = [[[self enclosingScrollView] contentView] 
	  documentVisibleRect];
	unsigned int y;

	y = NSMinY(vis);

	y = (y < vis.size.height) ? 0 : y - vis.size.height;
	
	[self scrollPoint: NSMakePoint(0, y)];
}
- (void)pageDown
{
	NSRect vis = [[[self enclosingScrollView] contentView] 
	  documentVisibleRect];
	unsigned int max = NSMaxY([self frame]);
	unsigned int y;
	
	y = NSMinY(vis);

	y = ((y + vis.size.height) > max) ? max : y + vis.size.height;
	
	[self scrollPoint: NSMakePoint(0, y)];
}
- (void)setFrame: (NSRect)frameRect
{
	BOOL scroll = NO;

	if (fabs(NSMaxY([[[self enclosingScrollView] contentView] 
	                   documentVisibleRect]) - NSMaxY([self frame])) < 5)
	{
		scroll = YES;
	}
	[super setFrame: frameRect];

	if (scroll)
	{
		[self scrollPoint: NSMakePoint(0, NSMaxY([self frame]))];
	}
}
- (void)setFrameSize: (NSSize)frameSize
{
	BOOL scroll = NO;

	if (fabs(NSMaxY([[[self enclosingScrollView] contentView] 
	                   bounds]) - NSMaxY([self frame])) < 5)
	{
		scroll = YES;
	}
	[super setFrameSize: frameSize];

	if (scroll)
	{
		[self scrollPoint: NSMakePoint(0, NSMaxY([self frame]))];
	}
}
@end

