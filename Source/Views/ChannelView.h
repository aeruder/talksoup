/***************************************************************************
                                ChannelView.h
                          -------------------
    begin                : Sun Oct  6 01:33:50 CDT 2002
    copyright            : (C) 2002 by Andy Ruder
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

#import <AppKit/NSView.h>

@class ConsoleView, NSSplitView, NSTableView, NSTableColumn, NSScrollView;

@interface ChannelView : NSView
	{
		NSSplitView *splitView;
		NSTableView *userTable;
		NSTableColumn *userColumn;
		NSScrollView *userScroll;
		ConsoleView *consoleView;
	}
- init;

- (ConsoleView *)consoleView;
- (NSScrollView *)userScroll;
- (NSSplitView *)splitView;
- (NSTableColumn *)userColumn;
- (NSTableView *)userTable;
@end
