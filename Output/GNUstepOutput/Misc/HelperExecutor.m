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

#import <Foundation/NSBundle.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSTask.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSPathUtilities.h>

@interface HelperExecutor (PrivateMethods)
- (void)taskEnded: (NSNotification *)aNotification;
@end

@implementation HelperExecutor
- initWithHelperName: (NSString *)aName identifier: (NSString *)aIdentifier
{
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

	RETAIN(helper);
	executingTasks = [NSMutableArray new];
	notificationName = RETAIN(aIdentifier);

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(taskEnded:)
	  name: NSTaskDidTerminateNotification 
	  object: nil];

	return self;
}
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	RELEASE(executingTasks);
	RELEASE(notificationName);
	RELEASE(helper);

	[super dealloc];
}
- (void)runWithArguments: (NSArray *)aArgs
{
	NSMutableArray *args;
	NSTask *aTask;

	if (!aArgs)
		aArgs = AUTORELEASE([NSArray new]);

	args = [NSMutableArray new];
	[args addObject: notificationName];
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
}
@end

@implementation HelperExecutor (PrivateMethods)
- (void)taskEnded: (NSNotification *)aNotification
{
	id task = [aNotification object];

	if (![executingTasks containsObject: task])
		return;

	[executingTasks removeObject: task];
}
@end
