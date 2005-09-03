/***************************************************************************
                                main.m
                          -------------------
    begin                : Thu Jun 16 22:05:36 CDT 2005
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

#import "main.h"
#import "misc.h"
#import "IRCSwarmBot.h"

#import <netclasses/NetTCP.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSString.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSProcessInfo.h>

#include <time.h>
#include <stdlib.h>

NSMutableDictionary *sharedBots = nil;
NSMutableDictionary *connectingBots = nil;

static int max_clients = 200;

static float low_time = 0.0;
static float wait_connecting = 0.0;
static float wait_cant_connect = 300.0;
static float high_time = 0.0;

@implementation ControlSwarm
+ (void)initialize
{
	if (sharedBots) return;

	sharedBots = [NSMutableDictionary new];
	connectingBots = [NSMutableDictionary new];
}
- initWithChannel: (NSString *)aChan withPlay: (NSString *)aPlay
  withHost: (NSHost *)aHost
{
	NSString *aString;
	NSAutoreleasePool *aPool;
	unsigned done = 0;
	unsigned length = 0;

	if (!(self = [super init])) return self;

	aPool = [NSAutoreleasePool new];
	aString = [NSString stringWithContentsOfFile: aPlay];
	play = [NSMutableArray new];

	length = [aString length];

	while (done < length) 
	{
		NSRange aRange;
		unsigned start;
		unsigned end;
		unsigned lineend;
		aRange.location = done;
		aRange.length = 0;

		[aString getLineStart: &start end: &lineend
		 contentsEnd: &end forRange: aRange];
		[play addObject: [aString substringWithRange: 
		  NSMakeRange(start, end - start)]];
		done = lineend + 1;
	}
	RELEASE(aPool);
	channel = RETAIN(aChan);
	host = RETAIN(aHost);
	
	[NSTimer scheduledTimerWithTimeInterval:5.0 target: self 
	   selector: @selector(timerFired:) userInfo: nil repeats: NO];
	return self;
}
- (void)timerFired: (NSTimer *)aTimer
{
	id this_string;
	id separate;
	id ret = self;
	float lenwait;
	SEL aSel;

	lenwait = low_time + ((high_time - low_time)*rand()/(RAND_MAX + 1.0));

	this_string = [play objectAtIndex: curIndex];
	separate = [this_string separateIntoNumberOfArguments: 2];
	if ([separate count] < 2)
	{
		NSLog(@"Couldn't parse %@!!!", this_string);
		curIndex = (curIndex == [play count] - 1) ? 0 : curIndex + 1;
		[NSTimer scheduledTimerWithTimeInterval: lenwait
		   target:self selector: @selector(timerFired:) userInfo: nil 
		   repeats: NO];
	}
		
	aSel = NSSelectorFromString([NSString stringWithFormat: 
	  @"command%@:", [separate objectAtIndex: 0]]);

	if (aSel != NULL && [self respondsToSelector: aSel])
	{
		ret = 
		  [self performSelector: aSel withObject: [separate objectAtIndex: 1]];
	}
	
	if (ret) 
	{
		repeat = 0;
		curIndex = (curIndex == [play count] - 1) ? 0 : curIndex + 1;
	}
	else
	{
		repeat++;
		lenwait = wait_connecting;
	}

	if (repeat > 5)
	{
		lenwait = wait_cant_connect;
		curIndex = (curIndex == [play count] - 1) ? 0 : curIndex + 1;
	}

	[NSTimer scheduledTimerWithTimeInterval: lenwait
	   target:self selector: @selector(timerFired:) userInfo: nil 
	   repeats: NO];
}
- getBotForName: (NSString *)aNick
{
	id bot;
	id normalName;
	int num;

	if ([aNick length] > 8)
		aNick = [aNick substringToIndex: 8];

	normalName = aNick;

	aNick = [aNick lowercaseString];

	bot = [sharedBots objectForKey: aNick];
	if (bot) return bot;

	bot = [connectingBots objectForKey: aNick];
	if ([bot transport]) return nil;

	num = [[sharedBots allKeys] count];
	if (num > max_clients)
	{
		int index = (int)(num * (rand() / (RAND_MAX + 1.0)));
		id bot;

		bot = [sharedBots objectForKey: [[sharedBots allKeys] 
		  objectAtIndex: index]];
		NSLog(@"Disconnecting %@ (index %d)", [bot nick], index);
		[[NetApplication sharedInstance] disconnectObject: bot];
	}
	bot = [[IRCSwarmBot alloc] 
	  initWithNickname: normalName 
	  withUserName: nil withRealName: @"IRCSwarm Bot"
	  withPassword: nil
	  withControl: self];
	  
	NSLog(@"Connecting up a bot for %@", aNick);
	if ([[TCPSystem sharedInstance] connectNetObject: bot 
	  toHost: host 
	  onPort: 6667 withTimeout: 30])
	{
		[connectingBots setObject: bot forKey: aNick];
	}

	return nil;
}
- commandACTION: (NSString *)command
{
	id separate;
	id bot;
	id nick;
	id msg;
	separate = [command separateIntoNumberOfArguments: 2];
	if ([separate count] != 2)
	{
		NSLog(@"Bad action %@", command);
		return self;
	}

	nick = [separate objectAtIndex: 0];
	msg = [separate objectAtIndex: 1];
	bot = [self getBotForName: nick];
	if (bot)
	{
		[bot sendAction: msg to: channel];
		return self;
	}

	return nil;
}
- commandJOIN: (NSString *)command
{
	id separate;
	id bot;
	id nick;
	separate = [command separateIntoNumberOfArguments: 2];
	if ([separate count] == 0)
	{
		NSLog(@"Bad join %@", command);
		return self;
	}

	nick = [separate objectAtIndex: 0];
	bot = [self getBotForName: nick];

	return self;
}
- commandQUIT: (NSString *)command
{
	id separate;
	id bot;
	id nick;
	separate = [command separateIntoNumberOfArguments: 2];
	if ([separate count] == 0)
	{
		NSLog(@"Bad quit/part %@", command);
		return self;
	}

	nick = [separate objectAtIndex: 0];
	bot = [self getBotForName: nick];
	if (!bot)
	{
		return nil;
	}

	[bot quitWithMessage: nil];

	return self;
}
- commandPART: (NSString *)command
{
	return [self commandQUIT: command];
}
- commandMESSAGE: (NSString *)command
{
	id separate;
	id bot;
	id nick;
	id msg;
	separate = [command separateIntoNumberOfArguments: 2];
	if ([separate count] != 2)
	{
		NSLog(@"Bad message %@", command);
		return self;
	}

	nick = [separate objectAtIndex: 0];
	msg = [separate objectAtIndex: 1];
	bot = [self getBotForName: nick];
	if (bot)
	{
		[bot sendMessage: msg to: channel];
		return self;
	}

	return nil;
}
- (void)botDied: (IRCSwarmBot *)aBot
{
	id nick = [[aBot nick] lowercaseString];

	[sharedBots removeObjectForKey: nick];
	[sharedBots removeObjectForKey: nick];
}
- (void)botRegistered: (IRCSwarmBot *)aBot
{
	id nick = [[aBot nick] lowercaseString];

	if ([connectingBots objectForKey: nick])
	{
		[sharedBots setObject: aBot forKey: nick];
		[connectingBots removeObjectForKey: nick];
	}

	[aBot joinChannel: channel withPassword: nil];
}
@end

int main(int argc, char **argv, char **env)
{
	int index;
	NSArray *args;
	NSHost *aHost;
	CREATE_AUTORELEASE_POOL(arp);

	srand(time(0) ^ gethostid() % getpid());
		
	args = [[NSProcessInfo processInfo] arguments];
	if (([args count] < 7) || (([args count] % 2) != 1)) 
	{
		NSLog(@"Usage: %@ <lowtime> <hightime> <waitconnect> <server> <channel> <play> [<channel2> <play2>] ...",
		 [args objectAtIndex: 0]);
		exit(0);
	}
	aHost = [NSHost hostWithName: [args objectAtIndex: 4]];
	if (!aHost)
	{
		NSLog(@"Couldn't find host %@", [args objectAtIndex: 4]);
		exit(2);
	}
	low_time = [[args objectAtIndex: 1] floatValue];
	high_time = [[args objectAtIndex: 2] floatValue];
	wait_connecting = [[args objectAtIndex: 3] floatValue];
	
	if ((high_time - low_time) <= 0.00001)
	{
		NSLog(@"Invalid time constraints");
		exit(1);
	}

	for (index = 5; index < [args count]; index += 2)
	{
		[[ControlSwarm alloc] initWithChannel: [args objectAtIndex: index]
		  withPlay: [args objectAtIndex: index + 1] withHost: aHost];
	}
	
	[[NSRunLoop currentRunLoop] run];
		
	RELEASE(arp);
	return 0;
}

