/***************************************************************************
                                Channel.h
                          -------------------
    begin                : Mon Oct  7 01:56:55 CDT 2002
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

@class NSString, NSMutableArray;

@interface ChannelUser : NSObject
	{
		NSString *name;
		int mode;
	}
@end

@interface Channel : NSObject
	{
		NSString *name;
		NSMutableArray *userList;
		NSMutableArray *lowercaseList;
		NSMutableArray *tempList;
		NSMutableArray *tempLowercaseList;
		BOOL resetFlag;
	}
- init;

- setName: (NSString *)aName; // Should be the same as the corresponding
                              // ChannelViewController
- (NSString *)name;

- addUser: (NSString *)aString;
- (BOOL)containsUser: aString;
- removeUser: (NSString *)aString;

- addServerUserList: (NSString *)aString;
- endServerUserList;
@end
