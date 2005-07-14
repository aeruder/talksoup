/***************************************************************************
                                ServerEditorController.m
                          -------------------
    begin                : Tue May  6 22:58:36 CDT 2003
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

#import "Controllers/ServerEditorController.h"

#import <AppKit/NSTextField.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSTextContainer.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSView.h>

@implementation ServerEditorController
- (void)awakeFromNib
{
	[window makeKeyAndOrderFront: nil];
	[window makeFirstResponder: entryField];
	[entryField setNextKeyView: nickField];
	[nickField setNextKeyView: realField];
	[realField setNextKeyView: passwordField];
	[passwordField setNextKeyView: userField];
	[userField setNextKeyView: serverField];
	[serverField setNextKeyView: portField];
	[portField setNextKeyView: commandsText];
	[commandsText setNextKeyView: entryField];

	[commandsText setHorizontallyResizable: NO];
	[commandsText setVerticallyResizable: YES];
	[commandsText setMinSize: NSMakeSize(0, 0)];
	[commandsText setMaxSize: NSMakeSize(1e7, 1e7)];
	[commandsText setTextContainerInset: NSMakeSize(2, 2)];
	[[commandsText textContainer] setContainerSize:
	  NSMakeSize([commandsText frame].size.width, 1e7)];
	[[commandsText textContainer] setWidthTracksTextView: YES];
	[commandsText setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	
}
- (void)dealloc
{
	DESTROY(window);
	
	[super dealloc];
}
- (NSButton *)connectButton
{
	return connectButton;
}
- (NSTextView *)commandsText
{
	return commandsText;
}
- (NSTextField *)portField
{
	return portField;
}
- (NSTextField *)serverField
{
	return serverField;
}
- (NSTextField *)userField
{
	return userField;
}
- (NSTextField *)realField
{
	return realField;
}
- (NSTextField *)passwordField
{
	return passwordField;
}
- (NSTextField *)extraField
{
	return extraField;
}
- (NSButton *)okButton
{
	return okButton;
}
- (NSTextField *)entryField
{
	return entryField;
}
- (NSWindow *)window
{
	return window;
}
- (NSTextField *)nickField
{
	return nickField;
}
- (void)setConnect: (id)sender
{
}
- (void)setCommands: (id)sender
{
	[okButton performClick: nil];
}
- (void)setPort: (id)sender
{
	[okButton performClick: nil];
}
- (void)setServer: (id)sender
{
	[okButton performClick: nil];
}
- (void)setUser: (id)sender
{
	[okButton performClick: nil];
}
- (void)setPassword: (id)sender
{
	[okButton performClick: nil];
}
- (void)setReal: (id)sender
{
	[okButton performClick: nil];
}
- (void)setNick: (id)sender
{
	[okButton performClick: nil];
}
- (void)setEntry: (id)sender
{
	[okButton performClick: nil];
}
@end 
