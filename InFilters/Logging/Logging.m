/***************************************************************************
                              Logging.m
                          -------------------
    begin                : Sat Jun 27 18:58:30 CDT 2003
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

#include "Logging.h"
#include "TalkSoupBundles/TalkSoup.h"

#include <Foundation/NSAttributedString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSFileHandle.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSFileManager.h>

static NSMapTable *files = 0;
static NSInvocation *invoc = nil;

@implementation Logging
+ (void)initialize
{
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
		return S2AS(@"Connect to a server before using this command");
	}
	
	if ([arr count] == 0)
	{
		x = NSMapGet(files, connection);
		if (!x)
		{
			return S2AS(@"Usage: /logging <file>");
		}
		else
		{
			NSMapRemove(files, connection);
			return S2AS(@"Logging turned off.");
		}
	}
	
	dfm = [NSFileManager defaultManager];
	x = nil;
	path = [[arr objectAtIndex: 0] stringByExpandingTildeInPath];
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
		return BuildAttributedString(@"Could not open file for writing: ", path, nil);
	}
	
	NSMapInsert(files, connection, x);
	
	return S2AS(@"Logging turned on.");
}
- pluginActivated
{
	NSLog(@"%@", invoc);
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
	
	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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
	
	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}	
- CTCPRequestReceived: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)argument 
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ CTCPRequestReceived: aCTCP withArgument: argument from: aPerson
	  onConnection: connection withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
- CTCPReplyReceived: (NSAttributedString *)aCTCP
   withArgument: (NSAttributedString *)argument 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id x = NSMapGet(files, connection);

	[_TS_ CTCPReplyReceived: aCTCP withArgument: argument from: aPerson
	  onConnection: connection withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[_TS_ modeChanged: mode on: anObject withParams: paramList from: aPerson
	  onConnection: connection withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[_TS_ numericCommandReceived: command withParams: paramList from: sender
	  onConnection: connection withNickname: aNick sender: self];
	
	if (!x)
	{
		return self;
	}

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
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

	[x writeData: [[NSString stringWithFormat: @"[%@]\n", [NSDate date]] 
	  dataUsingEncoding: [NSString defaultCStringEncoding]
	  allowLossyConversion: YES]];

	return self;
}
@end
/*
- CTCPRequestReceived: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)argument 
   from: (NSAttributedString *)aPerson onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	SEL sid = NSSelectorFromString([NSString stringWithFormat: 
	   @"CTCPRequest%@:from:", [[aCTCP string] uppercaseString]]);
	id str;
	id where;
	
	where = ContentConsoleName;
	
	if (sid && [self respondsToSelector: sid])
	{
		where = [self performSelector: sid withObject: argument
		 withObject: aPerson];
	}
	
	if (where == self) return self;
	
	if ([argument length])
	{
		str = BuildAttributedFormat(_l(@"Received a CTCP '%@ %@' from %@"), 
		  aCTCP, argument, [IRCUserComponents(aPerson) objectAtIndex: 0]);
	}
	else
	{
		str = BuildAttributedFormat(_l(@"Received a CTCP %@ from %@"),
		  aCTCP, [IRCUserComponents(aPerson) objectAtIndex: 0]);
	}
	
	[content putMessage: str in: where];
	
	return self;
}
- CTCPReplyReceived: (NSAttributedString *)aCTCP
   withArgument: (NSAttributedString *)argument 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	SEL sid = NSSelectorFromString([NSString stringWithFormat: 
	   @"CTCPReply%@:from:", [[aCTCP string] uppercaseString]]);
	id str;
	id where = nil;
	
	if (sid && [self respondsToSelector: sid])
	{
		where = [self performSelector: sid withObject: argument
		 withObject: aPerson];
	}

	if (where == self) return self;
	
	if ([argument length])
	{
		str = BuildAttributedString(
		  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @"-",
		  [IRCUserComponents(aPerson) objectAtIndex: 0], 
		  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @"-",
		  @" ", aCTCP, @" ", argument, nil);
	}
	else
	{
		str = BuildAttributedString(MARK, TypeOfColor, 
		  GNUstepOutputOtherBracketColor, @"-",
		  [IRCUserComponents(aPerson) objectAtIndex: 0], 
		  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @"-",
		  @" ", aCTCP, nil);
	}

	[content putMessage: str in: where];

	return self;
}
- errorReceived: (NSAttributedString *)anError onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[self systemMessage: BuildAttributedFormat(_l(@"Error: %@"), anError)
	  onConnection: nil];
	
	return self;
}
- wallopsReceived: (NSAttributedString *)message 
   from: (NSAttributedString *)sender 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[content putMessage: BuildAttributedFormat(_l(@"Wallops(%@): %@"),
	  sender, message) in: ContentConsoleName];
	  
	return self;
}
- userKicked: (NSAttributedString *)aPerson 
   outOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason from: (NSAttributedString *)kicker 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id name = [IRCUserComponents(kicker) objectAtIndex: 0];
	id lowChan = GNUstepOutputLowercase([aChannel string]);
	id view = [content controllerForViewWithName: lowChan];

	if (GNUstepOutputCompare([aPerson string], [connection nick]))
	{
		[self leaveChannel: lowChan];
	}
	else
	{
		[[nameToChannelData objectForKey: lowChan] removeUser: [aPerson string]];
		[[view tableView] reloadData];
	}
	
	[content putMessage: 
	  BuildAttributedFormat(_l(@"%@ was kicked from %@ by %@ (%@)"), aPerson,
	  aChannel, name, reason) 
	  in: [aChannel string]];
	return self;
}
- invitedTo: (NSAttributedString *)aChannel from: (NSAttributedString *)inviter 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id name = [IRCUserComponents(inviter) objectAtIndex: 0];
	
	[content putMessage: 
	  BuildAttributedFormat(_l(@"You have been invited to %@ by %@"), 
	  aChannel, name)
	  in: nil];
	return self;
}
- modeChanged: (NSAttributedString *)aMode on: (NSAttributedString *)anObject 
   withParams: (NSArray *)paramList from: (NSAttributedString *)aPerson 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	Channel *chan;
	unichar m;
	BOOL add = YES;
	int argindex = 0;
	id mode = [aMode string];
	int modeindex;
	int modelen = [mode length];
	int argcnt = [paramList count];
	id who = [IRCUserComponents(aPerson) objectAtIndex: 0];
	
	id params;
	NSEnumerator *iter;
	id object = nil;
	
	iter = [paramList objectEnumerator];
	params = AUTORELEASE([NSMutableAttributedString new]);
	
	while ((object = [iter nextObject]))
	{
		[params appendAttributedString: S2AS(@" ")];
		[params appendAttributedString: object];
	}
		
	chan = [nameToChannelData objectForKey: 
	  GNUstepOutputLowercase([anObject string])];

	for (modeindex = 0; modeindex < modelen; modeindex++)
	{
		m = [mode characterAtIndex: modeindex];
		switch (m)
		{
			case '+':
				add = YES;
				continue;
			case '-':
				add = NO;
				continue;
			default:
				break;
		}
				
		if (chan)
		{
			switch (m)
			{
				case 'o':
					if (argindex < argcnt)
					{
						id user;
						user = [chan userWithName: 
						  [[paramList objectAtIndex: argindex] string]];
						[user setOperator: add];
						[[[content controllerForViewWithName: [anObject string]] tableView] 
						   reloadData];
						argindex++;
					}
					break;
				case 'v':
					if (argindex < argcnt)
					{
						id user;
						user = [chan userWithName: 
						  [[paramList objectAtIndex: argindex] string]];
						[user setVoice: add];
						[[[content controllerForViewWithName: [anObject string]] tableView] 
						   reloadData];
						argindex++;
					}
					break;
				default:
					break;
			}
		}
	}
	
	[content putMessage: 
	  BuildAttributedFormat(_l(@"%@ sets mode %@ %@%@"), who, aMode, anObject,
	  params) in: [anObject string]];
	
	return self;
}
- numericCommandReceived: (NSAttributedString *)command 
   withParams: (NSArray *)paramList from: (NSAttributedString *)sender 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{	
	SEL sel = NSSelectorFromString([NSString stringWithFormat: 
	  @"numericHandler%@:", [command string]]);
	NSMutableAttributedString *a = 
	  AUTORELEASE([[NSMutableAttributedString alloc] initWithString: @""]);
	NSEnumerator *iter;
	id object;
	id where;
	
	if ([connection connected] && !registered)
	{
		object = [IRCUserComponents(sender) objectAtIndex: 0];
		[content setLabel: object
		 forViewWithName: ContentConsoleName];
		[[content window] setTitle: [object string]];
	}
	
	iter = [paramList objectEnumerator];
	while ((object = [iter nextObject]))
	{
		[a appendAttributedString: object];
		[a appendAttributedString: S2AS(@" ")];
	}
	
	where = ContentConsoleName;
	
	if ([self respondsToSelector: sel])
	{
		where = [self performSelector: sel withObject: paramList];
	}

	if (where != self)
	{
		[content putMessage: a in: where];
	}
	
	return self;
}
- nickChangedTo: (NSAttributedString *)newName 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	NSEnumerator *iter;
	id object;
	id array;
	NSAttributedString *oldName = [IRCUserComponents(aPerson) objectAtIndex: 0];
	
	if (GNUstepOutputCompare([newName string], [connection nick]))
	{
		[self setNick: [newName string]];
		[content setNickViewString: [newName string]];
	}
	
	array = [self channelsWithUser: [oldName string]];
	iter = [array objectEnumerator];
	while ((object = [iter nextObject]))
	{
		[[nameToChannelData objectForKey: 
		  GNUstepOutputLowercase(object)] userRenamed: [oldName string] 
		  to: [newName string]];
		[[[content controllerForViewWithName: object] tableView]
		  reloadData];
	}
	
	[content putMessage: BuildAttributedFormat(
	  _l(@"%@ is now known as %@"), oldName, newName)
	  in: array];
	  
	if ([content controllerForViewWithName: [oldName string]])
	{
		[content renameViewWithName: [oldName string] to: [newName string]];
		[content setLabel: S2AS([newName string]) 
		  forViewWithName: [newName string]];
	}
	  
	return self;
}
- channelJoined: (NSAttributedString *)channel 
   from: (NSAttributedString *)joiner 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id name = [channel string];
	id array = IRCUserComponents(joiner);
	id lowName = GNUstepOutputLowercase(name);

	if (GNUstepOutputCompare([[array objectAtIndex: 0] string], [aConnection nick]))
	{
		id x;
		id object;

		[content addChannelWithName: name withLabel: channel];
		[content focusViewWithName: name];
		[nameToChannelData setObject: x = AUTORELEASE([[Channel alloc] 
		  initWithIdentifier: lowName]) forKey: lowName];
				
		object = [[content controllerForViewWithName: lowName] tableView];
		[object setDataSource: x];
		[object setTarget: self];
		[object setDoubleAction: @selector(doubleClickedUser:)];
	}
	else
	{
		[[nameToChannelData objectForKey: lowName] addUser: 
		  [[array objectAtIndex: 0] string]];
		[[[content controllerForViewWithName: lowName] tableView]
		  reloadData];
	}
	
	[content putMessage: BuildAttributedFormat(_l(@"%@ (%@) has joined %@"),
	  [array objectAtIndex: 0], [array objectAtIndex: 1], channel) in: name];
	
	[self updateTopicInspector];
	
	return self;
}
- channelParted: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage
   from: (NSAttributedString *)parter onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id name = [IRCUserComponents(parter) objectAtIndex: 0];
	id lowChan = GNUstepOutputLowercase([channel string]);
	id view = [content controllerForViewWithName: lowChan];

	if (GNUstepOutputCompare([name string], [connection nick]))
	{
		[self leaveChannel: lowChan];
	}
	else
	{
		[[nameToChannelData objectForKey: lowChan] removeUser: [name string]];
		[[view tableView] reloadData];
	}
	
	if (view)
	{
		[content putMessage: BuildAttributedFormat(_l(@"%@ has left %@ (%@)"), 
		  name, channel, aMessage) in: lowChan];
	}
	
	return self;
}
- quitIRCWithMessage: (NSAttributedString *)aMessage 
   from: (NSAttributedString *)quitter onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id name = [IRCUserComponents(quitter) objectAtIndex: 0];
	id array = [self channelsWithUser: [name string]];
	NSEnumerator *iter;
	id object;
	
	iter = [array objectEnumerator];
	while ((object = [iter nextObject]))
	{
		id low = GNUstepOutputLowercase(object);
		[[nameToChannelData objectForKey: low] 
		  removeUser: [name string]];
		[[[content controllerForViewWithName: low] tableView]
		  reloadData];
	}
	
	[content putMessage:
	  BuildAttributedFormat(_l(@"%@ has quit IRC (%@)"), name, aMessage)
	  in: array];
		
	return self;
}
- topicChangedTo: (NSAttributedString *)aTopic in: (NSAttributedString *)channel
   from: (NSAttributedString *)aPerson onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[content putMessage:
	  BuildAttributedFormat(_l(@"%@ changed the topic in %@ to '%@'"),
	   [IRCUserComponents(aPerson) objectAtIndex: 0], channel, aTopic)
	  in: [channel string]];
	
	[_TS_ setTopicForChannel: S2AS([channel string]) to: nil onConnection: aConnection
	  withNickname: S2AS([aConnection nick]) sender: _GS_];
	return self;
}
- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id who = [IRCUserComponents(sender) objectAtIndex: 0];
	id whos = [who string];
	id where;
	id string;
	id privstring;
	id pubstring;
	
	privstring = BuildAttributedString(
	  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @"*",
	  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, who, 
	  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @"*",
	  @" ", aMessage, nil);
	pubstring = BuildAttributedString(
	  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @"<", who, 
	  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @">",
	  @" ", aMessage, nil);
	
	string = pubstring;
	
	if (GNUstepOutputCompare([to string], [connection nick]))
	{
		if (![content controllerForViewWithName: where = whos])
		{
			where = nil;
			string = privstring;
		}
	}
	else
	{
		if (![content controllerForViewWithName: where = [to string]])
		{
			where = nil;
			string = privstring;
		}
	}
	
	[content putMessage: string in: where];
	
	return self;
}
- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[self messageReceived: aMessage to: to from: sender onConnection: aConnection
	  withNickname: aNick
	  sender: aPlugin];
	return self;
}
- actionReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id who = [IRCUserComponents(sender) objectAtIndex: 0];
	id whos = [who string];
	id where;
	NSString *prefix = @"*";
	
	if (GNUstepOutputCompare([to string], [connection nick]))
	{
		if (![content controllerForViewWithName: where = whos])
		{
			where = nil;
			prefix = @"***";
		}
	}
	else
	{
		if (![content controllerForViewWithName: where = [to string]])
		{
			where = nil;
			prefix = @"***";
		}
	}
	
	[content putMessage: BuildAttributedString(
	  MARK, TypeOfColor, GNUstepOutputOtherBracketColor,
	  prefix, @" ", who, @" ", aMessage, nil) in: where];
	
	return self;
}
- pingReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendPongWithArgument: arg onConnection: aConnection
	  withNickname: aNick
	  sender: _GS_];

	return self;
}
*/
