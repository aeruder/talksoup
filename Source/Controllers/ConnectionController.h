/***************************************************************************
                                ConnectionController.h
                          -------------------
    begin                : Sun Oct  6 15:58:33 CDT 2002
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

#import "netclasses/IRCObject.h"
#import "netclasses/NetTCP.h"

@class ServerController, NSArray, ChannelWindow, TCPConnecting, NSTabViewItem;
@class ChannelView;

@interface ConnectionController : IRCObject < TCPConnecting >
	{
		TCPConnecting *connecting;
		ChannelWindow *window;
		NSMutableDictionary *nameToTab;
		NSMutableDictionary *nameToChannel;
		
		NSTabViewItem *currentTab;
		ChannelView *currentView;
		
		NSTabViewItem *consoleTab;
		ChannelView *consoleView;
	}
- init;
- (void)dealloc;

- addTabWithName: (NSString *)key withLabel: (NSString *)tabLabel;

- connectingStarted: (TCPConnecting *)aConnection;
- connectingFailed: (NSString *)aReason;

- putMessage: aMessage inChannel: aChannel;

- (ChannelWindow *)window;
@end

