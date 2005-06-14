/***************************************************************************
                               commands.m 
                          -------------------
    begin                : Mon Dec 22 07:34:32 CST 2003
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

#import "commands.h"

#import <Foundation/NSString.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSMapTable.h>

#define MARK [NSNull null]
#define NO_CONNECT S2AS(_(@"Connect to a server before using this command"))

@implementation TalkSoup (Commands)
- (NSAttributedString *)commandSaveLoaded: (NSString *)args 
   connection: (id)connection
{
	[self savePluginList];

	return S2AS(_(@"The loaded bundles will now load automagically on TalkSoup startup."));
}
- (NSAttributedString *)commandLoaded: (NSString *)args connection: (id)connection
{
	return BuildAttributedString(_(@"Currently loaded bundles:\n"),
	  MARK, IRCBold, IRCBoldValue, _(@"Output: "), activatedOutput, @"\n",
	  MARK, IRCBold, IRCBoldValue, _(@"Input: "), activatedInput, @"\n",
	  MARK, IRCBold, IRCBoldValue, _(@"Output Filters: "), [[self activatedOutFilters]
	    componentsJoinedByString: @", "], @"\n",
	  MARK, IRCBold, IRCBoldValue, _(@"Input Filters: "), [[self activatedInFilters]
	    componentsJoinedByString: @", "], nil);
}
- (NSAttributedString *)commandLoad: (NSString *)args connection: (id)connection
{
	id x = [args separateIntoNumberOfArguments: 3];
	id first, second;
	id key;
	id array = nil;
	BOOL isIn = NO;
	
	[self refreshPluginList];
	
	if ([x count] < 1)
	{
		return S2AS(_(@"Usage: /load <in/out>"));
	}
	
	first = [x objectAtIndex: 0];
	
	if ([first isEqualToString: @"in"])
	{
		array = [inNames allKeys];
		isIn = YES;
	}
	else if ([first isEqualToString: @"out"])
	{
		array = [outNames allKeys];
	}
	else
	{
		return S2AS(_(@"Usage: /load <in/out>"));
	}
	
	second = ([x count] > 1) ? [x objectAtIndex: 1] : nil;

	if (second && [array containsObject: second]) 
	{
		key = second;
	}
	else if (second)
	{
		NSEnumerator *iter;
		iter = [array objectEnumerator];
		while ((key = [iter nextObject])) 
		{
			if ([[key lowercaseString] isEqualToString: second])
				break;
		}
	}
	
	if (!second || !key)
	{
		return BuildAttributedString(
		  _(@"Usage: /load <in/out> <filter>"), @"\n",
		  MARK, IRCBold, IRCBoldValue, _(@"Possible filters: "), 
		  [array componentsJoinedByString: @", "], nil);
	}
	
	if (isIn)
	{
		[self activateInFilter: key];
	}
	else
	{
		[self activateOutFilter: key];
	}
	
	return BuildAttributedString(key, _(@" loaded"), nil);
}
- (NSAttributedString *)commandUnload: (NSString *)args connection: (id)connection
{
	id x = [args separateIntoNumberOfArguments: 3];
	id first, second;
	id key;
	id array = nil;
	BOOL isIn = NO;
	
	if ([x count] < 1)
	{
		return S2AS(_(@"Usage: /unload <in/out>"));
	}
	
	first = [x objectAtIndex: 0];
	
	if ([first isEqualToString: @"in"])
	{
		array = [self activatedInFilters];
		isIn = YES;
	}
	else if ([first isEqualToString: @"out"])
	{
		array = [self activatedOutFilters];
	}
	else
	{
		return S2AS(_(@"Usage: /unload <in/out>"));
	}

	second = ([x count] > 1) ? [x objectAtIndex: 1] : nil;
	
	if (second && [array containsObject: second]) 
	{
		key = second;
	}
	else if (second)
	{
		NSEnumerator *iter;
		iter = [array objectEnumerator];
		while ((key = [iter nextObject])) 
		{
			if ([[key lowercaseString] isEqualToString: second])
				break;
		}
	}
	
	if (!second || !key)
	{
		return BuildAttributedString(
		  _(@"Usage: /unload <in/out> <filter>"), @"\n", 
		  MARK, IRCBold, IRCBoldValue, _(@"Possible filters: "), 
		  [array componentsJoinedByString: @", "], nil);
	}
	
	if (isIn)
	{
		[self deactivateInFilter: key];
	}
	else
	{
		[self deactivateOutFilter: key];
	}
	
	return BuildAttributedString(key, _(@" unloaded"), nil);
}
- (NSAttributedString *)commandJoin: (NSString *)aString connection: connection
{
	NSArray *x = [aString separateIntoNumberOfArguments: 3];
	id pass;
	
	if (!connection) return NO_CONNECT;
	
	if ([x count] == 0)
	{
		return S2AS(_(@"Usage: /join <channel1[,channel2...]> [password1[,password2...]]"));
	}
	
	pass = ([x count] == 2) ? [x objectAtIndex: 1] : nil;
	
	[_TS_ joinChannel: S2AS([x objectAtIndex: 0]) withPassword: S2AS(pass) 
	  onConnection: connection
	  withNickname: S2AS([connection nick])
	  sender: output];
	  
	return nil;
}
- (NSAttributedString *)commandMsg: (NSString *)aString connection: connection
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	
	if (!connection) return NO_CONNECT;
	
	if ([x count] < 2)
	{
		return S2AS(_(@"Usage: /msg <person> <message>"));
	}
	
	[_TS_ sendMessage: S2AS([x objectAtIndex: 1]) to: 
	  S2AS([x objectAtIndex: 0])
	  onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: output];

	return nil;
}
- (NSAttributedString *)commandPart: (NSString *)args connection: connection
{
	id x = [args separateIntoNumberOfArguments: 2];
	id name, msg;
	
	if (!connection) return NO_CONNECT;
	
	msg = name = nil;
	
	if ([x count] >= 1)
	{
		name = [x objectAtIndex: 0];
	}
	if ([x count] >= 2)
	{
		msg = [x objectAtIndex: 1];
	}
	
	if (!name)
	{
		return S2AS(_(@"Usage: /part <channel> [message]"));
	}
	
	[_TS_ partChannel: S2AS(name) withMessage: S2AS(msg) 
	  onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandNotice: (NSString *)aString connection: connection
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	
	if (!connection) return NO_CONNECT;
	
	if ([x count] < 2)
	{
		return S2AS(_(@"Usage: /notice <person> <message>"));
	}
	
	[_TS_ sendNotice: S2AS([x objectAtIndex: 1]) to: 
	  S2AS([x objectAtIndex: 0])
	  onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: output];

	return nil;
}
- (NSAttributedString *)commandAway: (NSString *)aString connection: connection
{
	NSArray *x = [aString separateIntoNumberOfArguments: 1];
	id y = nil;
	
	if (!connection) return NO_CONNECT;
	
	if ([x count] > 0)
	{
		y = [x objectAtIndex: 0];
	}
	
	[_TS_ setAwayWithMessage: S2AS(y) onConnection: connection
	  withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- commandNick: (NSString *)aString connection: connection
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	
	if (!connection) return NO_CONNECT;
	
	if ([x count] == 0)
	{
		return S2AS(_(@"Usage: /nick <newnick>"));
	}
	
	[_TS_ changeNick: S2AS([x objectAtIndex: 0]) onConnection: connection
	  withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandQuit: (NSString *)aString connection: connection
{
	if (!connection) return NO_CONNECT;
	
	[_TS_ quitWithMessage: S2AS(aString) onConnection: connection
	  withNickname: S2AS([connection nick]) sender: output];
	
	return nil;
}
- (NSAttributedString *)commandColors: (NSString *)aString connection: connection
{
	return BuildAttributedString(
	 _(@"Valid color names include any color from the following list: "),
	 [PossibleUserColors() componentsJoinedByString: @", "], @"\n",
	 _(@"Also, a string is valid if it is of the form 'custom [red] [green] [blue]' "),
	  _(@"where [red], [green], [blue] are the red, green, and blue "),
	  _(@"components of the color on a scale of 0 to 1000."), nil);
}  		  
- (NSAttributedString *)commandCtcp: (NSString *)command connection: connection
{
	id array;
	id ctcp;
	id args;
	id who;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 3];
	
	if ([array count] < 2)
	{
		return S2AS(_(@"Usage: /ctcp <nick> <ctcp> [arguments]")); 
	}

	args = ([array count] == 3) ? [array objectAtIndex: 2] : nil;
	
	ctcp = [[array objectAtIndex: 1] uppercaseString];
	who = [array objectAtIndex: 0];

	[_TS_ sendCTCPRequest: S2AS(ctcp) withArgument: S2AS(args)
	  to: S2AS(who) onConnection: connection 
	  withNickname: S2AS([connection nick]) sender: output];
	
	return nil;
}	
- (NSAttributedString *)commandVersion: (NSString *)command connection: connection
{
	id array;
	id who;
	
	array = [command separateIntoNumberOfArguments: 2];

	if (!connection) return NO_CONNECT;
	
	if ([array count] == 0)
	{
		return S2AS(_(@"Usage: /version <nick>"));
	}

	who = [array objectAtIndex: 0];
	
	[_TS_ sendCTCPRequest: S2AS(@"VERSION") withArgument: nil
	  to: S2AS(who) onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandClientinfo: (NSString *)command connection: connection
{
	id array;
	id who;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 2];

	if ([array count] == 0)
	{
		return S2AS(_(@"Usage: /clientinfo <nick>"));
	}

	who = [array objectAtIndex: 0];
	
	[_TS_ sendCTCPRequest: S2AS(@"CLIENTINFO") withArgument: nil
	  to: S2AS(who) onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandUserinfo: (NSString *)command connection: connection
{
	id array;
	id who;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 2];

	if ([array count] == 0)
	{
		return S2AS(_(@"Usage: /userinfo <nick>"));
	}

	who = [array objectAtIndex: 0];
	
	[_TS_ sendCTCPRequest: S2AS(@"USERINFO") withArgument: nil
	  to: S2AS(who) onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandPing: (NSString *)command connection: connection
{
	id array;
	id who;
	id arg = nil;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 2];

	if ([array count] <= 1)
	{
		return S2AS(_(@"Usage: /ping <nick> <argument>"));
	}

	who = [array objectAtIndex: 0];
	arg = [array objectAtIndex: 1];
	
	[_TS_ sendCTCPRequest: S2AS(@"PING") withArgument: S2AS(arg)
	  to: S2AS(who) onConnection: connection withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandTopic: (NSString *)command connection: connection
{
	id array;
	id who;
	id arg = nil;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 2];

	if ([array count] < 1)
	{
		return S2AS(_(@"Usage: /topic <channel> [topic]"));
	}

	who = [array objectAtIndex: 0];
	
	if ([array count] > 1)
	{
		arg = [array objectAtIndex: 1];
	}
	
	[_TS_ setTopicForChannel: S2AS(who) to: S2AS(arg)
	  onConnection: connection withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandKick: (NSString *)command connection: connection
{
	id array;
	id who;
	id arg = nil;
	id chan;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 3];

	if ([array count] <= 1)
	{
		return S2AS(_(@"Usage: /kick <channel> <user> [comment]"));
	}

	who = [array objectAtIndex: 1];
	chan = [array objectAtIndex: 0];
	if ([array count] > 2)
	{
		arg = [array objectAtIndex: 2];
	}
	
	[_TS_ kick: S2AS(who) offOf: S2AS(chan) for: S2AS(arg)
	  onConnection: connection withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandRaw: (NSString *)command connection: connection
{
	id array;
	id arg = nil;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 1];

	if ([array count] == 0)
	{
		return S2AS(_(@"Usage: /raw <message>"));
	}

	arg = [array objectAtIndex: 0];
	
	[_TS_ writeRawString: S2AS(arg)
	  onConnection: connection withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandMode: (NSString *)command connection: connection
{
	id array;
	id mode;
	id arg = AUTORELEASE([NSMutableArray new]);
	id obj;
	int ind, max;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: -1];

	max = [array count];
	
	if (max <= 1)
	{
		return S2AS(_(@"Usage: /mode <object> <mode(s)> [arguments]"));
	}

	mode = [array objectAtIndex: 1];
	obj = [array objectAtIndex: 0];
	
	for (ind = 2; ind < max; ind++)
	{
		[arg addObject: S2AS([array objectAtIndex: ind])];
	}
	
	[_TS_ setMode: S2AS(mode) on: S2AS(obj) withParams: arg
	  onConnection: connection withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandEncoding: (NSString *)command connection: connection
{
	id array;
	id arg = nil;
	NSStringEncoding enc = 0;
	id temp;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 2];
	
	if ([array count] > 0)
	{
		arg = [array objectAtIndex: 0];
		arg = [arg lowercaseString];
	}
	
	if (arg) enc = (NSStringEncoding)NSMapGet(encodings, arg);
	
	if (!enc)
	{
		temp = NSAllMapTableKeys(encodings);
		return BuildAttributedString(_(@"Usage: /encoding <encoding>"), @"\n", 
		  _(@"Available encodings: "), [temp componentsJoinedByString: @", "], @"\n",
		  _(@"Current encoding: "), StringFromEncoding([connection encoding]), nil);
	}
	
	[connection setEncoding: enc];
	
	return S2AS(_(@"Ok."));
}
- (void)setupCommandList
{
#define ADD_COMMAND(_sel, _name) { id invoc; \
	invoc = [NSInvocation invocationWithMethodSignature: \
	  [self methodSignatureForSelector: \
	  (_sel)]]; \
	[invoc retainArguments];\
	[invoc setSelector: (_sel)];\
	[invoc setTarget: self];\
	[self addCommand: (_name) withInvocation: invoc];}

	ADD_COMMAND(@selector(commandLoad:connection:), @"load");
	ADD_COMMAND(@selector(commandUnload:connection:), @"unload");
	ADD_COMMAND(@selector(commandLoaded:connection:), @"loaded");
	ADD_COMMAND(@selector(commandSaveLoaded:connection:), @"saveloaded");
	ADD_COMMAND(@selector(commandJoin:connection:), @"join");
	ADD_COMMAND(@selector(commandMsg:connection:), @"msg");
	ADD_COMMAND(@selector(commandPart:connection:), @"part");
	ADD_COMMAND(@selector(commandNotice:connection:), @"notice");
	ADD_COMMAND(@selector(commandAway:connection:), @"away");
	ADD_COMMAND(@selector(commandQuit:connection:), @"quit");
	ADD_COMMAND(@selector(commandColors:connection:), @"colors");
	ADD_COMMAND(@selector(commandCtcp:connection:), @"ctcp");
	ADD_COMMAND(@selector(commandVersion:connection:), @"version");
	ADD_COMMAND(@selector(commandClientinfo:connection:), @"clientinfo");
	ADD_COMMAND(@selector(commandUserinfo:connection:), @"userinfo");
	ADD_COMMAND(@selector(commandPing:connection:), @"ping");
	ADD_COMMAND(@selector(commandTopic:connection:), @"topic");
	ADD_COMMAND(@selector(commandKick:connection:), @"kick");
	ADD_COMMAND(@selector(commandRaw:connection:), @"raw");
	ADD_COMMAND(@selector(commandMode:connection:), @"mode");
	ADD_COMMAND(@selector(commandEncoding:connection:), @"encoding");
	
#undef ADD_COMMAND
}
@end

#undef MARK

