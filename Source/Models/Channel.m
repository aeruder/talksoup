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

NSString *nickWithStrippedModifiers(NSString *nick)
{
	if ([nick hasPrefix: @"@"])
	{
		return [nick substringFromIndex: 1];
	}
	
	if ([nick hasPrefix: @"+"])
	{
		return [nick substringFromIndex: 1];
	}

	return nick;
}

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
	tempLowercaseList = [NSMutableArray new];
	
	return self;
}
- (void)dealloc
{
	DESTROY(name);
	DESTROY(tempList);
	DESTROY(userList);
	DESTROY(lowercaseList);
	DESTROY(tempLowercaseList);
	[super dealloc];
}
- setName: (NSString *)aName
{
	if (aName == name) return self;

	RELEASE(name);
	name = RETAIN(aName);
	
	return self;
}
- (NSString *)name
{
	return name;
}
- addUser: (NSString *)aString
{
	[userList addObject: aString];
	[lowercaseList addObject: [nickWithStrippedModifiers(aString) 
	   lowercaseIRCString]];
	
	return self;
}
- (BOOL)containsUser: aString
{
	return [lowercaseList containsObject: [aString lowercaseIRCString]];
}
- removeUser: (NSString *)aString
{
	int x = [lowercaseList indexOfObject: [aString lowercaseString]];
	if (x != NSNotFound)
	{
		[userList removeObjectAtIndex: x];
		[lowercaseList removeObjectAtIndex: x];
	}
	return self;
}
- addServerUserList: (NSString *)aString
{
	NSEnumerator *iter;
	NSArray *array = [aString componentsSeparatedByString: @" "];
	id object;
	
	NSLog(@"Adding user list %@", aString);
	
	iter = [array objectEnumerator];
	while ((object = [iter nextObject]))
	{
		if ([object length] == 0) break;
		[tempList addObject: object];
		[tempLowercaseList addObject: [nickWithStrippedModifiers(object) 
		  lowercaseIRCString]];
	}
	
	return self;
}
- endServerUserList
{
	NSLog(@"Ending...");
	[userList setArray: tempList];
	[lowercaseList setArray: tempLowercaseList];
	[tempList removeAllObjects];
	[tempLowercaseList removeAllObjects];
	NSLog(@"userList: %@ tempList: %@", userList, tempList);
	return self;
}
@end

@implementation Channel (TableViewDataSource)
- (int)numberOfRowsInTableView: (NSTableView *)aTableView
{
	NSLog(@"%d items", [userList count]);
	return [userList count];  // FIXME: Caching!!!
}
- (id)tableView: (NSTableView *)aTableView 
     objectValueForTableColumn: (NSTableColumn *)aTableColumn
	 row: (int)rowIndex
{
	NSLog(@"%@", [userList objectAtIndex: rowIndex]);
	return RETAIN([userList objectAtIndex: rowIndex]);
}
@end
