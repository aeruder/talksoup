/***************************************************************************
                      BundleConfigureController.m
                          -------------------
    begin                : Mon Sep  8 00:16:46 CDT 2003
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

#include "Controllers/BundleConfigureController.h"
#include "GNUstepOutput.h"

#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSWindow.h>

@implementation BundleConfigureController
- (void)awakeFromNib
{
	[availableTable setDelegate: self];
	[loadedTable setDelegate: self];
	
	availCol = [availableTable tableColumnWithIdentifier: @"available"];
	loadCol = [loadedTable tableColumnWithIdentifier: @"loaded"];

	[descriptionText setHorizontallyResizable: NO];
	[descriptionText setVerticallyResizable: YES];
	[descriptionText setMinSize: NSMakeSize(0, 0)];
	[descriptionText setMaxSize: NSMakeSize(1e7, 1e7)];
	[[descriptionText textContainer] setWidthTracksTextView: YES];
	[descriptionText setTextContainerInset: NSMakeSize(2, 0)];
	[descriptionText setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];

	[descriptionText setText:
	 @"Welcome to the TalkSoup Bundle Configuration Interface.\n\n"
	 @"TalkSoup is a highly-modular IRC client, and parts of it "
	 @"can be loaded and unloaded while it is running.  These "
	 @"optional parts are called bundles.  There are two sets "
	 @"of bundles.  The first set, the input bundles, affect "
	 @"data coming into the IRC client. The second set, the output "
	 @"bundles, affect the data leaving the IRC client.  The pop up "
	 @"button located at the top is used to change which of these "
	 @"sets are being configured.\n\n"
	 
	 @"Above are two tables of bundles.  On the left, there is a "
	 @"table showing the loaded bundles and the order they are loaded "
	 @"in.  The arrows on the left can be used to move the selected "
	 @"bundle up and down throughout the list of loaded bundles.  On "
	 @"the right is the bundles which can be loaded but currently are "
	 @"not.  Use the arrows in the center to move bundles between "
	 @"the two tables.\n\n"

	 @"Clicking on any bundle will show information about that bundle "
	 @"in this text area."];

	[window makeKeyAndOrderFront: nil];
}	
- (void)dealloc
{
	RELEASE(window);
	RELEASE(availableTable);
	RELEASE(loadedTable);
	RELEASE(descriptionText);

	[super dealloc];
}
- (NSWindow *)window
{
	return window;
}
- (void)upHit: (id)sender
{
}
- (void)refreshHit: (id)sender
{
}
- (void)cancelHit: (id)sender
{
}
- (void)okHit: (id)sender
{
}
- (void)downHit: (id)sender
{
}
- (void)leftHit: (id)sender
{
}
- (void)rightHit: (id)sender
{
}
- (void)showingSelected: (id)sender
{
}
@end
