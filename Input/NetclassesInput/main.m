/***************************************************************************
                                main.m
                          -------------------
    begin                : Fri Feb 21 00:51:41 CST 2003
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

#include "main.h"

#include <Foundation/NSInvocation.h>
#include <Foundation/NSArray.h>

@interface NetclassesInput (PrivateNetclassesInput)
- removeConnection: aConnection;
@end

@implementation NetclassesInput (PrivateNetclassesInput)
- removeConnection: aConnection
{
	[connections removeObject: aConnection];
	
	return self;
}
@end

@implementation NetclassesInput
- init
{
	if (!(self = [super init])) return nil;

	connections = [[NSMutableArray alloc] init];

	return self;
}
- (void)dealloc
{
	RELEASE(connections);
	[super dealloc];
}
- initiateConnectionToHost: (NSHost *)aHost onPort: (int)aPort
   withTimeout: (int)seconds withNickname: (NSString *)nickname 
   withUserName: (NSString *)user withRealName: (NSString *)realName 
   withPassword: (NSString *)password withIdentification: (NSString *)ident
{
	id connection = [[NetclassesConnection alloc] initWithNickname:
	  nickname withUserName: user withRealName: realName
	  withPassword: password withIdentification: ident onPort: aPort
	  withControl: self];
	
	[[TCPSystem sharedInstance] connectNetObjectInBackground: connection
	  toHost: aHost onPort: aPort withTimeout: seconds];
	
	[connections addObject: connection];

	return self;
}
- (void)closeConnection: (id)connection
{
	if ([connections containsObject: connection])
	{
		[[NetApplication sharedInstance] disconnectObject: connection];
	}
}	
- (NSArray *)connections
{
	return [NSArray arrayWithArray: connections];
}
@end
		 
@implementation NetclassesConnection
- initWithNickname: (NSString *)aNick withUserName: (NSString *)user
   withRealName: (NSString *)real withPassword: (NSString *)aPass
   withIdentification: (NSString *)ident onPort: (int)aPort
   withControl: plugin;
{
	if (!(self = [super initWithNickname: aNick withUserName: user
	  withRealName: real withPassword: aPass])) return nil;

	identification = RETAIN(ident);

	port = aPort;

	control = plugin; // Avoiding circular reference
	
	return self;
}
- (void)dealloc
{
	RELEASE(identification);

	[super dealloc];
}
- (NSString *)identification
{
	return identification;
}
- (int)port
{
	return port;
}
- (NSHost *)host
{
	return [transport address];
}
- (void)connectionLost
{
	[control removeConnection: self];
	[super connectionLost];
}
- connectionEstablished: (id)aTransport
{
	NSLog(@"%@", self);
	id x = [super connectionEstablished: aTransport];
	[_TS_ newConnection: self sender: control];
	return x;
}
#define S2AS(_x) AUTORELEASE([[NSAttributedString alloc] initWithString: (_x)])
- registeredWithServer
{
	[_TS_ registeredWithServerOnConnection: self sender: control];
	return self;
}
- couldNotRegister: (NSString *)reason
{
	[_TS_ couldNotRegister: S2AS(reason) onConnection: self sender: control];
	return self;
}
- CTCPRequestReceived: (NSString *)aCTCP
   withArgument: (NSString *)argument from: (NSString *)aPerson;
{
	[_TS_ CTCPRequestReceived: S2AS(aCTCP) withArgument: S2AS(argument)
	  from: S2AS(aPerson) onConnection: self sender: control];
	return self;
}
- CTCPReplyReceived: (NSString *)aCTCP
   withArgument: (NSString *)argument from: (NSString *)aPerson
{
	[_TS_ CTCPReplyReceived: S2AS(aCTCP) withArgument: S2AS(argument)
	  from: S2AS(aPerson) onConnection: self sender: control];
	return self;
}
- errorReceived: (NSString *)anError
{
	[_TS_ errorReceived: S2AS(anError) onConnection: self sender: control];
	return self;
}
- wallopsReceived: (NSString *)message from: (NSString *)sender
{
	[_TS_ wallopsReceived: S2AS(message) from: S2AS(sender) onConnection: self
	  sender: control];
	return self;
}
- userKicked: (NSString *)aPerson outOf: (NSString *)aChannel
         for: (NSString *)reason from: (NSString *)kicker
{
	[_TS_ userKicked: S2AS(aPerson) outOf: S2AS(aChannel) for: S2AS(reason)
	  from: S2AS(kicker) onConnection: self sender: control];
	return self;
}
- invitedTo: (NSString *)aChannel from: (NSString *)inviter
{
	[_TS_ invitedTo: S2AS(aChannel) from: S2AS(inviter) onConnection: self
	  sender: control];
	return self;
}
- modeChanged: (NSString *)mode on: (NSString *)anObject
   withParams: (NSArray *)paramList from: (NSString *)aPerson
{
	NSMutableArray *y;
	NSEnumerator *iter;
	id object;
	
	y = AUTORELEASE([[NSMutableArray alloc] init]);
	
	iter = [paramList objectEnumerator];

	while ((object = [iter nextObject]))
	{
		[y addObject: S2AS(object)];
	}

	[_TS_ modeChanged: S2AS(mode) on: S2AS(anObject) withParams: 
	  [NSArray arrayWithArray: y] from: S2AS(aPerson) onConnection: self
	  sender: control];
	return self;
}
- numericCommandReceived: (NSString *)command withParams: (NSArray *)paramList
                      from: (NSString *)sender
{
	NSMutableArray *y;
	NSEnumerator *iter;
	id object;
	
	y = AUTORELEASE([[NSMutableArray alloc] init]);
	
	iter = [paramList objectEnumerator];

	while ((object = [iter nextObject]))
	{
		[y addObject: S2AS(object)];
	}

	[_TS_ numericCommandReceived: S2AS(command) withParams:
	  [NSArray arrayWithArray: y] from: S2AS(sender) onConnection: self
	  sender: control];

	return self;
}
- nickChangedTo: (NSString *)newName from: (NSString *)aPerson
{
	[_TS_ nickChangedTo: S2AS(newName) from: S2AS(aPerson) onConnection: self
	  sender: control];

	return self;
}
- channelJoined: (NSString *)channel from: (NSString *)joiner
{
	[_TS_ channelJoined: S2AS(channel) from: S2AS(joiner) onConnection: self
	  sender: control];
	
	return self;
}
- channelParted: (NSString *)channel withMessage: (NSString *)aMessage
             from: (NSString *)parter
{
	[_TS_ channelParted: S2AS(channel) withMessage: S2AS(aMessage)
	  from: S2AS(parter) onConnection: self sender: control];

	return self;
}
- quitIRCWithMessage: (NSString *)aMessage from: (NSString *)quitter
{
	[_TS_ quitIRCWithMessage: S2AS(aMessage) from: S2AS(quitter) 
	  onConnection: self sender: control];
	
	return self;
}
- topicChangedTo: (NSString *)aTopic in: (NSString *)channel
              from: (NSString *)aPerson
{
	[_TS_ topicChangedTo: S2AS(aTopic) in: S2AS(channel)
	  from: S2AS(aPerson) onConnection: self sender: control];

	return self;
}
- messageReceived: (NSString *)aMessage to: (NSString *)to
               from: (NSString *)sender
{
	[_TS_ messageReceived: S2AS(aMessage) to: S2AS(to) from: S2AS(sender)
	  onConnection: self sender: control];
	
	return self;
}
- noticeReceived: (NSString *)aMessage to: (NSString *)to
              from: (NSString *)sender
{
	[_TS_ noticeReceived: S2AS(aMessage) to: S2AS(to) from: S2AS(sender)
	  onConnection: self sender: control];
	
	return self;
}
- actionReceived: (NSString *)anAction to: (NSString *)to
              from: (NSString *)sender
{
	[_TS_ actionReceived: S2AS(anAction) to: S2AS(to) from: S2AS(sender)
	  onConnection: self sender: control];
	
	return self;
}
- pingReceivedWithArgument: (NSString *)arg from: (NSString *)sender
{
	[_TS_ pingReceivedWithArgument: S2AS(arg) from: S2AS(sender) 
	  onConnection: self sender: control];
	
	return self;
}
- pongReceivedWithArgument: (NSString *)arg from: (NSString *)sender
{
	[_TS_ pongReceivedWithArgument: S2AS(arg) from: S2AS(sender)
	  onConnection: self sender: control];
	
	return self;
}
- newNickNeededWhileRegistering
{
	[_TS_ newNickNeededWhileRegisteringOnConnection: self sender: control];

	return self;
}
- writeRawString: (NSString *)aString
{
	[self writeString: @"%@", aString];
	
	return self;
}
- (BOOL)respondsToSelector: (SEL)aSel
{
	if ([_TSDummy_ respondsToSelector: aSel])
	{
		return YES;
	}
	return [super respondsToSelector: aSel];
}
- methodSignatureForSelector: (SEL)aSel
{
	if ([_TSDummy_ respondsToSelector: aSel])
	{
		return [_TSDummy_ methodSignatureForSelector: aSel];
	}

	return [super methodSignatureForSelector: aSel];
}	
- (void)forwardInvocation: (NSInvocation *)invocation
{
	NSInvocation *invoc;
	SEL sel;
	id selS;
	char buffer[64];
	int num;
	int x;
	
	sel = [invocation selector];
	selS = NSStringFromSelector(sel);
	
	NSLog(@"%@", selS);
	
	if ([_TSDummy_ respondsTo: sel]
	    && [selS hasSuffix: @"nConnection:sender:"])
	{
		selS = [selS substringToIndex: [selS length] - 
		  [@"onConnection:sender:" length]];
		
		sel = NSSelectorFromString(selS);

		if (![self respondsToSelector: sel])
		{
			[super forwardInvocation: invocation];
		}

		num = [[selS componentsSeparatedByString: @":"] count] - 1;

		invoc = [NSInvocation invocationWithMethodSignature: 
		  [self methodSignatureForSelector: sel]];
		
		[invoc setSelector: sel];
		
		for (x = 2; x < (num + 2); x++)
		{
			[invocation getArgument: buffer atIndex: x];
			[invoc setArgument: buffer atIndex: x];
		}

		[invoc invokeWithTarget: self];
		
		return;
	}
	
	[super forwardInvocation: invocation];
}
@end
