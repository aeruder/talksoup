/***************************************************************************
                               TalkSoup.h
						  -------------------
    begin                : Sat Oct  5 02:22:30 CDT 2002
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

#import <Foundation/NSObject.h>

@class ConnectionController, NSNotification, NSMutableArray;

@interface TalkSoup : NSObject
	{
		NSMutableArray *connectionList;
	}
+ (id)sharedInstance;

- addConnection: (ConnectionController *)aConnection;
- removeConnection: (ConnectionController *)aConnection;

- (void)applicationWillFinishLaunching: (NSNotification *)aNotification;
- (void)applicationDidFinishLaunching: (NSNotification *)aNotification;
@end

