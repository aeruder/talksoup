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

#ifndef SERVER_LIST_CONTROLLER_H
#define SERVER_LIST_CONTROLLER_H

#include <Foundation/NSObject.h>

@class NSButton, NSOutlineView, NSWindow, NSTableColumn, NSScrollView;

@interface ServerListController : NSObject
	{
		NSButton *connectButton;
		NSButton *addGroupButton;
		NSButton *removeButton;
		NSButton *addEntryButton;
		NSButton *editButton;
		NSOutlineView *outline;
		NSScrollView *scrollView;
		NSWindow *window;
		NSTableColumn *serverColumn;
	}
- (void)editHit: (NSButton *)sender;
- (void)addEntryHit: (NSButton *)sender;
- (void)removeHit: (NSButton *)sender;
- (void)connectHit: (NSButton *)sender;
- (void)addGroupHit: (NSButton *)sender;

- (NSOutlineView *)outlineView;
- (NSWindow *)window;
@end

#endif
