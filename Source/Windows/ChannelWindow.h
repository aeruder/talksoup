/***************************************************************************
                                ChannelWindow.h
                          -------------------
    begin                : Tue Oct  8 12:51:07 CDT 2002
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

#import <AppKit/NSWindow.h>

@class NSView, NSTabView, NSTabViewItem, NSTextField, ChannelView;

@interface ChannelWindow : NSWindow
	{
		NSTextField *typeView;
		NSTextField *nickView;
		NSTabView *tabView;
	}
	- init;
	- (NSTabView *)tabView;
	- (NSTextField *)typeView;
	- (NSTextField *)nickView;
	- updateNick: (NSString *)newNick;
	
@end
