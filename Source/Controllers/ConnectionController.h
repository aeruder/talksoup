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

NSArray *SeparateOutFirstWord(NSString *aString);

@class ServerController, NSArray, ChannelWindow, TCPConnecting, NSTabViewItem;
@class ChannelView, ConsoleView, ChannelViewController;

@interface ConnectionController : IRCObject < TCPConnecting >
	{
		TCPConnecting *connecting;
		ChannelWindow *window;
		
		NSMutableDictionary *nameToChannel;
		NSMutableDictionary *nameToDeadChannel;
		
		ChannelViewController *console;
		ChannelViewController *current;

		NSString *nextServer;
	}
- init;
- (void)dealloc;

- connectingStarted: (TCPConnecting *)aConnection;
- connectingFailed: (NSString *)aReason;

- putMessage: aMessage inChannel: aChannel;

- (ChannelViewController *)addTabWithName: (NSString *)aName
    withLabel: (NSString *)aLabel withUserList: (BOOL)flag;
- (void)removeTabWithName: (NSString *)aName;

- (ChannelWindow *)window;

- (NSArray *)channelsWithUser: (NSString *)aUser;
@end

