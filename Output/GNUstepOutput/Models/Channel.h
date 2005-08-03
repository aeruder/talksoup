/***************************************************************************
                                Channel.h
                          -------------------
    begin                : Tue Apr  8 17:15:55 CDT 2003
    copyright            : (C) 2005 by Andrew Ruder
    email                : aeruder@ksu.edu
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

#import <Foundation/NSObject.h>
#import <Foundation/NSFormatter.h>

@class NSString, NSArray, NSMutableArray;

@interface ChannelUser : NSObject <NSCopying>
	{
		NSString *userName;
		NSString *lowerName;
		BOOL hasOps;
		BOOL hasVoice;
		id connection;
	}
- initWithModifiedName: (NSString *)aName
   withConnectionController: aConnection;

- copyWithZone: (NSZone *)aZone;

- (NSString *)userName;
- setUserName: (NSString *)aName;

- (NSString *)formattedName;

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
		NSString *topic;
		NSString *topicDate;
		NSString *topicAuthor;
		id connection;
	}
- initWithIdentifier: (NSString *)aName
   withConnectionController: aConnection;

- setTopic: (NSString *)aTopic;
- (NSString *)topic;

- setTopicAuthor: (NSString *)aTopicAuthor;
- (NSString *)topicAuthor;

- setTopicDate: (NSString *)aTopicDate;
- (NSString *)topicDate;

- setIdentifier: (NSString *)aName;
- (NSString *)identifier;

- sortUserList;

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
