/***************************************************************************
                                Channel.h
                          -------------------
    begin                : Tue Apr  8 17:15:55 CDT 2003
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

@class Channel;

#ifndef CHANNEL_H
#define CHANNEL_H

#include <Foundation/NSObject.h>
#include <Foundation/NSFormatter.h>

@class NSString, NSArray, NSMutableArray;

@interface ChannelUser : NSObject
	{
		NSString *userName;
		BOOL hasOps;
		BOOL hasVoice;
	}
- initWithModifiedName: (NSString *)aName;

- (NSString *)userName;
- setUserName: (NSString *)aName;

- (BOOL)isOperator;
- setOperator: (BOOL)aOp;

- (BOOL)isVoice;
- setVoice: (BOOL)aVoice;
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
- initWithIdentifier: (NSString *)aName;

- setIdentifier: (NSString *)aName;
- (NSString *)identifier;

- addUser: (NSString *)aString;
- (BOOL)containsUser: aString;
- removeUser: (NSString *)aString;
- userRenamed: (NSString *)oldName to: (NSString *)newName;
- (NSArray *)userList;
- (ChannelUser *)userWithName: (NSString *)name;

- addServerUserList: (NSString *)aString;
- endServerUserList;
@end

#endif
