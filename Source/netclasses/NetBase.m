/***************************************************************************
                                NetBase.m
                          -------------------
    begin                : Fri Nov  2 01:19:16 UTC 2001
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
#include <string.h>
#import "NetBase.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSString.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSException.h>
#import <Foundation/NSAutoreleasePool.h>

NSString *NetException = @"NetException";
NSString *FatalNetException = @"FatalNetException";

NetApplication *netApplication;

@implementation NetApplication
+ sharedInstance
{
	return (netApplication) ? (netApplication) : [[NetApplication alloc] init];
}
- init
{
	if (!(self = [super init])) return nil;
	if (netApplication)
	{
		[super dealloc];
		return nil;
	}
	netApplication = RETAIN(self);
	
	descTable = NSCreateMapTable(NSIntMapKeyCallBacks, 
	 NSNonRetainedObjectMapValueCallBacks, 100);
	
	portArray = [NSMutableArray new];
	netObjectArray = [NSMutableArray new];
	badDescs = [NSMutableArray new];
	return self;
}
- (void)dealloc  // How in the world...
{
	RELEASE(portArray);
	RELEASE(netObjectArray);
	RELEASE(badDescs);
	NSFreeMapTable(descTable);
	
	netApplication = nil;
	[super dealloc];
}
- (NSDate *)timedOutEvent: (void *)data
                     type: (RunLoopEventType)type
                  forMode: (NSString *)mode
{
	return nil;
}
- (void)receivedEvent: (void *)data
                 type: (RunLoopEventType)type
                extra: (void *)extra
              forMode: (NSString *)mode
{
	id object;

	object = (id)NSMapGet(descTable, data);
	if (!object)
	{
		[[NSRunLoop currentRunLoop] removeEvent: data
		 type: type forMode: NSDefaultRunLoopMode all: YES];
		return;
	}
	
	NS_DURING
		switch(type)
		{
			default:
				break;
			case ET_RDESC:
				if ([object conformsTo: @protocol(NetObject)])
				{
					[object dataReceived: [[object transport] readData: 2048]];
				}
				else
				{
					[object newConnection];
				}
				break;
			case ET_WDESC:
				[[object transport] writeData: nil];
				if ([[object transport] isDoneWriting])
				{
					[[NSRunLoop currentRunLoop] removeEvent: data
					 type: ET_WDESC forMode: NSDefaultRunLoopMode all: YES];
				}
				break;
			case ET_EDESC:
				[self disconnectObject: self];
				break;
		}
	NS_HANDLER
		if (([[localException name] isEqualToString:NetException]) ||
		    ([[localException name] isEqualToString:FatalNetException]))
		{
			[self disconnectObject: object];
		}
		else
		{
			[localException raise];
		}
	NS_ENDHANDLER																
}
			
- connectObject: anObject
{
	void *desc = 0;
	
	if ([anObject conformsToProtocol: @protocol(NetPort)])
	{ 
		desc = (void *)[anObject desc];
		
		[portArray addObject: anObject];
	}
	else if ([anObject conformsToProtocol: @protocol(NetObject)])
	{
		desc = (void *)[[anObject transport] desc];
		
		[netObjectArray addObject: anObject];
	}
	else
	{		
		[NSException raise: NetException 
		  format: @"[NetApplication addObject:] %@ does not follow "
		          @"< NetPort > or < NetObject >", 
		    NSStringFromClass([anObject class])];
	}
	NSMapInsert(descTable, desc, anObject);
	
	[[NSRunLoop currentRunLoop] addEvent: desc type: ET_EDESC
	 watcher: self forMode: NSDefaultRunLoopMode];
		
	[[NSRunLoop currentRunLoop] addEvent: desc type: ET_RDESC
	 watcher: self forMode: NSDefaultRunLoopMode];
	
	return self;
}
- disconnectObject: anObject
{
	id whichOne = nil;
	
	void *desc = 0;
	
	if ([portArray containsObject: anObject])
	{
		whichOne = portArray;
		
		desc = (void *)[anObject desc];
	}
	else if ([netObjectArray containsObject: anObject])
	{
		whichOne = netObjectArray;
		
		desc = (void *)[[anObject transport] desc];
		
		[[NSRunLoop currentRunLoop] removeEvent: desc
		 type: ET_WDESC forMode: NSDefaultRunLoopMode all: YES];
	}	
	else
	{		
		return self;
	}
	[[NSRunLoop currentRunLoop] removeEvent: desc
	 type: ET_RDESC forMode: NSDefaultRunLoopMode all: YES];
		
	[[NSRunLoop currentRunLoop] removeEvent: desc
	 type: ET_EDESC forMode: NSDefaultRunLoopMode all: YES];
	
	NSMapRemove(descTable, desc);

	RETAIN(anObject);
	[whichOne removeObject: anObject];
	AUTORELEASE(anObject);
		
	[anObject connectionLost];
	
	return self;
}
- closeEverything
{
	CREATE_AUTORELEASE_POOL(apr);
	
	while ([netObjectArray count] != 0)
	{
		[self disconnectObject: [netObjectArray objectAtIndex: 0]];
	}
	
	while ([portArray count] != 0)
	{
		[self disconnectObject: [portArray objectAtIndex: 0]];
	}

	RELEASE(apr);
	return self;
}
- transportNeedsToWrite: aTransport
{
	if ([aTransport conformsTo: @protocol(NetTransport)])
	{
		[[NSRunLoop currentRunLoop] addEvent: 
		 (void *)[aTransport desc] type: ET_WDESC watcher: self 
		 forMode: NSDefaultRunLoopMode];
	}
	return self;
}
@end

