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
#import <Foundation/NSFormatter.h>

@class NSString, NSMutableArray;

@interface ChannelUser : NSObject
	{
		NSString *userName;
		int userMode;
	}

- initWithModifiedName: (NSString *)aName;

- (NSString *)userName;
- setUserName: (NSString *)aName;

- (int)userMode;
- setUserMode: (int)aMode;
@end

extern const int ChannelUserOperator;
extern const int ChannelUserVoice;

@interface ChannelFormatter : NSFormatter
@end

@interface Channel : NSObject
	{
		NSString *identifier;
		NSMutableArray *userList;
		NSMutableArray *lowercaseList;
		NSMutableArray *tempList;
		BOOL resetFlag;
	}
- init;

- setIdentifier: (NSString *)aName;
- (NSString *)identifier;

- addUser: (NSString *)aString;
- (BOOL)containsUser: aString;
- removeUser: (NSString *)aString;
- userRenamed: (NSString *)oldName to: (NSString *)newName;

- addServerUserList: (NSString *)aString;
- endServerUserList;
@end
