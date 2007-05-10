/***************************************************************************
                                TalkSoup.m
                          -------------------
    begin                : Fri Jan 17 11:04:36 CST 2003
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

#include "TalkSoup.h"

#include <Foundation/NSString.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>

id _TS_;
id _TSDummy_;

@interface NSException (Blah)
@end

@implementation NSException (Blah)
- (void)raise
{
	//abort();
}
@end

@implementation TalkSoup
+ (TalkSoup *)sharedInstance
{
	if (!_TS_)
	{
		AUTORELEASE([TalkSoup new]);
		if (!_TS_)
		{
			NSLog(@"Couldn't initialize the TalkSoup object");
		}
		_TSDummy_ = [TalkSoupDummyProtocolClass new];
	}

	return _TS_;
}
- init
{
	if (_TS_) return nil;
	
	if (!(self = [super init])) return nil;

	outFilters = [NSMutableArray new];
	inFilters = [NSMutableArray new];

	_TS_ = RETAIN(self);
	
	return self;
}
- (NSDictionary *)commandList
{
	return nil;
}
- addCommand: (NSString *)aCommand withSelector: (SEL)aSel
{
	return self;
}
- removeCommand: (NSString *)aCommand
{
	return self;
}
- (BOOL)respondsToSelector: (SEL)aSel
{
	if ([_TSDummy_ respondsToSelector: aSel]) return YES;

	return [super respondsToSelector: aSel];
}
- (NSMethodSignature *)methodSignatureForSelector: (SEL)aSel
{
	id object;
	
	if ((object = [_TSDummy_ methodSignatureForSelector: aSel]))
		return object;
	
	return [super methodSignatureForSelector: aSel];
}
- (void)forwardInvocation: (NSInvocation *)aInvocation
{
	NSMutableArray *in;
	NSMutableArray *out;
	SEL sel;
	id selString;
	int args;
	int index = NSNotFound;
	id sender;
	id next;

	sel = [aInvocation selector];
	selString = NSStringFromSelector(sel);
	args = [[selString componentsSeparatedByString: @":"] count] - 1;
	
	if (![selString hasSuffix: @"sender:"])
	{
		[super forwardInvocation: aInvocation];
		return;
	}

	[aInvocation retainArguments];

	in = [NSMutableArray arrayWithObjects: input, nil];
	out = [NSMutableArray arrayWithObjects: output, nil];

	[in addObjectsFromArray: inFilters];
	[out addObjectsFromArray: outFilters];

	[aInvocation getArgument: &sender atIndex: args + 1];

	if ((index = [in indexOfObjectIdenticalTo: sender]) != NSNotFound)
	{
		NSLog(@"In!");
		if (index == ([in count] - 1))
		{
			next = output;
		}
		else
		{
			next = [in objectAtIndex: index + 1];
		}

		if ([next respondsToSelector: sel])
		{
			[aInvocation invokeWithTarget: next];
		}
		else
		{
			if (next != output)
			{
				[aInvocation setArgument: &next atIndex: args - 1];
				[self forwardInvocation: aInvocation];
			}
		}
	}
	else if ((index = [out indexOfObjectIdenticalTo: sender]) != NSNotFound)
	{
		id connection;
		if (![selString hasSuffix: @"Connection:sender:"])
		{
			[super forwardInvocation: aInvocation];
			return;
		}
		if (index == ([out count] - 1))
		{
			[aInvocation getArgument: &connection atIndex: args - 2];
			next = connection;
		}
		else
		{
			next = [in objectAtIndex: index + 1];
		}

		if ([next respondsToSelector: sel])
		{
			[aInvocation invokeWithTarget: next];
		}
		else
		{
			if (next != connection)
			{
				[aInvocation setArgument: &next atIndex: args - 1];
				[self forwardInvocation: aInvocation];
			}
		}
	}
}
- (id)input
{
	return input;
}
- (NSMutableArray *)inFilters
{
	return inFilters;
}
- (NSMutableArray *)outFilters
{
	return outFilters;
}
- (id)output
{
	return output;
}
- setInput: (id)aInput
{
	RELEASE(input);
	input = RETAIN(aInput);

	return self;
}
- setOutput: (id)aOutput
{
	RELEASE(output);
	output = RETAIN(aOutput);
	
	return self;
}
@end

@implementation TalkSoupDummyProtocolClass
- changeNick: (NSString *)aNick onConnection: aConnection sender: aPlugin 
   { return nil; }

- quitWithMessage: (NSString *)aMessage onConnection: aConnection 
   sender: aPlugin { return nil; }

- partChannel: (NSString *)channel withMessage: (NSString *)aMessage 
   onConnection: aConnection sender: aPlugin { return nil; }

- joinChannel: (NSString *)channel withPassword: (NSString *)aPassword 
   onConnection: aConnection sender: aPlugin { return nil; }

- sendCTCPReply: (NSString *)aCTCP withArgument: (NSString *)args
   to: (NSString *)aPerson onConnection: aConnection sender: aPlugin 
   { return nil; }

- sendCTCPRequest: (NSString *)aCTCP withArgument: (NSString *)args
   to: (NSString *)aPerson onConnection: aConnection sender: aPlugin 
   { return nil; }

- sendMessage: (NSString *)message to: (NSString *)receiver 
   onConnection: aConnection sender: aPlugin { return nil; }

- sendNotice: (NSString *)message to: (NSString *)receiver 
   onConnection: aConnection sender: aPlugin { return nil; }

- sendAction: (NSString *)anAction to: (NSString *)receiver 
   onConnection: aConnection sender: aPlugin { return nil; }

- becomeOperatorWithName: (NSString *)aName withPassword: (NSString *)pass 
   onConnection: aConnection sender: aPlugin { return nil; }

- requestNamesOnChannel: (NSString *)aChannel fromServer: (NSString *)aServer 
   onConnection: aConnection sender: aPlugin { return nil; }

- requestMOTDOnServer: (NSString *)aServer onConnection: aConnection 
   sender: aPlugin { return nil; }

- requestSizeInformationFromServer: (NSString *)aServer
   andForwardTo: (NSString *)anotherServer onConnection: aConnection 
   sender: aPlugin { return nil; }

- requestVersionOfServer: (NSString *)aServer onConnection: aConnection 
   sender: aPlugin { return nil; }

- requestServerStats: (NSString *)aServer for: (NSString *)query 
   onConnection: aConnection sender: aPlugin { return nil; }

- requestServerLink: (NSString *)aLink from: (NSString *)aServer 
   onConnection: aConnection sender: aPlugin { return nil; }

- requestTimeOnServer: (NSString *)aServer onConnection: aConnection 
   sender: aPlugin { return nil; }

- requestServerToConnect: (NSString *)aServer to: (NSString *)connectServer
   onPort: (NSString *)aPort onConnection: aConnection sender: aPlugin 
   { return nil; }

- requestTraceOnServer: (NSString *)aServer onConnection: aConnection 
   sender: aPlugin { return nil; }

- requestAdministratorOnServer: (NSString *)aServer onConnection: aConnection 
   sender: aPlugin { return nil; }

- requestInfoOnServer: (NSString *)aServer onConnection: aConnection
   sender: aPlugin { return nil; }

- requestServiceListWithMask: (NSString *)aMask ofType: (NSString *)type 
   onConnection: aConnection sender: aPlugin { return nil; }

- requestServerRehashOnConnection: aConnection sender: aPlugin { return nil; }

- requestServerShutdownOnConnection: aConnection sender: aPlugin { return nil; }

- requestServerRestartOnConnection: aConnection sender: aPlugin { return nil; }

- requestUserInfoOnServer: (NSString *)aServer onConnection: aConnection 
   sender: aPlugin { return nil; }

- areUsersOn: (NSString *)userList onConnection: aConnection sender: aPlugin 
   { return nil; }

- sendWallops: (NSString *)message onConnection: aConnection sender: aPlugin 
   { return nil; }

- queryService: (NSString *)aService withMessage: (NSString *)aMessage 
   onConnection: aConnection sender: aPlugin { return nil; }

- listWho: (NSString *)aMask onlyOperators: (BOOL)operators 
   onConnection: aConnection sender: aPlugin { return nil; }

- whois: (NSString *)aPerson onServer: (NSString *)aServer 
   onConnection: aConnection sender: aPlugin { return nil; }

- whowas: (NSString *)aPerson onServer: (NSString *)aServer
   withNumberEntries: (NSString *)aNumber onConnection: aConnection 
   sender: aPlugin { return nil; }

- kill: (NSString *)aPerson withComment: (NSString *)aComment 
   onConnection: aConnection sender: aPlugin { return nil; }

- setTopicForChannel: (NSString *)aChannel to: (NSString *)aTopic 
   onConnection: aConnection sender: aPlugin { return nil; }

- setMode: (NSString *)aMode on: (NSString *)anObject 
   withParams: (NSArray *)list onConnection: aConnection sender: aPlugin 
   { return nil; }
					 
- listChannel: (NSString *)aChannel onServer: (NSString *)aServer 
   onConnection: aConnection sender: aPlugin { return nil; }

- invite: (NSString *)aPerson to: (NSString *)aChannel 
   onConnection: aConnection sender: aPlugin { return nil; }

- kick: (NSString *)aPerson offOf: (NSString *)aChannel for: (NSString *)reason 
   onConnection: aConnection sender: aPlugin { return nil; }

- setAwayWithMessage: (NSString *)message onConnection: aConnection 
   sender: aPlugin { return nil; }

- sendPingWithArgument: (NSString *)aString onConnection: aConnection 
   sender: aPlugin { return nil; }

- sendPongWithArgument: (NSString *)aString onConnection: aConnection 
   sender: aPlugin { return nil; }

- (NSString *)identification { return nil; }

- newConnection: (id)connection sender: aPlugin { return nil; }

- registeredWithServerOnConnection: (id)connection sender: aPlugin 
   { return nil; }

- couldNotRegister: (NSAttributedString *)reason onConnection: (id)connection 
   sender: aPlugin { return nil; }

- CTCPRequestReceived: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)argument 
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   sender: aPlugin { return nil; }

- CTCPReplyReceived: (NSAttributedString *)aCTCP
   withArgument: (NSAttributedString *)argument 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection sender: aPlugin { return nil; }

- errorReceived: (NSAttributedString *)anError onConnection: (id)connection 
   sender: aPlugin { return nil; }

- wallopsReceived: (NSAttributedString *)message 
   from: (NSAttributedString *)sender 
   onConnection: (id)connection sender: aPlugin { return nil; }

- userKicked: (NSAttributedString *)aPerson 
   outOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason from: (NSAttributedString *)kicker 
   onConnection: (id)connection sender: aPlugin { return nil; }
		 
- invitedTo: (NSAttributedString *)aChannel from: (NSAttributedString *)inviter 
   onConnection: (id)connection sender: aPlugin { return nil; }

- modeChanged: (NSAttributedString *)mode on: (NSAttributedString *)anObject 
   withParams: (NSArray *)paramList from: (NSAttributedString *)aPerson 
   onConnection: (id)connection sender: aPlugin { return nil; }
   
- numericCommandReceived: (NSAttributedString *)command 
   withParams: (NSArray *)paramList from: (NSAttributedString *)sender 
   onConnection: (id)connection sender: aPlugin { return nil; }

- nickChangedTo: (NSAttributedString *)newName 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection sender: aPlugin { return nil; }

- channelJoined: (NSAttributedString *)channel 
   from: (NSAttributedString *)joiner 
   onConnection: (id)connection sender: aPlugin { return nil; }

- channelParted: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage
   from: (NSAttributedString *)parter onConnection: (id)connection 
   sender: aPlugin { return nil; }

- quitIRCWithMessage: (NSAttributedString *)aMessage 
   from: (NSAttributedString *)quitter onConnection: (id)connection 
   sender: aPlugin { return nil; }

- topicChangedTo: (NSAttributedString *)aTopic in: (NSAttributedString *)channel
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   sender: aPlugin { return nil; }

- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin { return nil; }

- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin { return nil; }

- actionReceived: (NSAttributedString *)anAction to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin { return nil; }

- pingReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin { return nil; }

- pongReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin { return nil; }

- newNickNeededWhileRegisteringOnConnection: (id)connection sender: aPlugin 
   { return nil; }

@end
