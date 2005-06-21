/***************************************************************************
                             HelperExecutor.m
                          -------------------
    begin                : Thu Jun  9 19:12:10 CDT 2005
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

#import "Misc/HelperExecutor.h"
#import "GNUstepOutput.h"

#import <Foundation/NSPort.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSConnection.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSTask.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSPortNameServer.h>

@interface HelperExecutor (PrivateMethods)
- (void)taskEnded: (NSNotification *)aNotification;
@end

@implementation HelperExecutor
- initWithHelperName: (NSString *)aName identifier: (NSString *)aIdentifier
{
	NSMessagePort *aPort;
	NSBundle *aBundle;
	NSFileManager *aManager;

	if (!(self = [super init])) return nil;

	aBundle = [NSBundle bundleForClass: [_GS_ class]];
	helper = [[aBundle resourcePath] stringByAppendingPathComponent: @"Tools"];
	helper = [helper stringByAppendingPathComponent: aName];

	aManager = [NSFileManager defaultManager];
	if (!helper || ![aManager isExecutableFileAtPath: helper])
	{
		NSLog(@"%@ is not executable", helper);
		[super dealloc];
		return nil;
	}

	aPort = AUTORELEASE([NSMessagePort new]);

	distConnection = [NSConnection connectionWithReceivePort: aPort sendPort: nil];
	if (!distConnection || ![distConnection registerName: aIdentifier
	  withNameServer: 
	  (NSMessagePortNameServer *)[NSMessagePortNameServer sharedInstance]]
	)
	{
		NSLog(@"Couldn't register NSConnection in HelperExecutor :(");
		[super dealloc];
		return nil;
	}

	RETAIN(distConnection);
	RETAIN(helper);
	executingTasks = [NSMutableArray new];
	distConnectionName = RETAIN(aIdentifier);

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(taskEnded:)
	  name: NSTaskDidTerminateNotification 
	  object: nil];

	return self;
}
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[distConnection registerName: nil];
	RELEASE(executingTasks);
	RELEASE(distConnection);
	RELEASE(distConnectionName);
	RELEASE(helper);

	[super dealloc];
}
- (void)runWithArguments: (NSArray *)aArgs object: (id)aObject
{
	NSMutableArray *args;
	NSTask *aTask;

	if (!aArgs)
		aArgs = AUTORELEASE([NSArray new]);

	[distConnection setRootObject: aObject];

	args = [NSMutableArray new];
	[args addObject: distConnectionName];
	[args addObjectsFromArray: aArgs];

	aTask = AUTORELEASE([NSTask new]);
	[aTask setLaunchPath: helper];
	[aTask setArguments: args];
	[executingTasks addObject: aTask];
	[aTask launch];
}
- (void)cleanup
{
	NSEnumerator *iter;
	id object;

	iter = [[NSArray arrayWithArray: executingTasks] objectEnumerator];
	while ((object = [iter nextObject])) 
	{
		[object terminate];
	}

	[distConnection setRootObject: [NSNull null]];
}
@end

@implementation HelperExecutor (PrivateMethods)
- (void)taskEnded: (NSNotification *)aNotification
{
	id task = [aNotification object];

	if (![executingTasks containsObject: task])
		return;

	if ([executingTasks objectAtIndex: [executingTasks count] - 1] 
	    == task)
	{
		[distConnection setRootObject: [NSNull null]];
	}

	[executingTasks removeObject: task];
}
@end
