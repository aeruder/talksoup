/***************************************************************************
                              Logging.m
                          -------------------
    begin                : Sat Jun 27 18:58:30 CDT 2003
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

#import "Logging.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSCalendarDate.h>
#import <Foundation/NSString.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSData.h>
#import <Foundation/NSEnumerator.h>

static NSMapTable *files = 0;
static NSInvocation *invoc = nil;

#define USE_DATE [[NSDate date] descriptionWithCalendarFormat: @"%Y-%m-%d %H:%M:%S" \
  timeZone: nil locale: nil]

@implementation Logging
+ (void)initialize
{
	if (invoc) return;

	files = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 5);
	invoc = RETAIN([NSInvocation invocationWithMethodSignature: 
	  [self methodSignatureForSelector: @selector(commandLogging:connection:)]]);
	[invoc retainArguments];
	[invoc setTarget: self];
	[invoc setSelector: @selector(commandLogging:connection:)];
}
+ (NSAttributedString *)commandLogging: (NSString *)command connection: (id)connection
{
	id arr = [command separateIntoNumberOfArguments: 1];
	id x;
	id dfm;
	BOOL isDir;
	id path;
	
	if (!connection)
	{
		return S2AS(_l(@"Connect to a server before using this command"));
	}
	
	if ([arr count] == 0)
	{
		x = NSMapGet(files, connection);
		if (!x)
		{
			return S2AS(_l(@"Usage: /logging <file>"));
		}
		else
		{
			[x writeData: [[NSString stringWithFormat: _l(@"[%@] LOGGING DEACTIVATED\n"),
			  USE_DATE]
			  dataUsingEncoding: [NSString defaultCStringEncoding]
			  allowLossyConversion: YES]];
			NSMapRemove(files, connection);
			return S2AS(_l(@"Logging turned off."));
		}
	}
	
	dfm = [NSFileManager defaultManager];
	x = nil;
	path = [[arr objectAtIndex: 0] stringByStandardizingPath];
	isDir = NO;
	
	if (![dfm fileExistsAtPath: path isDirectory: &isDir])
	{
		isDir = ![dfm createFileAtPath: path contents: AUTORELEASE([NSData new])
		  attributes: nil];
	}
	
	if (!isDir)
	{
		x = [NSFileHandle fileHandleForWritingAtPath: path];
		[x seekToEndOfFile];
	}
	else
	{
		return BuildAttributedString(_l(@"Could not open file for writing: "), path, nil);
	}
	
	NSMapInsert(files, connection, x);
	
	[x writeData: [[NSString stringWithFormat: _l(@"[%@] LOGGING ACTIVATED\n"),
	  USE_DATE]
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];
	
	return S2AS(_l(@"Logging turned on."));
}
- (NSAttributedString *)pluginDescription
{
	return BuildAttributedString([NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Author: "), @"Andrew Ruder\n\n",
	 [NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Description: "), _l(@"This command can handle logging to a file. "
	 @"To use it, simply type /logging <file> on any connection to "
	 @"log that connection.  To set up persistent logging, please "
	 @"see the FAQ distributed with TalkSoup."),
	 @"\n\n",
	 _l(@"Copyright (C) 2005 by Andrew Ruder"),
	 nil);
}
- pluginActivated
{
	[_TS_ addCommand: @"logging" withInvocation: invoc];
	return self;
}
- pluginDeactivated
{
	[_TS_ removeCommand: @"logging"];
	return self;
}
- quitWithMessage: (NSAttributedString *)aMessage onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, aConnection);

	[_TS_ quitWithMessage: aMessage onConnection: aConnection withNickname: aNick
	  sender: self];
	
	if (!x)
	{
		return self;
	}
	
	[x writeData: [[NSString stringWithFormat: _l(@"[%@] %@ has quit IRC (%@)\n"), 
	  USE_DATE, [aConnection nick], [aMessage string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- sendCTCPReply: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)args
   to: (NSAttributedString *)aPerson 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, aConnection);

	[_TS_ sendCTCPReply: aCTCP withArgument: args to: aPerson
	  onConnection: aConnection withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}
	
	[x writeData: [[NSString stringWithFormat: _l(@"[%@] <%@:%@> CTCP-REPLY %@ %@\n"), 
	  USE_DATE, [aConnection nick], [aPerson string], [aCTCP string], 
	  [args string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- sendCTCPRequest: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)args
   to: (NSAttributedString *)aPerson onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
	sender: aPlugin
{
	id x = NSMapGet(files, aConnection);

	[_TS_ sendCTCPRequest: aCTCP withArgument: args to: aPerson
	  onConnection: aConnection withNickname: aNick sender: self];

	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: _l(@"[%@] <%@:%@> CTCP-REQUEST %@ %@\n"), 
	  USE_DATE, [aConnection nick], [aPerson string], [aCTCP string], 
	  [args string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}  
- sendMessage: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick    
	sender: aPlugin
{
	id x = NSMapGet(files, aConnection);

	[_TS_ sendMessage: message to: receiver onConnection: aConnection 
	  withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: @"[%@] <%@:%@> %@\n", 
	  USE_DATE, [aConnection nick], [receiver string], [message string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- sendNotice: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
	sender: aPlugin
{
	id x = NSMapGet(files, aConnection);

	[_TS_ sendNotice: message to: receiver onConnection: aConnection
	  withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: @"[%@] <%@:%@> %@\n", 
	  USE_DATE, [aConnection nick], [receiver string], [message string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- sendAction: (NSAttributedString *)anAction to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
	sender: aPlugin
{
	id x = NSMapGet(files, aConnection);

	[_TS_ sendAction: anAction to: receiver onConnection: aConnection
	  withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: @"[%@] * %@:%@ %@\n", 
	  USE_DATE, [aConnection nick], [receiver string], [anAction string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- lostConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ lostConnection: connection withNickname: aNick sender: self];

	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: _l(@"[%@] Connection Terminated\n"), 
	  USE_DATE] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];
	[x writeData: [[NSString stringWithFormat: _l(@"[%@] LOGGING DEACTIVATED\n"),
	  USE_DATE]
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];
	
	NSMapRemove(files, connection);

	return self;
}	
- CTCPRequestReceived: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)argument 
   to: (NSAttributedString *)receiver
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ CTCPRequestReceived: aCTCP withArgument: argument 
	  to: receiver from: aPerson
	  onConnection: connection withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: _l(@"[%@] <%@:%@> CTCP-REQUEST %@ %@\n"), 
	  USE_DATE, [[IRCUserComponents(aPerson) objectAtIndex: 0] string], 
	  [receiver string], [aCTCP string], [argument string]]
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- CTCPReplyReceived: (NSAttributedString *)aCTCP
   withArgument: (NSAttributedString *)argument 
   to: (NSAttributedString *)receiver
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ CTCPReplyReceived: aCTCP withArgument: argument 
	  to: receiver from: aPerson
	  onConnection: connection withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: @"[%@] <%@:%@> %@ %@\n", 
	  USE_DATE, [[IRCUserComponents(aPerson) objectAtIndex: 0] string],
	  [receiver string], [aCTCP string], [argument string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- errorReceived: (NSAttributedString *)anError onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ errorReceived: anError onConnection: connection withNickname: aNick
	  sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: _l(@"[%@] ERROR: %@\n"), USE_DATE,
	  [anError string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- wallopsReceived: (NSAttributedString *)message 
   from: (NSAttributedString *)sender 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ wallopsReceived: message from: sender onConnection: connection
	  withNickname: aNick sender: self];
	  
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: _l(@"[%@] Wallops(%@): %@\n"), 
	  USE_DATE, [[IRCUserComponents(sender) objectAtIndex: 0] string], 
	  [message string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- userKicked: (NSAttributedString *)aPerson 
   outOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason from: (NSAttributedString *)kicker 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ userKicked: aPerson outOf: aChannel for: reason from: kicker
	  onConnection: connection withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: _l(@"[%@] %@ was kicked from %@ by %@ (%@)\n"), 
	  USE_DATE, [aPerson string], [aChannel string], 
	  [[IRCUserComponents(kicker) objectAtIndex: 0] string], [reason string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}		 
- invitedTo: (NSAttributedString *)aChannel from: (NSAttributedString *)inviter 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ invitedTo: aChannel from: inviter onConnection: connection
	  withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: _l(@"[%@] %@(%@) has invited you to %@\n"), 
	  USE_DATE, [[IRCUserComponents(inviter) objectAtIndex: 0] string], 
	  [[IRCUserComponents(inviter) objectAtIndex: 1] string], [aChannel string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- modeChanged: (NSAttributedString *)mode on: (NSAttributedString *)anObject 
   withParams: (NSArray *)paramList from: (NSAttributedString *)aPerson 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);
	NSMutableString *str;
	NSEnumerator *iter;
	id object;

	[_TS_ modeChanged: mode on: anObject withParams: paramList from: aPerson
	  onConnection: connection withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}
	
	iter = [paramList objectEnumerator];
	str = AUTORELEASE([NSMutableString new]);
	object = [iter nextObject];
	
	while (object)
	{
		[str appendString: [object string]];
		if ((object = [iter nextObject]))
		{
			[str appendString: @" "];
		}
	}

	[x writeData: [[NSString stringWithFormat: _l(@"[%@] %@ sets mode %@ %@ %@\n"), 
	  USE_DATE, [[IRCUserComponents(aPerson) objectAtIndex: 0] string], 
	  [mode string], [anObject string], str] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}  
- numericCommandReceived: (NSAttributedString *)command 
   withParams: (NSArray *)paramList from: (NSAttributedString *)sender 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);
	NSMutableString *str;
	NSEnumerator *iter;
	id object;

	[_TS_ numericCommandReceived: command withParams: paramList from: sender
	  onConnection: connection withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	iter = [paramList objectEnumerator];
	str = AUTORELEASE([NSMutableString new]);
	object = [iter nextObject];
	
	while (object)
	{
		[str appendString: [object string]];
		if ((object = [iter nextObject]))
		{
			[str appendString: @" "];
		}
	}
	
	[x writeData: [[NSString stringWithFormat: @"[%@] (%@) %@\n", 
	  USE_DATE, [command string], str] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- nickChangedTo: (NSAttributedString *)newName 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ nickChangedTo: newName from: aPerson onConnection: connection
	  withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: _l(@"[%@] %@ is now known as %@\n"), 
	  USE_DATE, [[IRCUserComponents(aPerson) objectAtIndex: 0] string],
	  [newName string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- channelJoined: (NSAttributedString *)channel 
   from: (NSAttributedString *)joiner 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ channelJoined: channel from: joiner onConnection: connection
	  withNickname: aNick sender: self];

	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: _l(@"[%@] %@(%@) has joined %@\n"), 
	  USE_DATE, [[IRCUserComponents(joiner) objectAtIndex: 0] string],
	  [[IRCUserComponents(joiner) objectAtIndex: 1] string], [channel string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- channelParted: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage
   from: (NSAttributedString *)parter onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ channelParted: channel withMessage: aMessage from: parter
	  onConnection: connection withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: _l(@"[%@] %@ has parted %@(%@)\n"), 
	  USE_DATE, [[IRCUserComponents(parter) objectAtIndex: 0] string],
	  [channel string], [aMessage string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- quitIRCWithMessage: (NSAttributedString *)aMessage 
   from: (NSAttributedString *)quitter onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ quitIRCWithMessage: aMessage from: quitter onConnection: connection
	  withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: _l(@"[%@] %@ has quit IRC(%@)\n"), 
	  USE_DATE, [[IRCUserComponents(quitter) objectAtIndex: 0] string],
	  [aMessage string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- topicChangedTo: (NSAttributedString *)aTopic in: (NSAttributedString *)channel
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ topicChangedTo: aTopic in: channel from: aPerson onConnection: connection
	  withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: _l(@"[%@] %@ changed the topic in %@ to '%@'\n"), 
	  USE_DATE, [[IRCUserComponents(aPerson) objectAtIndex: 0] string],
	  [channel string], [aTopic string]]
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ messageReceived: aMessage to: to from: sender onConnection: connection
	  withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: @"[%@] <%@:%@> %@\n", 
	  USE_DATE, [[IRCUserComponents(sender) objectAtIndex: 0] string],
	  [to string], [aMessage string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ noticeReceived: aMessage to: to from: sender onConnection: connection
	  withNickname: aNick sender: self];

	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: @"[%@] <%@:%@> %@\n", 
	  USE_DATE, [[IRCUserComponents(sender) objectAtIndex: 0] string],
	  [to string], [aMessage string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- actionReceived: (NSAttributedString *)anAction to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ actionReceived: anAction to: to from: sender onConnection: connection
	  withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: @"[%@] * %@:%@ %@\n", 
	  USE_DATE, [[IRCUserComponents(sender) objectAtIndex: 0] string],
	  [to string], [anAction string]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
@end

#undef USE_DATE

