/***************************************************************************
                                Channel.m
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

 
#import "Models/Channel.h"
#import "GNUstepOutput.h"

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSArray.h>

#import <AppKit/NSTableView.h>
#import <AppKit/NSTableColumn.h>

@implementation ChannelUser
- initWithModifiedName: (NSString *)aName
{
	if (!(self = [super init])) return nil;
	
	[self setUserName: aName];
	
	return self;
}
- copyWithZone: (NSZone *)aZone
{
	return [[ChannelUser allocWithZone: aZone]
	  initWithModifiedName: [self formattedName]];
}
- (void)dealloc
{
	DESTROY(userName);

	[super dealloc];
}
- (NSString *)userName
{
	return userName;
}
- (NSString *)formattedName
{
	if (hasOps)
	{
		return [NSString stringWithFormat: @"@%@", userName];
	}
	if (hasVoice)
	{
		return [NSString stringWithFormat: @"+%@", userName];
	}

	return userName;
}
- setUserName: (NSString *)aName
{
	if (aName == userName) return self;
	
	hasOps = hasVoice = NO;
	
	if ([aName hasPrefix: @"@"])
	{
		hasOps = YES;
		aName = [aName substringFromIndex: 1];
	}
	else if ([aName hasPrefix: @"+"])
	{
		hasVoice = YES;
		aName = [aName substringFromIndex: 1];
	}
	
	RELEASE(userName);
	userName = RETAIN(aName);

	return self;
}
- (BOOL)isOperator
{
	return hasOps;
}
- setOperator: (BOOL)aOp
{
	hasOps = aOp;
	return self;
}
- (BOOL)isVoice
{
	return hasVoice;
}
- setVoice: (BOOL)aVoice
{
	hasVoice = aVoice;
	return self;
}
- (NSComparisonResult)sortByName: (ChannelUser *)aUser
{
	return [GNUstepOutputLowercase(userName) compare: 
	  GNUstepOutputLowercase([aUser userName])];
}
@end

@implementation ChannelFormatter
- (NSString *)stringForObjectValue: (id)anObject
{
	if (![anObject isKindOfClass: [ChannelUser class]]) return nil;
	return [anObject formattedName];
}
- (BOOL)getObjectValue: (id *)obj forString: (NSString *)string
   errorDescription: (NSString **)error
{
	*obj = AUTORELEASE([[Channel alloc] initWithModifiedName: string]);
	return YES;
}
@end

@interface Channel (TableViewDataSource)
@end

@implementation Channel
- init
{
	return [self initWithIdentifier: nil];
}
- initWithIdentifier: (NSString *)aName
{
	if (!(self = [super init])) return nil;
	
	resetFlag = YES;
	tempList = [NSMutableArray new];
	userList = [NSMutableArray new];
	lowercaseList = [NSMutableArray new];
	
	[self setIdentifier: aName];
	
	return self;
}
- (void)dealloc
{
	DESTROY(identifier);
	DESTROY(tempList);
	DESTROY(userList);
	DESTROY(lowercaseList);
	DESTROY(topic);
	DESTROY(topicAuthor);
	DESTROY(topicDate);
	
	[super dealloc];
}
- setTopic: (NSString *)aTopic
{
	if (topic == aTopic) return self;
	
	RELEASE(topic);
	topic = RETAIN(aTopic);
	
	return self;
}
- (NSString *)topic
{
	return topic;
}
- setTopicAuthor: (NSString *)aTopicAuthor
{
	if (topicAuthor == aTopicAuthor) return self;
	RELEASE(topicAuthor);
	topicAuthor = RETAIN(aTopicAuthor);
	return self;
}
- (NSString *)topicAuthor
{
	return topicAuthor;
}
- setTopicDate: (NSString *)aTopicDate
{
	if (topicDate == aTopicDate) return self;
	
	RELEASE(topicDate);
	topicDate = RETAIN(aTopicDate);
	return self;
}		
- (NSString *)topicDate
{
	return topicDate;
}
- setIdentifier: (NSString *)aIdentifier
{
	if (aIdentifier == identifier) return self;

	RELEASE(identifier);
	identifier = RETAIN(aIdentifier);
	
	return self;
}
- (NSString *)identifier
{
	return identifier;
}
- sortUserList
{
	NSEnumerator *iter;
	id object;
	
	[userList sortUsingSelector: @selector(sortByName:)];
	[lowercaseList removeAllObjects];
	
	iter = [userList objectEnumerator];
	while ((object = [iter nextObject]))
	{
		[lowercaseList addObject: GNUstepOutputLowercase([object userName])];
	}
	
	return self;
}
- addUser: (NSString *)aString
{
	id user;

	user = AUTORELEASE([[ChannelUser alloc] initWithModifiedName: aString]);
	
	[userList addObject: user];
	
	[self sortUserList];
	
	return self;
}
- (BOOL)containsUser: aString
{
	return [lowercaseList containsObject: GNUstepOutputLowercase(aString)];
}
- removeUser: (NSString *)aString
{
	int x = [lowercaseList indexOfObject: GNUstepOutputLowercase(aString)];
	if (x != NSNotFound)
	{
		[userList removeObjectAtIndex: x];
		[lowercaseList removeObjectAtIndex: x];
	}
	return self;
}
- userRenamed: (NSString *)oldName to: (NSString *)newName // Keeps mode in tact
{
	BOOL hasVoice;
	BOOL hasOps;
	int index;

	index = [lowercaseList indexOfObject: GNUstepOutputLowercase(oldName)];
	if (index == NSNotFound) return self;
	
	hasVoice = [[userList objectAtIndex: index] isVoice];
	hasOps = [[userList objectAtIndex: index] isOperator];
	
	[self removeUser: oldName];
	[self addUser: newName];

	index = [lowercaseList indexOfObject: GNUstepOutputLowercase(newName)];
	if (index == NSNotFound) return self;

	[[userList objectAtIndex: index] setVoice: hasVoice];
	[[userList objectAtIndex: index] setVoice: hasOps];

	return self;
}
- (ChannelUser *)userWithName: (NSString *)name
{
	int index;

	index = [lowercaseList indexOfObject: GNUstepOutputLowercase(name)];

	if (index == NSNotFound) return nil;

	return [userList objectAtIndex: index];
}	
- addServerUserList: (NSString *)aString
{
	NSEnumerator *iter;
	NSArray *array = [aString componentsSeparatedByString: @" "];
	id object;
	id user;
	
	iter = [array objectEnumerator];
	while ((object = [iter nextObject]))
	{
		if ([object length] == 0) break;
		user = AUTORELEASE([[ChannelUser alloc] initWithModifiedName: object]);
		[tempList addObject: user];
	}
	
	return self;
}
- endServerUserList
{
	[userList setArray: tempList];
	[tempList removeAllObjects];
	
	[self sortUserList];
	
	return self;
}
- (NSArray *)userList
{
	return [NSArray arrayWithArray: userList];
}
@end

@implementation Channel (TableViewDataSource)
- (int)numberOfRowsInTableView: (NSTableView *)aTableView
{
	return [userList count];
}
- (id)tableView: (NSTableView *)aTableView 
     objectValueForTableColumn: (NSTableColumn *)aTableColumn
	 row: (int)rowIndex
{
	return [userList objectAtIndex: rowIndex];
}
@end
