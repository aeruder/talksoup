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
 
#import "Controllers/NamePromptController.h"
#import "Controllers/ConnectionController.h"
#import "Controllers/ContentController.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSString.h>

#import <AppKit/NSWindow.h>
#import <AppKit/NSTextField.h>

@implementation NamePromptController
- (void)awakeFromNib
{
	[window setDelegate: self];
	[window makeKeyAndOrderFront: nil];
	[window makeFirstResponder: typeView];
	RETAIN(self);
}
- (void)dealloc
{
	[window setDelegate: nil];
	DESTROY(window);
	DESTROY(typeView);
	
	[super dealloc];
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
	
	[window close]; // This object is officially destroyed at this point...
	
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
