/***************************************************************************
                                IRCObject.m
                          -------------------
    begin                : Thu May 30 22:06:25 UTC 2002
    copyright            : (C) 2002 by Andy Ruder
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

#import "NetBase.h"
#import "NetTCP.h"
#import "IRCObject.h"

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSData.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSProcessInfo.h>

#include <string.h>

NSString *IRCException = @"IRCException";

static NSMapTable *command_to_function = 0;
static NSMapTable *ctcp_to_function = 0;

static NSData *IRC_new_line = nil;

@interface IRCObject (InternalIRCObject)
- setNick: (NSString *)aNick;
- setErrorString: (NSString *)anError;
@end

#define REMOVE_SPACES(__buffer, __bufferEnd)\
while (*__buffer == ' ') {\
	__buffer++;\
	if (__buffer == __bufferEnd) {\
		*offset = -1;\
		return nil;\
	}\
}

static inline NSString *get_IRC_prefix(NSData *data, int *offset)
{
	const char *memBegin = [data bytes];
	const char *mem = memBegin;
	const char *memEnd = mem + [data length];
	const char *temp;
	
	REMOVE_SPACES(mem, memEnd);

	if (*mem != ':')
	{
		return nil;
	}
	mem++;
	
	temp = memchr(mem, ' ', memEnd - mem);

	if (temp == 0)
	{
		*offset = -1;
		return nil;
	}
	
	*offset = temp - memBegin;
	return [NSString stringWithCString: mem length: temp - mem];
}
	
static inline NSString *get_next_IRC_word(NSData *data, int *offset)
{
	const char *memBegin = [data bytes];
	const char *mem = memBegin;
	const char *memEnd = mem + [data length];
	const char *temp;
	
	mem += *offset;

	REMOVE_SPACES(mem, memEnd);

	if (*mem == ':')
	{
		*offset = -1;
		mem++;
		return [NSString stringWithCString: mem length: memEnd - mem];
	}

	temp = memchr(mem, ' ', memEnd - mem);
	
	if (!temp)
	{
		*offset = -1;
		return [NSString stringWithCString: mem length: memEnd - mem];
	}

	*offset = temp - memBegin;
	return [NSString stringWithCString: mem length: temp - mem];
}

#undef REMOVE_SPACES

static inline BOOL is_numeric_command(NSString *aString)
{
	char *marker;
	
	if ([aString length] != 3)
	{
		return NO;
	}
	
	strtol([aString cString], &marker, 0);

	return (*marker == '\0') ? YES : NO;
}

static inline BOOL contains_a_space(NSString *aString)
{
	return (strchr([aString cString], ' ')) ? YES : NO;
}	

static inline NSString *string_to_character(NSString *aString, int c)
{
	const char *temp = [aString cString];
	const char *test;

	if (!aString)
	{
		return nil;
	}

	test = strchr(temp, c);

	if (!test)
	{
		return aString;
	}
	
	return [NSString stringWithCString: temp length: test - temp];
}

inline NSString *ExtractIRCNick(NSString *prefix)
{	
	const char *temp = [prefix cString];
	const char *test;

	if (!prefix)
	{
		return nil;
	}

	test = strchr(temp, '!');

	if (!test)
	{
		return prefix;
	}

	return [NSString stringWithCString: temp length: test - temp];
}

inline NSString *ExtractIRCHost(NSString *prefix)
{
	const char *temp = [prefix cString];
	const char *test;

	if (!prefix)
	{
		return nil;
	}

	test = strchr(temp, '!');

	if (!test)
	{
		return nil;
	}

	return [NSString stringWithCString: test + 1];
}

inline NSArray *SeparateIRCNickAndHost(NSString *prefix)
{
	const char *temp = [prefix cString];
	const char *test;

	if (!prefix)
	{
		return nil;
	}

	test = strchr(temp, '!');

	if (!test)
	{
		return [NSArray arrayWithObject: prefix];
	}

	return [NSArray arrayWithObjects: 
	 [NSString stringWithCString: temp length: test - temp],
	 [NSString stringWithCString: temp + 1],
	 nil];
}

static void rec_caction(IRCObject *client, NSString *prefix,
                        NSString *command, NSString *rest, NSString *to)
{
	if ([rest length] == 0)
	{
		return;
	}
	[client actionReceived: rest to: to from: prefix];
}
static void rec_cversion(IRCObject *client, NSString *prefix,
                         NSString *command, NSString *rest, NSString *to)
{
	if ([command isEqualToString: @"NOTICE"])
	{
		[client versionReplyReceived: rest from: prefix];
	}
	else
	{
		[client versionRequestReceived: rest from: prefix];
	}
}
static void rec_cping(IRCObject *client, NSString *prefix,
                      NSString *command, NSString *rest, NSString *to)
{
	if ([command isEqualToString: @"NOTICE"])
	{
		[client pingReplyReceived: rest from: prefix];
	}
	else
	{
		[client pingRequestReceived: rest from: prefix];
	}
}
static void rec_cclientinfo(IRCObject *client, NSString *prefix,
                            NSString *command, NSString *rest, NSString *to)
{
	if ([command isEqualToString: @"NOTICE"])
	{
		[client clientInfoReplyReceived: rest from: prefix];
	}
	else
	{
		[client clientInfoRequestReceived: rest from: prefix];
	}
}
static void rec_cuserinfo(IRCObject *client, NSString *prefix,
                            NSString *command, NSString *rest, NSString *to)
{
	if ([command isEqualToString: @"NOTICE"])
	{
		[client userInfoReplyReceived: rest from: prefix];
	}
	else
	{
		[client userInfoRequestReceived: rest from: prefix];
	}
}
static void rec_nick(IRCObject *client, NSString *command,
                     NSString *prefix, NSArray *paramList)
{
	if (!prefix)
	{
		return;
	}
		
	if ([paramList count] < 1)
	{
		return;
	}
	
	if ([ExtractIRCNick(prefix) caseInsensitiveCompare: [client nick]] 
	      == NSOrderedSame)
	{
		[client setNick: [paramList objectAtIndex: 0]];
	}

	[client nickChangedTo: [paramList objectAtIndex: 0] from: prefix];
}

static void rec_join(IRCObject *client, NSString *command, 
                     NSString *prefix, NSArray *paramList)
{
	if (!prefix)
	{
		return;
	}

	if ([paramList count] == 0)
	{
		return;
	}

	[client channelJoined: [paramList objectAtIndex: 0] from: prefix];
}

static void rec_part(IRCObject *client, NSString *command,
                     NSString *prefix, NSArray *paramList)
{
	int x;
	
	if (!prefix)
	{	
		return;
	}

	x = [paramList count];
	if (x == 0)
	{
		return;
	}

	[client channelParted: [paramList objectAtIndex: 0] withMessage:
	  (x == 2) ? [paramList objectAtIndex: 1] : 0 from: prefix];
}

static void rec_quit(IRCObject *client, NSString *command,
                     NSString *prefix, NSArray *paramList)
{
	if (!prefix)
	{
		return;
	}

	if ([paramList count] == 0)
	{
		return;
	}

	[client quitIRCWithMessage: [paramList objectAtIndex: 0] from: prefix];
}

static void rec_topic(IRCObject *client, NSString *command,
                      NSString *prefix, NSArray *paramList)
{
	if (!prefix)
	{
		return;
	}

	if ([paramList count] < 2)
	{
		return;
	}

	[client topicChangedTo: [paramList objectAtIndex: 1] 
	  in: [paramList objectAtIndex: 0] from: prefix];
}
static void rec_privmsg(IRCObject *client, NSString *command,
                        NSString *prefix, NSArray *paramList)
{
	id message;
	
	if (!prefix)
	{
		return;
	}

	if ([paramList count] < 2)
	{
		return;
	}

	message = [paramList objectAtIndex: 1];
	if ([message hasPrefix: @"\001"])
	{
		void (*func)(IRCObject *, NSString *, NSString *, NSString *, 
		              NSString *);
		id ctcp = string_to_character(message, ' ');
		id rest;
		
		if ([ctcp isEqualToString: message])
		{
			if ([ctcp hasSuffix: @"\001"])
			{
				ctcp = [ctcp substringToIndex: [ctcp length] - 1];
			}
			rest = nil;
		}
		else
		{
			NSRange aRange;
			aRange.location = [ctcp length] + 1;
			aRange.length = [message length] - aRange.location;
			
			if ([message hasSuffix: @"\001"])
			{
				aRange.length--;
			}
			
			if (aRange.length > 0)
			{
				rest = [message substringWithRange: aRange];
			}
			else
			{
				rest = nil;
			}
		}	
		func = NSMapGet(ctcp_to_function, ctcp);
		
		if (func)
		{
			func(client, prefix, command, rest, [paramList objectAtIndex: 0]);
		}
		
		return;
	}
	
	if ([command isEqualToString: @"PRIVMSG"])
	{
		[client messageReceived: message
		   to: [paramList objectAtIndex: 0] from: prefix];
	}
	else
	{
		[client noticeReceived: message
		   to: [paramList objectAtIndex: 0] from: prefix];
	}
}
static void rec_mode(IRCObject *client, NSString *command, NSString *prefix, 
                     NSArray *paramList)
{
	NSArray *newParams;
	int x;
	
	if (!prefix)
	{
		return;
	}
	
	x = [paramList count];
	if (x < 2)
	{	
		return;
	}

	if (x == 2)
	{
		newParams = AUTORELEASE([NSArray new]);
	}
	else
	{
		NSRange aRange;
		aRange.location = 2;
		aRange.length = x - 2;
		
		newParams = [paramList subarrayWithRange: aRange];
	}
	
	[client modeChanged: [paramList objectAtIndex: 1] 
	  on: [paramList objectAtIndex: 0] withParams: newParams from: prefix];
}
static void rec_invite(IRCObject *client, NSString *command, NSString *prefix, 
                     NSArray *paramList)
{
	if (!prefix)
	{
		return;
	}
	if ([paramList count] < 2)
	{
		return;
	}

	[client invitedTo: [paramList objectAtIndex: 1] from: prefix];
}
static void rec_kick(IRCObject *client, NSString *command, NSString *prefix,
                       NSArray *paramList)
{
	id object;
	
	if (!prefix)
	{
		return;
	}
	if ([paramList count] < 2)
	{
		return;
	}
	
	object = ([paramList count] > 2) ? [paramList objectAtIndex: 2] : nil;
	
	[client userKicked: [paramList objectAtIndex: 1]
	   outOf: [paramList objectAtIndex: 0] for: object from: prefix];
}
static void rec_ping(IRCObject *client, NSString *command, NSString *prefix,
                       NSArray *paramList)
{
	if ([paramList count] < 1)
	{
		return;
	}
	
	[client writeString: @"PONG %@", [paramList objectAtIndex: 0]];
}
static void rec_wallops(IRCObject *client, NSString *command, NSString *prefix,
                          NSArray *paramList)
{
	if (!prefix)
	{
		return;
	}
	if ([paramList count] < 1)
	{
		return;
	}
	
	[client wallopsReceived: [paramList objectAtIndex: 0] from: prefix];
}
static void rec_error(IRCObject *client, NSString *command, NSString *prefix,
                        NSArray *paramList)
{
	if ([paramList count] < 1)
	{
		return;
	}

	[client errorReceived: [paramList objectAtIndex: 0]];
}


@implementation IRCObject (InternalIRCObject)
- setNick: (NSString *)aNick
{
	RELEASE(nick);
	nick = RETAIN(aNick);
	return self;
}
- setErrorString: (NSString *)anError
{
	RELEASE(errorString);
	errorString = RETAIN(anError);
	return self;
}
@end

@implementation IRCObject
+ (void)initialize
{
	IRC_new_line = [[NSData alloc] initWithBytes: "\r\n" length: 2];

	command_to_function = NSCreateMapTable(NSObjectMapKeyCallBacks,
	   NSIntMapValueCallBacks, 13);
	
	NSMapInsert(command_to_function, @"NICK", rec_nick);
	NSMapInsert(command_to_function, @"JOIN", rec_join);
	NSMapInsert(command_to_function, @"PART", rec_part);
	NSMapInsert(command_to_function, @"QUIT", rec_quit);
	NSMapInsert(command_to_function, @"TOPIC", rec_topic);
	NSMapInsert(command_to_function, @"PRIVMSG", rec_privmsg);
	NSMapInsert(command_to_function, @"NOTICE", rec_privmsg);
	NSMapInsert(command_to_function, @"MODE", rec_mode);
	NSMapInsert(command_to_function, @"KICK", rec_kick);
	NSMapInsert(command_to_function, @"INVITE", rec_invite);
	NSMapInsert(command_to_function, @"PING", rec_ping);
	NSMapInsert(command_to_function, @"WALLOPS", rec_wallops);
	NSMapInsert(command_to_function, @"ERROR", rec_error);

	ctcp_to_function = NSCreateMapTable(NSObjectMapKeyCallBacks,
	   NSIntMapValueCallBacks, 5);
	
	NSMapInsert(ctcp_to_function, @"\001ACTION", rec_caction);
	NSMapInsert(ctcp_to_function, @"\001VERSION", rec_cversion);
	NSMapInsert(ctcp_to_function, @"\001PING", rec_cping);
	NSMapInsert(ctcp_to_function, @"\001USERINFO", rec_cuserinfo);
	NSMapInsert(ctcp_to_function, @"\001CLIENTINFO", rec_cclientinfo);
}
- initWithNicknames: (NSArray *)nicknames withUserName: (NSString *)user
   withRealName: (NSString *)realName
   withPassword: (NSString *)password
{
	NSEnumerator *iter = [nicknames objectEnumerator];
	NSMutableArray *array = AUTORELEASE([NSMutableArray new]);
	id object;

	if (!(self = [super init])) return nil;
	
	if ([nicknames count] == 0)
	{
		[self setErrorString: @"No nicknames provided"];
		[self dealloc];
		return nil;
	}
	
	while ((object = [iter nextObject]))
	{
		object = string_to_character(object, ' ');
		if ([object length] == 0)
		{
			continue;
		}
		[array addObject: object];
	}
	
	if ([array count] == 0)
	{
		[self setErrorString: @"No usable nicknames provided"];
		[self dealloc];
		return nil;
	}
	
	if ([password length])
	{
		if (contains_a_space(password))
		{
			[self setErrorString: @"Password contains a space"];
			[self dealloc];
			return nil;
		}
	}
	else
	{
		password = nil;
	}
	
	if ([user length] == 0)
	{
		id enviro;
		enviro = [[NSProcessInfo processInfo] environment];

		user = [enviro objectForKey: @"LOGNAME"];
		
		if ([user length] == 0)
		{
			user = @"netclasses";
		}
	}
	if ([(user = string_to_character(user, ' ')) length] == 0)
	{
		user = @"netclasses";
	}

	if ([realName length] == 0)
	{
		realName = @"John Doe";
	}
	
	if (password)
	{
		passwordString = [[NSString alloc] initWithFormat: @"PASS %@", 
		  password];
	}
	
	initialNicknames = [[NSArray alloc] initWithArray: array];
	
	userString = [[NSString alloc] initWithFormat:
	 @"USER %@ %@ %@ :%@", user, @"localhost", @"netclasses", realName];
	
	return self;
}		  
- (void)dealloc
{
	DESTROY(initialNicknames);
	DESTROY(userString);
	DESTROY(passwordString);
	DESTROY(errorString);
	[super dealloc];
}
- (NSString *)errorString
{
	return errorString;
}
- connectionEstablished: aTransport
{
	id object;
	[super connectionEstablished: aTransport];
	
	[self writeString: passwordString];
	object = [initialNicknames objectAtIndex: 0];

	[self setNick: object];
	[self changeNick: object];

	[self writeString: userString];
	return self;
}
- (void)connectionLost
{
	DESTROY(nick);
	[super connectionLost];
}
- (BOOL)connected
{
	return connected;
}
- (NSString *)nick
{
	return nick;
}
- changeNick: (NSString *)aNick
{
	if ([aNick length] > 0)
	{
		if (contains_a_space(aNick))
		{
			[NSException raise: IRCException
			 format: @"[IRCObject changeNick: '%@'] Nickname contains a space",
			  aNick];
		}
					
		[self writeString: @"NICK %@", aNick];
	}
	return self;
}
- quitWithMessage: (NSString *)aMessage
{
	if ([aMessage length] > 0)
	{
		[self writeString: @"QUIT :%@", aMessage];
	}
	else
	{
		[self writeString: @"QUIT"];
	}
	return self;
}
- partChannel: (NSString *)channel withMessage: (NSString *)aMessage
{
	if ([channel length] == 0)
	{
		return self;
	}
	
	if (contains_a_space(channel))
	{
		[NSException raise: IRCException
		 format: @"[IRCObject partChannel: '%@' ...] Channel contains a space",
		  channel];
	}
	
	if ([aMessage length] > 0)
	{
		[self writeString: @"PART %@ :%@", channel, aMessage];
	}
	else
	{
		[self writeString: @"PART %@", channel];
	}
	
	return self;
}
- joinChannel: (NSString *)channel withPassword: (NSString *)aPassword
{
	if ([channel length] == 0)
	{
		return self;
	}

	if (contains_a_space(channel))
	{
		[NSException raise: IRCException
		 format: @"[IRCObject joinChannel: '%@' ...] Channel contains a space",
		  channel];
	}

	if ([aPassword length] == 0)
	{
		[self writeString: @"JOIN %@", channel];
		return self;
	}

	if (contains_a_space(aPassword))
	{
		[NSException raise: IRCException
		 format: @"[IRCObject joinChannel: withPassword: '%@'] Password contains a space.",
		  aPassword];
	}

	[self writeString: @"JOIN %@ %@", channel, aPassword];

	return self;
}
- sendVersionReplyTo: (NSString *)aPerson name:(NSString *)clientName
    version: (NSString *)clientVersion environment: (NSString *)clientEnv
{
	if ([clientName length] == 0)
	{	
		return self;
	}
	if ([clientVersion length] == 0)
	{
		return self;
	}
	if ([clientEnv length] == 0)
	{
		return self;
	}
	if ([aPerson length] == 0)
	{
		return self;
	}
	if (contains_a_space(aPerson))
	{
		[NSException raise: IRCException format: 
		 @"[IRCObject sendVersionReplyTo: '%@' name: '%@' version: '%@' environment: '%@'] Person contains a space",
		  aPerson, clientName, clientVersion, clientEnv];
	}
	
	[self writeString: @"NOTICE %@ :\001VERSION %@ %@ %@\001",
	 aPerson, clientName, clientVersion, clientEnv];
	return self;
}
- sendPingReplyTo: (NSString *)aPerson withArgument: (NSString *)argument
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if ([argument length] == 0)
	{
		return self;
	}
	if (contains_a_space(aPerson))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject sendPingReplyTo: '%@' withArgument: '%@'] Person contains a space",
		  aPerson, argument];
	}

	[self writeString: @"NOTICE %@ :\001PING %@\001", aPerson, argument];
	return self;
}
- sendClientInfo: (NSString *)clientInfo to: (NSString *)aPerson
{
	if ([clientInfo length] == 0)
	{
		return self;
	}
	if ([aPerson length] == 0)
	{
		return self;
	}
	if (contains_a_space(aPerson))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject sendClientInfo: '%@' to: '%@'] Person contains a space",
		  clientInfo, aPerson];
	}

	[self writeString: @"NOTICE %@ :\001CLIENTINFO %@\001", 
	  aPerson, clientInfo];

	return self;
}
- sendUserInfo: (NSString *)userInfo to: (NSString *)aPerson
{
	if ([userInfo length] == 0)
	{
		return self;
	}
	if ([aPerson length] == 0)
	{
		 return self;
	}
	if (contains_a_space(aPerson))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject sendUserInfo: '%@' to: '%@'] Person contains a space",
		  userInfo, aPerson];
	}

	[self writeString: @"NOTICE %@ :\001USERINFO %@\001",
	 aPerson, userInfo];
	
	return self;
}
- sendMessage: (NSString *)message to: (NSString *)receiver
{
	if ([message length] == 0)
	{
		return self;
	}
	if ([receiver length] == 0)
	{
		return self;
	}
	if (contains_a_space(receiver))
	{
		[NSException raise: IRCException
		 format: @"[IRCObject sendMessage: '%@' to: '%@'] The receiver contains a space.",
		  message, receiver];
	}
	
	[self writeString: @"PRIVMSG %@ :%@", receiver, message];
	
	return self;
}
- sendNotice: (NSString *)message to: (NSString *)receiver
{
	if ([message length] == 0)
	{
		return self;
	}
	if ([receiver length] == 0)
	{
		return self;
	}
	if (contains_a_space(receiver))
	{
		[NSException raise: IRCException
		 format: @"[IRCObject sendNotice: '%@' to: '%@'] The receiver contains a space.",
		  message, receiver];
	}
	
	[self writeString: @"NOTICE %@ :%@", receiver, message];
	
	return self;
}
- sendAction: (NSString *)anAction to: (NSString *)receiver
{
	if ([anAction length] == 0)
	{
		return self;
	}
	if ([receiver length] == 0)
	{
		return self;
	}
	if (contains_a_space(receiver))
	{
		[NSException raise: IRCException
		 format: @"[IRCObject sendAction: '%@' to: '%@'] The receiver contsins a space.",
		   anAction, receiver];
	}

	[self writeString: @"PRIVMSG %@ :\001ACTION %@\001", receiver, anAction];
	
	return self;
}
- becomeOperatorWithName: (NSString *)aName withPassword: (NSString *)pass
{
	if (([aName length] == 0) || ([pass length] == 0))
	{
		return self;
	}
	if (contains_a_space(pass))
	{
		[NSException raise: IRCException
		 format: @"[IRCObject becomeOperatorWithName: %@ withPassword: %@] The password contains a space.",
		  aName, pass];
	}
	if (contains_a_space(aName))
	{
		[NSException raise: IRCException
		 format: @"[IRCObject becomeOperatorWithName: %@ withPassword: %@] The name contains a space.",
		  aName, pass];
	}
	
	[self writeString: @"OPER %@ %@", aName, pass];
	
	return self;
}
- requestNamesOnChannel: (NSString *)aChannel fromServer: (NSString *)aServer
{
	if ([aChannel length] == 0)
	{
		[self writeString: @"NAMES"];
		return self;
	}
	
	if (contains_a_space(aChannel))
	{
		[NSException raise: IRCException
		 format: 
		  @"[IRCObject requestNamesOnChannel: %@ fromServer: %@] The channel contains a space.",
		   aChannel, aServer];
	}
			
	if ([aServer length] == 0)
	{
		[self writeString: @"NAMES %@", aChannel];
		return self;
	}

	if (contains_a_space(aServer))
	{
		[NSException raise: IRCException
		 format: @"[IRCObject requestNamesOnChannel: %@ fromServer: %@] The server contains a space.",
		   aChannel, aServer];
	}
		
	[self writeString: @"NAMES %@ %@", aChannel, aServer];
	return self;
}
- requestMOTDOnServer: (NSString *)aServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"MOTD"];
		return self;
	}
	if (contains_a_space(aServer))
	{
		[NSException raise: IRCException format: 
		  @"[IRCObject requestMOTDOnServer:'%@'] Server contains a space",
		  aServer];
	}

	[self writeString: @"MOTD %@", aServer];
	return self;
}
- requestSizeInformationFromServer: (NSString *)aServer 
    andForwardTo: (NSString *)anotherServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"LUSERS"];
		return self;
	}
	if (contains_a_space(aServer))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestSizeInformationFromServer: '%@' andForwardTo: '%@'] First argument contains a space", 
		  aServer, anotherServer];
	}
	if ([anotherServer length] == 0)
	{
		[self writeString: @"LUSERS %@", aServer];
		return self;
	}
	if (contains_a_space(anotherServer))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestSizeInformationFromServer: '%@' andForwardTo: '%@'] Second argument contains a space",
		 aServer, anotherServer];
	}

	[self writeString: @"LUSERS %@ %@", aServer, anotherServer];
	return self;
}	
- requestVersionOfServer: (NSString *)aServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"VERSION"];
		return self;
	}
	if (contains_a_space(aServer))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestVersionOfServer: '%@'] Server contains a space",
		  aServer];
	}

	[self writeString: @"VERSION %@", aServer];
	return self;
}
- requestServerStats: (NSString *)aServer for: (NSString *)query
{
	if ([query length] == 0)
	{
		[self writeString: @"STATS"];
		return self;
	}
	if (contains_a_space(query))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerStats: '%@' for: '%@'] Query contains a space",
		  aServer, query];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"STATS %@", query];
		return self;
	}
	if (contains_a_space(aServer))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerStats: '%@' for: '%@'] Server contains a space",
		  aServer, query];
	}
	
	[self writeString: @"STATS %@ %@", query, aServer];
	return self;
}
- requestServerLink: (NSString *)aLink from: (NSString *)aServer
{
	if ([aLink length] == 0)
	{
		[self writeString: @"LINKS"];
		return self;
	}
	if (contains_a_space(aLink))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerLink: '%@' from: '%@'] Link contains a space",
		  aLink, aServer];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"LINKS %@", aLink];
		return self;
	}
	if (contains_a_space(aServer))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerLink: '%@' from: '%@'] Server contains a space", 
		  aLink, aServer];
	}

	[self writeString: @"LINKS %@ %@", aServer, aLink];
	return self;
}
- requestTimeOnServer: (NSString *)aServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"TIME"];
		return self;
	}
	if (contains_a_space(aServer))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestTimeOnServer: '%@'] Server contains a space",
		  aServer];
	}

	[self writeString: @"TIME %@", aServer];
	return self;
}
- requestServerToConnect: (NSString *)aServer to: (NSString *)connectServer
                  onPort: (NSString *)aPort
{
	if ([connectServer length] == 0)
	{
		return self;
	}
	if (contains_a_space(connectServer))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerToConnect: '%@' to: '%@' onPort: '%@'] Server to connect to contains a space",
		  aServer, connectServer, aPort];
	}
	if ([aPort length] == 0)
	{
		return self;
	}
	if (contains_a_space(aPort))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerToConnect: '%@' to: '%@' onPort: '%@'] Port contains a space",
		  aServer, connectServer, aPort];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"CONNECT %@ %@", connectServer, aPort];
		return self;
	}
	if (contains_a_space(aServer))
	{
		[NSException raise: IRCException format: 
		 @"[IRCObject requestServerToConnect: '%@' to: '%@' onPort: '%@'] Server contains a space",
		  aServer, connectServer, aPort];
	}
	
	[self writeString: @"CONNECT %@ %@ %@", connectServer, aPort, aServer];
	return self;
}
- requestTraceOnServer: (NSString *)aServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"TRACE"];
		return self;
	}
	if (contains_a_space(aServer))
	{
		[NSException raise: IRCException format: 
		 @"[IRCObject requestTraceOnServer: '%@'] Server contains a space",
		  aServer];
	}
	
	[self writeString: @"TRACE %@", aServer];
	return self;
}
- requestAdministratorOnServer: (NSString *)aServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"ADMIN"];
		return self;
	}
	if (contains_a_space(aServer))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestAdministratorOnServer: '%@'] Server contains a space", 
		  aServer];
	}

	[self writeString: @"ADMIN %@", aServer];
	return self;
}
- requestInfoOnServer: (NSString *)aServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"INFO"];
		return self;
	}
	if (contains_a_space(aServer))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestInfoOnServer: '%@'] Server contains a space",
		  aServer];
	}

	[self writeString: @"INFO %@", aServer];
	return self;
}
- requestServiceListWithMask: (NSString *)aMask ofType: (NSString *)type
{
	if ([aMask length] == 0)
	{
		[self writeString: @"SERVLIST"];
		return self;
	}
	if (contains_a_space(aMask))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServiceListWithMask: '%@' ofType: '%@'] Mask contains a space",
		  aMask, type];
	}
	if ([type length] == 0)
	{
		[self writeString: @"SERVLIST %@", aMask];
		return self;
	}
	if (contains_a_space(type))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServiceListWithMask: '%@' ofType: '%@'] Type contains a space",
		  aMask, type];
	}

	[self writeString: @"SERVLIST %@ %@", aMask, type];
	return self;
}
- requestServerRehash
{
	[self writeString: @"REHASH"];
	return self;
}
- requestServerShutdown
{
	[self writeString: @"DIE"];
	return self;
}
- requestServerRestart
{
	[self writeString: @"RESTART"];
	return self;
}
- requestUserInfoOnServer: (NSString *)aServer
{
	if ([aServer length] == 0)
	{
		[self writeString: @"USERS"];
		return self;
	}
	if (contains_a_space(aServer))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestUserInfoOnServer: '%@'] Server contains a space",
		  aServer];
	}

	[self writeString: @"USERS %@", aServer];
	return self;
}
- areUsersOn: (NSString *)userList
{
	if ([userList length] == 0)
	{
		return self;
	}
	
	[self writeString: @"ISON %@", userList];
	return self;
}
- sendWallops: (NSString *)message
{
	if ([message length] == 0)
	{
		return self;
	}

	[self writeString: @"WALLOPS :%@", message];
	return self;
}
- queryService: (NSString *)aService withMessage: (NSString *)aMessage
{
	if ([aService length] == 0)
	{
		return self;
	}
	if (contains_a_space(aService))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject queryService: '%@' withMessage: '%@'] Service contains a space",
		  aService, aMessage];
	}
	if ([aMessage length] == 0)
	{
		return self;
	}

	[self writeString: @"SQUERY %@ :%@", aService, aMessage];
	return self;
}
- listWho: (NSString *)aMask onlyOperators: (BOOL)operators
{
	if ([aMask length] == 0)
	{
		[self writeString: @"WHO"];
		return self;
	}
	if (contains_a_space(aMask))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject listWho: '%@' onlyOperators: %d] Mask contains a space",
		 aMask, operators];
	}
	
	if (operators)
	{
		[self writeString: @"WHO %@ o", aMask];
	}
	else
	{
		[self writeString: @"WHO %@", aMask];
	}
	
	return self;
}
- whois: (NSString *)aPerson onServer: (NSString *)aServer
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if (contains_a_space(aPerson))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whois: '%@' onServer: '%@'] Person contains a space",
		 aPerson, aServer];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"WHOIS %@", aPerson];
		return self;
	}
	if (contains_a_space(aServer))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whois: '%@' onServer: '%@'] Server contains a space",
		  aPerson, aServer];
	}

	[self writeString: @"WHOIS %@ %@", aServer, aPerson];
	return self;
}
- whowas: (NSString *)aPerson onServer: (NSString *)aServer
      withNumberEntries: (NSString *)aNumber
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if (contains_a_space(aPerson))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whowas: '%@' onServer: '%@' withNumberEntries: '%@'] Person contains a space",
		  aPerson, aServer, aNumber];
	}
	if ([aNumber length] == 0)
	{
		[self writeString: @"WHOWAS %@", aPerson];
		return self;
	}
	if (contains_a_space(aNumber))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whowas: '%@' onServer: '%@' withNumberEntries: '%@'] Number of entries contains a space", 
		  aPerson, aServer, aNumber];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"WHOWAS %@ %@", aPerson, aNumber];
		return self;
	}
	if (contains_a_space(aServer))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whowas: '%@' onServer: '%@' withNumberEntries: '%@'] Server contains a space",
		  aPerson, aServer, aNumber];
	}

	[self writeString: @"WHOWAS %@ %@ %@", aPerson, aNumber, aServer];
	return self;
}
- kill: (NSString *)aPerson withComment: (NSString *)aComment
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if (contains_a_space(aPerson))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject kill: '%@' withComment: '%@'] Person contains a space",
		 aPerson, aComment];
	}
	if ([aComment length] == 0)
	{
		return self;
	}

	[self writeString: @"KILL %@ :%@", aPerson, aComment];
	return self;
}
- setTopicForChannel: (NSString *)aChannel to: (NSString *)aTopic
{
	if ([aChannel length] == 0)
	{
		return self;
	}
	if (contains_a_space(aChannel))
	{
		[NSException raise: IRCException
		 format: @"[IRCObject setTopicForChannel: %@ to: %@] The channel contains a space.",
		   aChannel, aTopic];
	}

	if ([aTopic length] == 0)
	{
		[self writeString: @"TOPIC %@", aChannel];
	}
	else
	{
		[self writeString: @"TOPIC %@ :%@", aChannel, aTopic];
	}

	return self;
}
- setMode: (NSString *)aMode on: (NSString *)anObject 
                     withParams: (NSArray *)list
{
	NSMutableString *aString;
	NSEnumerator *iter;
	id object;
	
	if ([anObject length] == 0)
	{
		return self;
	}
	if (contains_a_space(anObject))
	{
		[NSException raise: IRCException format:
		  @"[IRCObject setMode:'%@' on:'%@' withParams:'%@'] Object contains a space", 
		    aMode, anObject, list];
	}
	if ([aMode length] == 0)
	{
		[self writeString: @"MODE %@", anObject];
		return self;
	}
	if (contains_a_space(aMode))
	{		
		[NSException raise: IRCException format:
		  @"[IRCObject setMode:'%@' on:'%@' withParams:'%@'] Mode contains a space", 
		    aMode, anObject, list];
	}
	if (!list)
	{
		[self writeString: @"MODE %@ %@", anObject, aMode];
		return self;
	}
	
	aString = [NSMutableString stringWithFormat: @"MDOE %@ %@", 
	            anObject, aMode];
				
	iter = [list objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[aString appendString: @" "];
		[aString appendString: object];
	}
	
	[self writeString: @"%@", aString];

	return self;
}
- listChannel: (NSString *)aChannel onServer: (NSString *)aServer
{
	if ([aChannel length] == 0)
	{
		[self writeString: @"LIST"];
		return self;
	}
	if (contains_a_space(aChannel))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject listChannel:'%@' onServer:'%@'] Channel contains a space",
		  aChannel, aServer];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"LIST %@", aChannel];
		return self;
	}
	if (contains_a_space(aChannel))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject listChannel:'%@' onServer:'%@'] Server contains a space",
		  aChannel, aServer];
	}
	
	[self writeString: @"LIST %@ %@", aChannel, aServer];
	return self;
}
- invite: (NSString *)aPerson to: (NSString *)aChannel
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if ([aChannel length] == 0)
	{
		return self;
	}
	if (contains_a_space(aPerson))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject invite:'%@' to:'%@'] Person contains a space",
		  aPerson, aChannel];
	}
	if (contains_a_space(aChannel))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject invite:'%@' to:'%@'] Channel contains a space",
		  aPerson, aChannel];
	}
	
	[self writeString: @"INVITE %@ %@", aPerson, aChannel];
	return self;
}
- kick: (NSString *)aPerson offOf: (NSString *)aChannel for: (NSString *)reason
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if ([aChannel length] == 0)
	{
		return self;
	}
	if (contains_a_space(aPerson))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject kick:'%@' offOf:'%@' for:'%@'] Person contains a space",
		  aPerson, aChannel, reason];
	}
	if (contains_a_space(aChannel))
	{
		[NSException raise: IRCException format:
		 @"[IRCObject kick:'%@' offOf:'%@' for:'%@'] Channel contains a space",
		  aPerson, aChannel, reason];
	}
	if ([reason length] == 0)
	{
		[self writeString: @"KICK %@ %@", aPerson, aChannel];
		return self;
	}

	[self writeString: @"KICK %@ %@ :%@", aPerson, aChannel, reason];
	return self;
}
- setAwayWithMessage: (NSString *)message
{
	if ([message length] == 0)
	{
		[self writeString: @"AWAY"];
		return self;
	}

	[self writeString: @"AWAY :%@", message];
	return self;
}
- registeredWithServer
{
	return self;
}
- couldNotRegister: (NSString *)reason
{
	return self;
}	
- versionReplyReceived: (NSString *)versionInfo from: (NSString *)aPerson
{
	return self;
}
- versionRequestReceived: (NSString *)query from: (NSString *)aPerson
{
	return self;
}
- pingReplyReceived: (NSString *)argument from: (NSString *)aPerson
{
	return self;
}
- pingRequestReceived: (NSString *)argument from: (NSString *)aPerson
{
	return self;
}
- clientInfoReplyReceived: (NSString *)clientInfo from: (NSString *)aPerson
{
	return self;
}
- clientInfoRequestReceived: (NSString *)query from: (NSString *)aPerson
{
	return self;
}
- userInfoReplyReceived: (NSString *)userInfo from: (NSString *)aPerson
{
	return self;
}
- userInfoRequestReceived: (NSString *)query from: (NSString *)aPerson
{
	return self;
}
- errorReceived: (NSString *)anError
{
	return self;
}
- wallopsReceived: (NSString *)message from: (NSString *)sender
{
	return self;
}
- userKicked: (NSString *)aPerson outOf: (NSString *)aChannel 
         for: (NSString *)reason from: (NSString *)kicker
{
	return self;
}
- invitedTo: (NSString *)aChannel from: (NSString *)anInviter
{
	return self;
}
- modeChanged: (NSString *)mode on: (NSString *)anObject 
    withParams: (NSArray *)paramList from: (NSString *)aPerson
{
	return self;
}
- numericCommandReceived: (NSString *)command withParams: (NSArray *)paramList 
    from: (NSString *)sender
{
	return self;
}
- nickChangedTo: (NSString *)newName from: (NSString *)aPerson
{
	return self;
}
- channelJoined: (NSString *)channel from: (NSString *)joiner
{
	return self;
}
- channelParted: (NSString *)channel withMessage: (NSString *)aMessage
             from: (NSString *)parter
{
	return self;
}
- quitIRCWithMessage: (NSString *)aMessage from: (NSString *)quitter
{
	return self;
}
- topicChangedTo: (NSString *)aTopic in: (NSString *)channel
              from: (NSString *)aPerson
{
	return self;
}
- messageReceived: (NSString *)aMessage to: (NSString *)to
               from: (NSString *)sender
{
	return self;
}
- noticeReceived: (NSString *)aMessage to: (NSString *)to
              from: (NSString *)sender
{
	return self;
}
- actionReceived: (NSString *)anAction to: (NSString *)to
              from: (NSString *)sender
{
	return self;
}
- lineReceived: (NSData *)aLine
{
	NSString *prefix = nil;
	NSString *command = nil;
	NSMutableArray *paramList = nil;
	int offset = 0;
	id object;
	void (*function)(IRCObject *, NSString *, NSString *, NSArray *);

	if ([aLine length] == 0)
	{
		return self;
	}
	paramList = AUTORELEASE([NSMutableArray new]);
	
	prefix = get_IRC_prefix(aLine, &offset);
	if (offset == -1)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject lineReceived: '@'] Line ended prematurely.",
		 [NSString stringWithCString: [aLine bytes] length: [aLine length]]];
	}

	command = get_next_IRC_word(aLine, &offset);
	if (command == nil)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject lineReceived: '@'] Line ended prematurely.",
		 [NSString stringWithCString: [aLine bytes] length: [aLine length]]];
	}

	while (offset != -1)
	{
		object = get_next_IRC_word(aLine, &offset);
		if (!object)
		{
			break;
		}
		[paramList addObject: object];
	}

	if (!connected)
	{
		if ([command isEqualToString: ERR_ERRONEUSNICKNAME] || 
		    [command isEqualToString: ERR_NEEDMOREPARAMS] ||
			[command isEqualToString: ERR_ALREADYREGISTRED] ||
			[command isEqualToString: ERR_NONICKNAMEGIVEN] ||
			[command isEqualToString: ERR_NICKCOLLISION])
		{
			[[NetApplication sharedInstance] disconnectObject: self];
			[self couldNotRegister: [NSString stringWithFormat:
			 @"%@ %@ %@", prefix, command, paramList]];
			return nil;
		}
		else if ([command isEqualToString: ERR_NICKNAMEINUSE])
		{
			int actualIndex = ((++nicknameIndex) >= [initialNicknames count]) ? 
			                  0 : nicknameIndex;
			int underscores = (actualIndex == 0) ? nicknameIndex : 0;
			
			nick = RETAIN([initialNicknames objectAtIndex: actualIndex]);
			
			if (underscores > 0)
			{
				char *buffer = malloc(underscores);
				memset(buffer, '_', underscores);
				
				AUTORELEASE(nick);
				nick = RETAIN([nick stringByAppendingString:
				 [NSString stringWithCString: buffer length: underscores]]);

				free(buffer);
			}

			[self changeNick: nick];
			return self;
		}
		else if ([command isEqualToString: RPL_WELCOME])
		{
			connected = YES;
			[self registeredWithServer];
		}
	}
	
	if (is_numeric_command(command))
	{		
		if ([paramList count] >= 2)
		{
			NSRange aRange;

			aRange.location = 1;
			aRange.length = [paramList count] - 1;
		
			[self numericCommandReceived: command 
			  withParams: [paramList subarrayWithRange: aRange]
			  from: prefix];
		}	
	}
	else
	{
		function = NSMapGet(command_to_function, command);
		if (function != 0)
		{
			function(self, command, prefix, paramList);
		}
		else
		{
			NSLog(@"Could not handle :%@ %@ %@", prefix, command, paramList);
		}
	}
	return self;
}
- writeString: (NSString *)format, ...
{
	NSString *temp;
	va_list ap;

	va_start(ap, format);
	temp = [NSString stringWithFormat: format arguments: ap];

	[transport writeData: [NSData dataWithBytes: [temp cString]
	                                     length: [temp cStringLength]]];
	
	if (![temp hasSuffix: @"\r\n"])
	{
		[transport writeData: IRC_new_line];
	}
	return self;
}
@end

NSString *RPL_WELCOME = @"001";
NSString *RPL_YOURHOST = @"002";
NSString *RPL_CREATED = @"003";
NSString *RPL_MYINFO = @"004";
NSString *RPL_BOUNCE = @"005";
NSString *RPL_USERHOST = @"302";
NSString *RPL_ISON = @"303";
NSString *RPL_AWAY = @"301";
NSString *RPL_UNAWAY = @"305";
NSString *RPL_NOWAWAY = @"306";
NSString *RPL_WHOISUSER = @"311";
NSString *RPL_WHOISSERVER = @"312";
NSString *RPL_WHOISOPERATOR = @"313";
NSString *RPL_WHOISIDLE = @"317";
NSString *RPL_ENDOFWHOIS = @"318";
NSString *RPL_WHOISCHANNELS = @"319";
NSString *RPL_WHOWASUSER = @"314";
NSString *RPL_ENDOFWHOWAS = @"369";
NSString *RPL_LISTSTART = @"321";
NSString *RPL_LIST = @"322";
NSString *RPL_LISTEND = @"323";
NSString *RPL_UNIQOPIS = @"325";
NSString *RPL_CHANNELMODEIS = @"324";
NSString *RPL_NOTOPIC = @"331";
NSString *RPL_TOPIC = @"332";
NSString *RPL_INVITING = @"341";
NSString *RPL_SUMMONING = @"342";
NSString *RPL_INVITELIST = @"346";
NSString *RPL_ENDOFINVITELIST = @"347";
NSString *RPL_EXCEPTLIST = @"348";
NSString *RPL_ENDOFEXCEPTLIST = @"349";
NSString *RPL_VERSION = @"351";
NSString *RPL_WHOREPLY = @"352";
NSString *RPL_ENDOFWHO = @"315";
NSString *RPL_NAMREPLY = @"353";
NSString *RPL_ENDOFNAMES = @"366";
NSString *RPL_LINKS = @"364";
NSString *RPL_ENDOFLINKS = @"365";
NSString *RPL_BANLIST = @"367";
NSString *RPL_ENDOFBANLIST = @"368";
NSString *RPL_INFO = @"371";
NSString *RPL_ENDOFINFO = @"374";
NSString *RPL_MOTDSTART = @"375";
NSString *RPL_MOTD = @"372";
NSString *RPL_ENDOFMOTD = @"376";
NSString *RPL_YOUREOPER = @"381";
NSString *RPL_REHASHING = @"382";
NSString *RPL_YOURESERVICE = @"383";
NSString *RPL_TIME = @"391";
NSString *RPL_USERSSTART = @"392";
NSString *RPL_USERS = @"393";
NSString *RPL_ENDOFUSERS = @"394";
NSString *RPL_NOUSERS = @"395";
NSString *RPL_TRACELINK = @"200";
NSString *RPL_TRACECONNECTING = @"201";
NSString *RPL_TRACEHANDSHAKE = @"202";
NSString *RPL_TRACEUNKNOWN = @"203";
NSString *RPL_TRACEOPERATOR = @"204";
NSString *RPL_TRACEUSER = @"205";
NSString *RPL_TRACESERVER = @"206";
NSString *RPL_TRACESERVICE = @"207";
NSString *RPL_TRACENEWTYPE = @"208";
NSString *RPL_TRACECLASS = @"209";
NSString *RPL_TRACERECONNECT = @"210";
NSString *RPL_TRACELOG = @"261";
NSString *RPL_TRACEEND = @"262";
NSString *RPL_STATSLINKINFO = @"211";
NSString *RPL_STATSCOMMANDS = @"212";
NSString *RPL_ENDOFSTATS = @"219";
NSString *RPL_STATSUPTIME = @"242";
NSString *RPL_STATSOLINE = @"243";
NSString *RPL_UMODEIS = @"221";
NSString *RPL_SERVLIST = @"234";
NSString *RPL_SERVLISTEND = @"235";
NSString *RPL_LUSERCLIENT = @"251";
NSString *RPL_LUSEROP = @"252";
NSString *RPL_LUSERUNKNOWN = @"253";
NSString *RPL_LUSERCHANNELS = @"254";
NSString *RPL_LUSERME = @"255";
NSString *RPL_ADMINME = @"256";
NSString *RPL_ADMINLOC1 = @"257";
NSString *RPL_ADMINLOC2 = @"258";
NSString *RPL_ADMINEMAIL = @"259";
NSString *RPL_TRYAGAIN = @"263";
NSString *ERR_NOSUCHNICK = @"401";
NSString *ERR_NOSUCHSERVER = @"402";
NSString *ERR_NOSUCHCHANNEL = @"403";
NSString *ERR_CANNOTSENDTOCHAN = @"404";
NSString *ERR_TOOMANYCHANNELS = @"405";
NSString *ERR_WASNOSUCHNICK = @"406";
NSString *ERR_TOOMANYTARGETS = @"407";
NSString *ERR_NOSUCHSERVICE = @"408";
NSString *ERR_NOORIGIN = @"409";
NSString *ERR_NORECIPIENT = @"411";
NSString *ERR_NOTEXTTOSEND = @"412";
NSString *ERR_NOTOPLEVEL = @"413";
NSString *ERR_WILDTOPLEVEL = @"414";
NSString *ERR_BADMASK = @"415";
NSString *ERR_UNKNOWNCOMMAND = @"421";
NSString *ERR_NOMOTD = @"422";
NSString *ERR_NOADMININFO = @"423";
NSString *ERR_FILEERROR = @"424";
NSString *ERR_NONICKNAMEGIVEN = @"431";
NSString *ERR_ERRONEUSNICKNAME = @"432";
NSString *ERR_NICKNAMEINUSE = @"433";
NSString *ERR_NICKCOLLISION = @"436";
NSString *ERR_UNAVAILRESOURCE = @"437";
NSString *ERR_USERNOTINCHANNEL = @"441";
NSString *ERR_NOTONCHANNEL = @"442";
NSString *ERR_USERONCHANNEL = @"443";
NSString *ERR_NOLOGIN = @"444";
NSString *ERR_SUMMONDISABLED = @"445";
NSString *ERR_USERSDISABLED = @"446";
NSString *ERR_NOTREGISTERED = @"451";
NSString *ERR_NEEDMOREPARAMS = @"461";
NSString *ERR_ALREADYREGISTRED = @"462";
NSString *ERR_NOPERMFORHOST = @"463";
NSString *ERR_PASSWDMISMATCH = @"464";
NSString *ERR_YOUREBANNEDCREEP = @"465";
NSString *ERR_YOUWILLBEBANNED = @"466";
NSString *ERR_KEYSET = @"467";
NSString *ERR_CHANNELISFULL = @"471";
NSString *ERR_UNKNOWNMODE = @"472";
NSString *ERR_INVITEONLYCHAN = @"473";
NSString *ERR_BANNEDFROMCHAN = @"474";
NSString *ERR_BADCHANNELKEY = @"475";
NSString *ERR_BADCHANMASK = @"476";
NSString *ERR_NOCHANMODES = @"477";
NSString *ERR_BANLISTFULL = @"478";
NSString *ERR_NOPRIVILEGES = @"481";
NSString *ERR_CHANOPRIVSNEEDED = @"482";
NSString *ERR_CANTKILLSERVER = @"483";
NSString *ERR_RESTRICTED = @"484";
NSString *ERR_UNIQOPPRIVSNEEDED = @"485";
NSString *ERR_NOOPERHOST = @"491";
NSString *ERR_UMODEUNKNOWNFLAG = @"501";
NSString *ERR_USERSDONTMATCH = @"502";
NSString *RPL_SERVICEINFO = @"231";
NSString *RPL_ENDOFSERVICES = @"232";
NSString *RPL_SERVICE = @"233";
NSString *RPL_NONE = @"300";
NSString *RPL_WHOISCHANOP = @"316";
NSString *RPL_KILLDONE = @"361";
NSString *RPL_CLOSING = @"262";
NSString *RPL_CLOSEEND = @"363";
NSString *RPL_INFOSTART = @"373";
NSString *RPL_MYPORTIS = @"384";
NSString *RPL_STATSCLINE = @"213";
NSString *RPL_STATSNLINE = @"214";
NSString *RPL_STATSILINE = @"215";
NSString *RPL_STATSKLINE = @"216";
NSString *RPL_STATSQLINE = @"217";
NSString *RPL_STATSYLINE = @"218";
NSString *RPL_STATSVLINE = @"240";
NSString *RPL_STATSLLINE = @"241";
NSString *RPL_STATSHLINE = @"244";
NSString *RPL_STATSSLINE = @"245";
NSString *RPL_STATSPING = @"246";
NSString *RPL_STATSBLINE = @"247";
NSString *RPL_STATSDLINE = @"250";
NSString *ERR_NOSERVICEHOST = @"492";
