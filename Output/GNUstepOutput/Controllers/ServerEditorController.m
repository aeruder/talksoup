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
#import <AppKit/NSScrollView.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSClipView.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSView.h>

@implementation ServerEditorController
- (void)awakeFromNib
{
	[window makeKeyAndOrderFront: nil];
	[window makeFirstResponder: entryField];

	[commandsText setFrame: [[[commandsText enclosingScrollView] 
	  contentView] bounds]];
	[commandsText setHorizontallyResizable: NO];
	[commandsText setVerticallyResizable: YES];
	[commandsText setMinSize: NSMakeSize(0, 0)];
	[commandsText setMaxSize: NSMakeSize(1e7, 1e7)];
	[commandsText setTextContainerInset: NSMakeSize(2, 2)];

	[[commandsText textContainer] setWidthTracksTextView: YES];
	[[commandsText textContainer] setHeightTracksTextView: NO];

	[commandsText setNeedsDisplay: YES];
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
}
- (void)setPort: (id)sender
{
}
- (void)setServer: (id)sender
{
}
- (void)setUser: (id)sender
{
}
- (void)setPassword: (id)sender
{
}
- (void)setReal: (id)sender
{
}
- (void)setNick: (id)sender
{
}
- (void)setEntry: (id)sender
{
}
@end 
