/***************************************************************************
                                Channel.m
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

#import "Models/Channel.h"

#import "netclasses/IRCObject.h"

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSArray.h>

#import <AppKit/NSTableView.h>
#import <AppKit/NSTableColumn.h>

const int ChannelUserOperator = 1;
const int ChannelUserVoice = 2;

@implementation ChannelUser
- initWithModifiedName: (NSString *)aName
{
	if (!(self = [super init])) return nil;
	
	[self setUserName: aName];
	
	return self;
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
- setUserName: (NSString *)aName
{
	if (aName == userName) return self;
	
	if ([aName hasPrefix: @"@"])
	{
		userMode = ChannelUserOperator;
		aName = [aName substringFromIndex: 1];
	}
	else if ([aName hasPrefix: @"+"])
	{
		userMode = ChannelUserVoice;
		aName = [aName substringFromIndex: 1];
	}
	
	RELEASE(userName);
	userName = RETAIN(aName);

	return self;
}
- (int)userMode
{
	return userMode;
}
- setUserMode: (int)aMode
{
	if (aMode >= 3 || aMode < 0)
	{
		userMode = 0;
	}
	else
	{
		userMode = aMode;
	}
	return self;
}
- (NSComparisonResult)sortByName: (ChannelUser *)aUser
{
	return [[userName lowercaseIRCString] compare: 
	       [[aUser userName] lowercaseIRCString]];
}
@end

@implementation ChannelFormatter
- (NSString *)stringForObjectValue: (id)anObject
{
	if (![anObject isKindOfClass: [ChannelUser class]]) return nil;
	return [anObject userName];
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
	if (!(self = [super init])) return nil;
	
	resetFlag = YES;
	tempList = [NSMutableArray new];
	userList = [NSMutableArray new];
	lowercaseList = [NSMutableArray new];
	
	return self;
}
- (void)dealloc
{
	DESTROY(identifier);
	DESTROY(tempList);
	DESTROY(userList);
	DESTROY(lowercaseList);
	
	[super dealloc];
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
- addUser: (NSString *)aString
{
	id user;
	int x;

	user = AUTORELEASE([[ChannelUser alloc] initWithModifiedName: aString]);
	
	x = [userList insertionPosition: user 
	                  usingSelector: @selector(sortByName:)];
		
	[userList insertObject: user atIndex: x];
	[lowercaseList insertObject: [[user userName] lowercaseIRCString]
	                    atIndex: x];
	
	return self;
}
- (BOOL)containsUser: aString
{
	return [lowercaseList containsObject: [aString lowercaseIRCString]];
}
- removeUser: (NSString *)aString
{
	int x = [lowercaseList indexOfObject: [aString lowercaseIRCString]];
	if (x != NSNotFound)
	{
		[userList removeObjectAtIndex: x];
		[lowercaseList removeObjectAtIndex: x];
	}
	return self;
}
- userRenamed: (NSString *)oldName to: (NSString *)newName // Keeps mode in tact
{
	int mode;
	int index;

	index = [lowercaseList indexOfObject: [oldName lowercaseIRCString]];
	if (index == NSNotFound) return self;
	
	mode = [[userList objectAtIndex: index] userMode];

	[self removeUser: oldName];
	[self addUser: newName];

	index = [lowercaseList indexOfObject: [newName lowercaseIRCString]];
	if (index == NSNotFound) return self;

	[[userList objectAtIndex: index] setUserMode: mode];

	return self;
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
	NSEnumerator *iter;
	id object;
	
	[userList setArray: tempList];
	[userList sortUsingSelector: @selector(sortByName:)];
	
	[tempList removeAllObjects];
	[lowercaseList removeAllObjects];
	
	iter = [userList objectEnumerator];
	while ((object = [iter nextObject]))
	{
		[lowercaseList addObject: [[object userName] lowercaseIRCString]];
	}
	
	return self;
}
@end

@implementation Channel (TableViewDataSource)
- (int)numberOfRowsInTableView: (NSTableView *)aTableView
{
	return [userList count];  // FIXME: Caching!!!
}
- (id)tableView: (NSTableView *)aTableView 
     objectValueForTableColumn: (NSTableColumn *)aTableColumn
	 row: (int)rowIndex
{
	return RETAIN([userList objectAtIndex: rowIndex]);
}
@end
