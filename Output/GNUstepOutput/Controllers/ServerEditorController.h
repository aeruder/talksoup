/***************************************************************************
                                ServerEditorController.h
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
 
@class ServerEditorController;

#ifndef SERVER_EDITOR_CONTROLLER_H
#define SERVER_EDITOR_CONTROLLER_H

#import <Foundation/NSObject.h>

@class NSTextField, NSButton, NSWindow, NSTextView;

@interface ServerEditorController : NSObject
	{
		NSButton *connectButton;
		NSTextView *commandsText;
		NSTextField *portField;
		NSTextField *serverField;
		NSTextField *userField;
		NSTextField *realField;
		NSTextField *passwordField;
		NSTextField *extraField;
		NSButton *okButton;
		NSTextField *entryField;
		NSWindow *window;
		NSTextField *nickField;
	}

- (NSButton *)connectButton;
- (NSTextView *)commandsText;
- (NSTextField *)portField;
- (NSTextField *)serverField;
- (NSTextField *)userField;
- (NSTextField *)realField;
- (NSTextField *)passwordField;
- (NSTextField *)extraField;
- (NSButton *)okButton;
- (NSTextField *)entryField;
- (NSWindow *)window;
- (NSTextField *)nickField;

- (void)setConnect: (id)sender;
- (void)setCommands: (id)sender;
- (void)setPort: (id)sender;
- (void)setServer: (id)sender;
- (void)setUser: (id)sender;
- (void)setPassword: (id)sender;
- (void)setReal: (id)sender;
- (void)setNick: (id)sender;
- (void)setEntry: (id)sender;
@end 

#endif
