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

#import <Foundation/NSDictionary.h>

NSArray *SeparateOutFirstWord(NSString *aString);

@class TCPConnecting, ChannelWindow, TalkController, QueryController;
@class NSTabViewItem, ChannelController, NSString, NSHost;
@class ColoredTabViewItem;

@interface ConnectionController : IRCObject < TCPConnecting >
	{
		TCPConnecting *connecting;
		NSMutableDictionary *nameToChannel;
		NSMutableDictionary *nameToChannelData;
		NSMutableDictionary *nameToQuery;
		NSMutableDictionary *nameToTalk;
		NSMutableDictionary *nameToDeadChannel; // Parted channels
		NSMutableDictionary *nameToTypedName; // Typed name
		NSMutableArray *connectCommands; // Commands to run when connection is made
		NSMapTable *talkToHolder; // Maps views to container;
		NSString *currentHost;
		ChannelWindow *window;
		QueryController *console;
		TalkController *current;

		int typedPort;
		NSString *typedHost;
	}
- init;
- (void)dealloc;

- connectingStarted: (TCPConnecting *)aConnection;
- connectingFailed: (NSString *)aReason;

- addConnectCommands: (NSArray *)aCommand;
- addConnectCommand: (NSString *)aCommand;
- resetConnectCommands;

- (ColoredTabViewItem *)addTabViewItemWithName: (NSString *)key 
    withView: (TalkController *)aView;
- removeTabViewItemWithName: (NSString *)key;

- setLabel: (NSString *)aLabel forView: (TalkController *)aView;

- putMessage: (NSString *)message in: channel;

- (NSArray *)channelsWithUser: (NSString *)aUser;

- updateHostName;
@end

