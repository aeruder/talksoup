/***************************************************************************
                               IRCSwarmBot.m
                          -------------------
    begin                : Thu Jun 16 22:01:45 CDT 2005
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

#import "IRCSwarmBot.h"
#import "main.h"

#import <Foundation/NSTimer.h>
#import <Foundation/NSString.h>
#import <Foundation/NSData.h>
#import <Foundation/NSValue.h>

#include <string.h>
#include <stdio.h>
#include <unistd.h>

static inline NSData *chomp_line(NSMutableData *data)
{
	char *memory = [data mutableBytes];
	char *memoryEnd = memory + [data length];
	char *lineEndWithControls;
	char *lineEnd;
	int tempLength;
	
	id lineData;
	
	lineEndWithControls = lineEnd = 
	  memchr(memory, '\n', memoryEnd - memory);
	
	if (!lineEnd)
	{
		return nil;
	}
	
	while (((*lineEnd == '\n') || (*lineEnd == '\r'))
	       && (lineEnd >= memory))
	{
		lineEnd--;
	}

	lineData = [NSData dataWithBytes: memory length: lineEnd - memory + 1];
	
	tempLength = memoryEnd - lineEndWithControls - 1;
	
	memmove(memory, lineEndWithControls + 1, 
	        tempLength);
	
	[data setLength: tempLength];
	
	return lineData;
}

@implementation IRCSwarmBot
- initWithNickname: (NSString *)aNickname withUserName: (NSString *)aUser
  withRealName: (NSString *)aReal withPassword: (NSString *)aPass
  withControl: (ControlSwarm *)aControl
{
	if (!(self = [super initWithNickname: aNickname
	 withUserName: aUser withRealName: aReal withPassword: aPass])) 
		return nil;
	
	control = RETAIN(aControl);

	return self;
}
- connectionEstablished: aTransport
{
	return [super connectionEstablished: aTransport];
}
- (void)connectionLost
{
	[control botDied: self];
	[super connectionLost];
}
- registeredWithServer
{
	[control botRegistered: self];
	return self;
}
- CTCPRequestReceived: (NSString *)aCTCP withArgument: (NSString *)argument
    to: (NSString *)aReceiver from: (NSString *)aPerson
{
	if ([aCTCP compare: @"PING"] == NSOrderedSame)
	{
		[self sendCTCPReply: @"PING" withArgument: argument
		  to: ExtractIRCNick(aPerson)];
	}
	if ([aCTCP compare: @"VERSION"] == NSOrderedSame)
	{
		NSString *version, *reply;

		version = [NetApplication netclassesVersion];
		reply = [NSString stringWithFormat: @"netclasses:%@:GNUstep", version];
		
		[self sendCTCPReply: @"VERSION" withArgument: reply 
		  to: ExtractIRCNick(aPerson)];
	}

	return self;
}		
- pingReceivedWithArgument: (NSString *)anArgument from: (NSString *)aSender
{
	[self sendPongWithArgument: anArgument];

	return self;
}
- messageReceived: (NSString *)aMessage to: (NSString *)to
               from: (NSString *)whom
{
	if ([aMessage caseInsensitiveCompare: @"get out of here"] == NSOrderedSame)
	{
		exit(2);
		return self;
	}
	
	return self;
}
@end
