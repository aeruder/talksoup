/***************************************************************************
                                NamePromptController.m
                          -------------------
    begin                : Thu May  1 11:45:04 CDT 2003
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
 
#include "Controllers/NamePromptController.h"
#include "Controllers/ConnectionController.h"
#include "Controllers/ContentController.h"
#include "TalkSoupBundles/TalkSoup.h"

#include <Foundation/NSString.h>

#include <AppKit/NSWindow.h>
#include <AppKit/NSTextField.h>

@implementation NamePromptController
- (void)awakeFromNib
{
	[window setDelegate: self];
	[window makeKeyAndOrderFront: nil];
	[window makeFirstResponder: typeView];
}
- (void)returnHit: (NSTextField *)sender
{
	id components;
	id x;
	id content;
	
	components = [[sender stringValue] separateIntoNumberOfArguments: 2];
	
	if ([components count] == 0)
	{
		[window close];
		return;
	}
	
	x = [ConnectionController new];
	[x connectToServer: [components objectAtIndex: 0] onPort: 6667];
	
	[window close];
	
	content = [x contentController];
	
	[[content window] makeKeyAndOrderFront: nil];
	[[content window] makeFirstResponder: [content typeView]];
}
- (NSWindow *)window
{
	return window;
}
- (NSTextField *)typeView
{
	return typeView;
}
@end

@interface NamePromptController (WindowDelegate)
@end

@implementation NamePromptController (WindowDelegate)
- (void)windowWillClose: (NSNotification *)aNotification
{
	[window setDelegate: nil];
	DESTROY(window);
	RELEASE(self);
}
@end