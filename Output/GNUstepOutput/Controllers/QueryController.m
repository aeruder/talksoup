/***************************************************************************
                                QueryController.m
                          -------------------
    begin                : Sat Jan 18 01:38:06 CST 2003
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

#include <AppKit/AppKit.h>
#include "QueryController.h"

@implementation QueryController
- (void)awakeFromNib
{	
	[chatView setHorizontallyResizable: NO];
	[chatView setVerticallyResizable: YES];
	[chatView setMinSize: NSMakeSize(0, 0)];
	[chatView setMaxSize: NSMakeSize(1e7, 1e7)];
	[[[chatView textStorage] mutableString] setString: @"BLAaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh"];
	[chatView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[[chatView textContainer] setContainerSize:
	  NSMakeSize([chatView frame].size.width, 1e7)];
	[[chatView textContainer] setWidthTracksTextView: YES];
	[chatView setTextContainerInset: NSMakeSize(2, 0)];

	[chatView setBackgroundColor: [NSColor colorWithCalibratedRed: 1.0
	  green: 0.9725 blue: 0.8627 alpha: 1.0]];
}
- (id)chatView
{
	return chatView;
}
- (id)window
{
	return window;
}
@end
