/***************************************************************************
                             exec_helper.m 
                          -------------------
    begin                : Wed Jun  8 20:55:48 CDT 2005
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

/* This is a simple tool that handles the problem of execing a separate task
 * without having to worry about the exec'd task hanging, using lots of 
 * cpu, running forever, etc...
 */

#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSTask.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSRange.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDistributedNotificationCenter.h>

#include <signal.h>

static NSString *my_dest = nil;
static NSString *my_regname = nil;
static NSString *my_notname = nil;

static NSString *getlp(NSString *command)
{
	return @"/bin/sh";
}

static NSArray *getargs(NSString *command)
{
	return [NSArray arrayWithObjects: @"-c", command, nil];
}

static void handle_lines(NSMutableString *str, int force_all)
{
	NSMutableArray *lines;
	NSRange aRange;
	NSEnumerator *iter;
	NSString *output;

	lines = [NSMutableArray arrayWithArray: 
	  [str componentsSeparatedByString: @"\n"]];
	
	if (!force_all)
	{
		aRange.location = 0;
		aRange.length = [str length] - [[lines objectAtIndex: [lines count] - 1] length];
		[str deleteCharactersInRange: aRange];
		[lines removeObjectAtIndex: [lines count] - 1];
	}
	else
	{
		[str setString: @""];
	}

	iter = [lines objectEnumerator];
	while ((output = [iter nextObject]))
	{
		if ([output hasSuffix: @"\r"])
			output = [output substringToIndex: [output length] - 1];
		if ([output hasPrefix: @"\r"])
			output = [output substringFromIndex: 1];

		if ([output length] == 0) continue;

		[(NSDistributedNotificationCenter *)[NSDistributedNotificationCenter defaultCenter]
		  postNotificationName: my_notname
		  object: my_regname
		  userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
			output, @"Output",
			my_dest, @"Destination",
			nil]
		  deliverImmediately: YES];
	}
}

static void run_it(NSString *command)
{
	NSTask *task;
	NSPipe *pipein;
	NSPipe *pipeout;
	NSFileHandle *fdin;
	NSFileHandle *fdout;
	NSData *newData;
	NSString *str;
	NSMutableString *sofar;
	
	task = AUTORELEASE([NSTask new]);
	pipein = [NSPipe pipe];
	pipeout = [NSPipe pipe];
		
	[task setStandardInput: pipein];
	[task setStandardOutput: pipeout];
	[task setStandardError: pipeout];
		
	fdin = [pipein fileHandleForWriting];
	fdout = [pipeout fileHandleForReading];
				
	[task setLaunchPath: getlp(command)];
	[task setArguments: getargs(command)];
	[task launch];
	[fdin closeFile];

	sofar = [NSMutableString stringWithString: @""];
	
	while (1)
	{
		newData = [fdout availableData];
		if ([newData length] == 0) 
		   break;	
		str = AUTORELEASE([[NSMutableString alloc] initWithData: newData 
		  encoding: NSUTF8StringEncoding]);
		if (!str)
		   break;

		[sofar appendString: str];
		handle_lines(sofar, 0);
	}
	handle_lines(sofar, 1);

	[task terminate];
}

int main(int argc, char **argv, char **env)
{
	CREATE_AUTORELEASE_POOL(apr);
	NSDictionary *dict;
	NSString *command;

	signal(SIGPIPE, SIG_IGN);
	if (argc < 3) 
		return 1;

	my_regname = [NSString stringWithCString: argv[1]];
	my_notname = [NSString stringWithCString: argv[2]];
	command = [NSString stringWithCString: argv[3]];
	if (argc >= 4)
		my_dest = [NSString stringWithCString: argv[4]];

	run_it(command);

	RELEASE(dict);
	RELEASE(apr);
	return 0;
}
