/***************************************************************************
                                ServerListController.h
                          -------------------
    begin                : Wed Apr 30 14:31:01 CDT 2003
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

@class ServerListController;

@class NSString;

extern NSString *ServerListInfoWindowFrame;
extern NSString *ServerListInfoEncoding;
extern NSString *ServerListInfoServer;
extern NSString *ServerListInfoPort;
extern NSString *ServerListInfoName;
extern NSString *ServerListInfoEntries;
extern NSString *ServerListInfoCommands;
extern NSString *ServerListInfoAutoConnect;

#ifndef SERVER_LIST_CONTROLLER_H
#define SERVER_LIST_CONTROLLER_H

#import <Foundation/NSObject.h>

@class NSButton, NSBrowser, NSWindow, NSTableColumn, NSScrollView, NSArray;
@class NSDictionary;

@interface ServerListController : NSObject
	{
		NSButton *connectButton;
		NSButton *addGroupButton;
		NSButton *removeButton;
		NSButton *addEntryButton;
		NSButton *editButton;
		NSButton *forceButton;
		NSBrowser *browser;
		NSScrollView *scrollView;
		NSWindow *window;
		NSTableColumn *serverColumn;
		id editor;
		int wasEditing;
	}

+ (BOOL)startAutoconnectServers;
+ (NSDictionary *)serverInGroup: (int)group row: (int)row;
+ (void)setServer: (NSDictionary *)x inGroup: (int)group row: (int)row;
+ (BOOL)serverFound: (NSDictionary *)x inGroup: (int *)group row: (int *)row;

- (void)editHit: (NSButton *)sender;
- (void)addEntryHit: (NSButton *)sender;
- (void)removeHit: (NSButton *)sender;
- (void)connectHit: (NSButton *)sender;
- (void)addGroupHit: (NSButton *)sender;
- (void)forceHit: (NSButton *)sender;

- (NSBrowser *)browser;
- (NSWindow *)window;
@end

#endif
