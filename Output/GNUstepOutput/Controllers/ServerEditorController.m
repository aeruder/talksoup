/***************************************************************************
                                ServerEditorController.m
                          -------------------
    begin                : Tue May  6 22:58:36 CDT 2003
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

#include "Controllers/ServerEditorController.h"

#include <AppKit/NSTextField.h>
#include <AppKit/NSWindow.h>

@implementation ServerEditorController
- (void)awakeFromNib
{
	[window makeKeyAndOrderFront: nil];
}
- (void)dealloc
{
	DESTROY(connectButton);
	DESTROY(commandsField);
	DESTROY(portField);
	DESTROY(serverField);
	DESTROY(userField);
	DESTROY(realField);
	DESTROY(passwordField);
	DESTROY(extraField);
	DESTROY(okButton);
	DESTROY(entryField);
	DESTROY(window);
	DESTROY(nickField);
	
	[super dealloc];
}
- (NSButton *)connectButton
{
	return connectButton;
}
- (NSTextField *)commandsField
{
	return commandsField;
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
	NSLog(@"%@", okButton);
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
