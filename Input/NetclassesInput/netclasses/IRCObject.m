/***************************************************************************
                                IRCObject.m
                          -------------------
    begin                : Thu May 30 22:06:25 UTC 2002
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

#include "NetBase.h"
#include "NetTCP.h"
#include "IRCObject.h"

#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSData.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSTimer.h>
#include <Foundation/NSScanner.h>

#include <string.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>

NSString *IRCException = @"IRCException";

static NSMapTable *command_to_function = 0;
static NSMapTable *ctcp_to_function = 0;

static NSData *IRC_new_line = nil;

@implementation NSString (IRCAddition)
// Because in IRC {}|^ are lowercase of []\~
- (NSString *)uppercaseIRCString
{
	NSMutableString *aString = [NSString stringWithString: [self uppercaseString]];
	NSRange aRange = {0, [aString length]};

	[aString replaceOccurrencesOfString: @"{" withString: @"[" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"}" withString: @"]" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"|" withString: @"\\" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"^" withString: @"~" options: 0
	  range: aRange];
	
	return [aString uppercaseString];
}
- (NSString *)lowercaseIRCString
{
	NSMutableString *aString = [NSMutableString 
	  stringWithString: [self lowercaseString]];
	NSRange aRange = {0, [aString length]};

	[aString replaceOccurrencesOfString: @"[" withString: @"{" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"]" withString: @"}" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"\\" withString: @"|" options: 0
	  range: aRange];
	[aString replaceOccurrencesOfString: @"~" withString: @"^" options: 0
	  range: aRange];
	
	return [aString lowercaseString];
}
- (NSComparisonResult)caseInsensitiveIRCCompare: (NSString *)aString
{
	return [[self uppercaseIRCString] compare:
	   [aString uppercaseIRCString]];
}
@end

@interface IRCObject (InternalIRCObject)
- setErrorString: (NSString *)anError;
@end
	
#define NEXT_SPACE(__y, __z, __string)\
{\
	__z = [(__string) rangeOfCharacterFromSet:\
	[NSCharacterSet whitespaceCharacterSet] options: 0\
	range: NSMakeRange((__y), [(__string) length] - (__y))].location;\
	if (__z == NSNotFound) __z = [(__string) length];\
}
	
#define NEXT_NON_SPACE(__y, __z, __string)\
{\
	int __len = [(__string) length];\
	id set = [NSCharacterSet whitespaceCharacterSet];\
	__z = (__y);\
	while (__z < __len && \
	  [set characterIsMember: [(__string) characterAtIndex: __z]]) __z++;\
}

static inline NSString *get_IRC_prefix(NSString *line, NSString **prefix)
{
	int beg;
	int end;
	int len = [line length];
	
	if (len == 0)
	{
		*prefix = nil;
		return @"";
	}
	NEXT_NON_SPACE(0, beg, line);
	
	if (beg == len)
	{
		*prefix = nil;
		return @"";
	}
	
	NEXT_SPACE(beg, end, line);
		
	if ([line characterAtIndex: beg] != ':')
	{
		*prefix = nil;
		return line;
	}
	else
	{
		beg++;
		if (beg == end)
		{
			*prefix = @"";
			if (beg == len)
			{
				return @"";
			}
			else
			{
				return [line substringFromIndex: beg];
			}
		}
	}
	
	*prefix = [line substringWithRange: NSMakeRange(beg, end - beg)];
	
	if (end != len)
	{
		return [line substringFromIndex: end];
	}
	
	return @"";
}
	
static inline NSString *get_next_IRC_word(NSString *line, NSString **prefix)
{
	int beg;
	int end;
	int len = [line length];
	
	if (len == 0)
	{
		*prefix = nil;
		return @"";
	}
	NEXT_NON_SPACE(0, beg, line);
	
	if (beg == len)
	{
		*prefix = nil;
		return @"";
	}
	if ([line characterAtIndex: beg] == ':')
	{
		beg++;
		if (beg == len)
		{
			*prefix = @"";
		}
		else
		{
			*prefix = [line substringFromIndex: beg];
		}
		
		return @"";
	}
	
   NEXT_SPACE(beg, end, line);
	
	*prefix = [line substringWithRange: NSMakeRange(beg, end - beg)];
	
	if (end != len)
	{
		return [line substringFromIndex: end];
	}
	
	return @"";
}

#undef NEXT_NON_SPACE
#undef NEXT_SPACE

static inline BOOL is_numeric_command(NSString *aString)
{
	static NSCharacterSet *set = nil;
	unichar test[3];
	
	if (!set)
	{
		set = RETAIN([NSCharacterSet 
		  characterSetWithCharactersInString: @"0123456789"]);
	}
	
	if ([aString length] != 3)
	{
		return NO;
	}
	
	[aString getCharacters: test];
	if ([set characterIsMember: test[0]] && [set characterIsMember: test[1]] &&
	    [set characterIsMember: test[2]])
	{
		return YES;
	}
	
	return NO;
}

static inline BOOL contains_a_space(NSString *aString)
{
	return ([aString rangeOfCharacterFromSet: 
	  [NSCharacterSet whitespaceCharacterSet]].location == NSNotFound) ?
	  NO : YES;
}	

static inline NSString *string_to_string(NSString *aString, NSString *delim)
{
	NSRange a = [aString rangeOfString: delim];
	
	if (a.location == NSNotFound) return [NSString stringWithString: aString];
	
	return [aString substringToIndex: a.location];
}

static inline NSString *string_from_string(NSString *aString, NSString *delim)
{
	NSRange a = [aString rangeOfString: delim];
	
	if (a.location == NSNotFound) return nil;
	
	a.location += a.length;
	
	if (a.location == [aString length])
	{
		return @"";
	}
	
	return [aString substringFromIndex: a.location];
}

inline NSString *ExtractIRCNick(NSString *prefix)
{	
	return string_to_string(prefix, @"!");
}

inline NSString *ExtractIRCHost(NSString *prefix)
{
	return string_from_string(prefix, @"!");
}

inline NSArray *SeparateIRCNickAndHost(NSString *prefix)
{
	return [NSArray arrayWithObjects: string_to_string(prefix, @"!"),
	  string_from_string(prefix, @"!"), nil];
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

static void rec_ccustom(IRCObject *client, NSString *prefix, 
                        NSString *command, NSString *rest, NSString *to,
                        NSString *ctcp)
{
	if ([command isEqualToString: @"NOTICE"])
	{
		[client CTCPReplyReceived: ctcp withArgument: rest
		  from: prefix];
	}
	else
	{
		[client CTCPRequestReceived: ctcp withArgument: rest
		  from: prefix];
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
	
	if ([[client nick] isEqualToString: ExtractIRCNick(prefix)])
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
	
	if ([paramList count] < 2)
	{
		return;
	}

	message = [paramList objectAtIndex: 1];
	if ([message hasPrefix: @"\001"])
	{
		void (*func)(IRCObject *, NSString *, NSString *, NSString *, 
		              NSString *);
		id ctcp = string_to_string(message, @" ");
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
		else
		{
			ctcp = [ctcp substringFromIndex: 1];
			rec_ccustom(client, prefix, command, rest,
			  [paramList objectAtIndex: 0], ctcp);
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
	NSString *arg;
	
	arg = [paramList componentsJoinedByString: @" "];
	
	[client pingReceivedWithArgument: arg from: prefix];
}
static void rec_pong(IRCObject *client, NSString *command, NSString *prefix,
                     NSArray *paramList)
{
	NSString *arg;
	
	arg = [paramList componentsJoinedByString: @" "];
	
	[client pongReceivedWithArgument: arg from: prefix];
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
	NSMapInsert(command_to_function, @"PONG", rec_pong);
	NSMapInsert(command_to_function, @"WALLOPS", rec_wallops);
	NSMapInsert(command_to_function, @"ERROR", rec_error);

	ctcp_to_function = NSCreateMapTable(NSObjectMapKeyCallBacks,
	   NSIntMapValueCallBacks, 1);
	
	NSMapInsert(ctcp_to_function, @"\001ACTION", rec_caction);
}
- initWithNickname: (NSString *)aNickname withUserName: (NSString *)aUser
   withRealName: (NSString *)aRealName
   withPassword: (NSString *)aPassword
{
	if (!(self = [super init])) return nil;
	
	if (![self setNick: aNickname])
	{
		return nil;
	}

	if (![self setUserName: aUser])
	{
		return nil;
	}

	if (![self setRealName: aRealName])
	{
		return nil;
	}

	if (![self setPassword: aPassword])
	{
		return nil;
	}

	return self;
}
- (void)dealloc
{
	DESTROY(nick);
	DESTROY(userName);
	DESTROY(realName);
	DESTROY(password);
	DESTROY(errorString);
	
	[super dealloc];
}
- (void)connectionLost
{
	connected = NO;
	[super connectionLost];
}
- setNick: (NSString *)aNickname
{
	if (aNickname == nick) return self;
	
	aNickname = string_to_string(aNickname, @" ");
	if ([aNickname length] == 0)
	{
		[self setErrorString: @"No usable nickname provided"];
		return nil;
	}

	RELEASE(nick);
	nick = RETAIN(aNickname);

	return self;
}
- (NSString *)nick
{
	return nick;
}
- setUserName: (NSString *)user
{
	id enviro;
	
	if ([user length] == 0)
	{
		enviro = [[NSProcessInfo processInfo] environment];
		
		user = [enviro objectForKey: @"LOGNAME"];

		if ([user length] == 0)
		{
			user = @"netclasses";
		}
	}
	if ([(user = string_to_string(user, @" ")) length] == 0)
	{
		user = @"netclasses";
	}

	RELEASE(userName);
	userName = RETAIN(user);
	
	return self;
}
- (NSString *)userName
{
	return userName;
}
- setRealName: (NSString *)aRealName
{
	if ([aRealName length] == 0)
	{
		aRealName = @"John Doe";
	}

	RELEASE(realName);
	realName = RETAIN(aRealName);

	return self;
}
- (NSString *)realName
{
	return realName;
}
- setPassword: (NSString *)aPass
{
	if ([aPass length])
	{
		if ([(aPass = string_to_string(aPass, @" ")) length] == 0) 
		{
			[self setErrorString: @"Unusable password"];
			return nil;
		}
	}
	else
	{
		aPass = nil;
	}
	
	DESTROY(password);
	password = RETAIN(aPass);
	
	return self;
}
- (NSString *)password
{
	return password;
}
- (NSString *)errorString
{
	return errorString;
}
- connectionEstablished: aTransport
{
	[super connectionEstablished: aTransport];
	
	if (password)
	{
		[self writeString: [NSString stringWithFormat: 
		  @"PASS %@", password]];
	}

	[self changeNick: nick];

	[self writeString: @"USER %@ %@ %@ :%@", userName, @"localhost", 
	  @"netclasses", realName];
	return self;
}
- (BOOL)connected
{
	return connected;
}
- changeNick: (NSString *)aNick
{
	if ([aNick length] > 0)
	{
		if ([(aNick = string_to_string(aNick, @" ")) length] == 0)
		{
			[NSException raise: IRCException
			 format: @"[IRCObject changeNick: '%@'] Unusable nickname given",
			  aNick];
		}
		if (!connected)
		{
			[self setNick: aNick];
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
	
	if ([(channel = string_to_string(channel, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject partChannel: '%@' ...] Unusable channel given",
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

	if ([(channel = string_to_string(channel, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject joinChannel: '%@' ...] Unusable channel",
		  channel];
	}

	if ([aPassword length] == 0)
	{
		[self writeString: @"JOIN %@", channel];
		return self;
	}

	if ([(aPassword = string_to_string(aPassword, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject joinChannel: withPassword: '%@'] Unusable password",
		  aPassword];
	}

	[self writeString: @"JOIN %@ %@", channel, aPassword];

	return self;
}
- sendCTCPReply: (NSString *)aCTCP withArgument: (NSString *)args
   to: (NSString *)aPerson
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if ([(aPerson = string_to_string(aPerson, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		  @"[IRCObject sendCTCPReply: '%@'withArgument: '%@' to: '%@'] Unusable receiver",
		    aCTCP, args, aPerson];
	}
	if (!aCTCP)
	{
		aCTCP = @"";
	}
	if ([args length])
	{
		[self writeString: @"NOTICE %@ :\001%@ %@\001", aPerson, aCTCP, args];
	}
	else
	{
		[self writeString: @"NOTICE %@ :\001%@\001", aPerson, aCTCP];
	}
		
	return self;
}
- sendCTCPRequest: (NSString *)aCTCP withArgument: (NSString *)args
   to: (NSString *)aPerson
{
	if ([aPerson length] == 0)
	{
		return self;
	}
	if ([(aPerson = string_to_string(aPerson, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		  @"[IRCObject sendCTCPRequest: '%@'withArgument: '%@' to: '%@'] Unusable receiver",
		    aCTCP, args, aPerson];
	}
	if (!aCTCP)
	{
		aCTCP = @"";
	}
	if ([args length])
	{
		[self writeString: @"PRIVMSG %@ :\001%@ %@\001", aPerson, aCTCP, args];
	}
	else
	{
		[self writeString: @"PRIVMSG %@ :\001%@\001", aPerson, aCTCP];
	}
		
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
	if ([(receiver = string_to_string(receiver, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject sendMessage: '%@' to: '%@'] Unusable receiver",
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
	if ([(receiver = string_to_string(receiver, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject sendNotice: '%@' to: '%@'] Unusable receiver",
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
	if ([(receiver = string_to_string(receiver, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject sendAction: '%@' to: '%@'] Unusable receiver",
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
	if ([(pass = string_to_string(pass, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject becomeOperatorWithName: %@ withPassword: %@] Unusable password",
		  aName, pass];
	}
	if ([(aName = string_to_string(aName, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject becomeOperatorWithName: %@ withPassword: %@] Unusable name",
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
	
	if ([(aChannel = string_to_string(aChannel, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: 
		  @"[IRCObject requestNamesOnChannel: %@ fromServer: %@] Unusable channel",
		   aChannel, aServer];
	}
			
	if ([aServer length] == 0)
	{
		[self writeString: @"NAMES %@", aChannel];
		return self;
	}

	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject requestNamesOnChannel: %@ fromServer: %@] Unusable server",
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
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format: 
		  @"[IRCObject requestMOTDOnServer:'%@'] Unusable server",
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
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestSizeInformationFromServer: '%@' andForwardTo: '%@'] Unusable first server", 
		  aServer, anotherServer];
	}
	if ([anotherServer length] == 0)
	{
		[self writeString: @"LUSERS %@", aServer];
		return self;
	}
	if ([(anotherServer = string_to_string(anotherServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestSizeInformationFromServer: '%@' andForwardTo: '%@'] Unusable second server",
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
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestVersionOfServer: '%@'] Unusable server",
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
	if ([(query = string_to_string(query, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerStats: '%@' for: '%@'] Unusable query",
		  aServer, query];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"STATS %@", query];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerStats: '%@' for: '%@'] Unusable server",
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
	if ([(aLink = string_to_string(aLink, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerLink: '%@' from: '%@'] Unusable link",
		  aLink, aServer];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"LINKS %@", aLink];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerLink: '%@' from: '%@'] Unusable server", 
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
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestTimeOnServer: '%@'] Unusable server",
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
	if ([(connectServer = string_to_string(connectServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerToConnect: '%@' to: '%@' onPort: '%@'] Unusable second server",
		  aServer, connectServer, aPort];
	}
	if ([aPort length] == 0)
	{
		return self;
	}
	if ([(aPort = string_to_string(aPort, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServerToConnect: '%@' to: '%@' onPort: '%@'] Unusable port",
		  aServer, connectServer, aPort];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"CONNECT %@ %@", connectServer, aPort];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format: 
		 @"[IRCObject requestServerToConnect: '%@' to: '%@' onPort: '%@'] Unusable first server",
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
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format: 
		 @"[IRCObject requestTraceOnServer: '%@'] Unusable server",
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
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestAdministratorOnServer: '%@'] Unusable server", 
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
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestInfoOnServer: '%@'] Unusable server",
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
	if ([(aMask = string_to_string(aMask, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServiceListWithMask: '%@' ofType: '%@'] Unusable mask",
		  aMask, type];
	}
	if ([type length] == 0)
	{
		[self writeString: @"SERVLIST %@", aMask];
		return self;
	}
	if ([(type = string_to_string(type, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestServiceListWithMask: '%@' ofType: '%@'] Unusable type",
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
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject requestUserInfoOnServer: '%@'] Unusable server",
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
	if ([(aService = string_to_string(aService, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject queryService: '%@' withMessage: '%@'] Unusable service",
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
	if ([(aMask = string_to_string(aMask, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject listWho: '%@' onlyOperators: %d] Unusable mask",
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
	if ([(aPerson = string_to_string(aPerson, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whois: '%@' onServer: '%@'] Unusable person",
		 aPerson, aServer];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"WHOIS %@", aPerson];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whois: '%@' onServer: '%@'] Unusable server",
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
	if ([(aPerson = string_to_string(aPerson, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whowas: '%@' onServer: '%@' withNumberEntries: '%@'] Unusable person",
		  aPerson, aServer, aNumber];
	}
	if ([aNumber length] == 0)
	{
		[self writeString: @"WHOWAS %@", aPerson];
		return self;
	}
	if ([(aNumber = string_to_string(aNumber, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whowas: '%@' onServer: '%@' withNumberEntries: '%@'] Unusable number of entries", 
		  aPerson, aServer, aNumber];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"WHOWAS %@ %@", aPerson, aNumber];
		return self;
	}
	if ([(aServer = string_to_string(aServer, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject whowas: '%@' onServer: '%@' withNumberEntries: '%@'] Unusable server",
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
	if ([(aPerson = string_to_string(aPerson, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject kill: '%@' withComment: '%@'] Unusable person",
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
	if ([(aChannel = string_to_string(aChannel, @" ")) length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject setTopicForChannel: %@ to: %@] Unusable channel",
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
	if ([(anObject = string_to_string(anObject, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		  @"[IRCObject setMode:'%@' on:'%@' withParams:'%@'] Unusable object", 
		    aMode, anObject, list];
	}
	if ([aMode length] == 0)
	{
		[self writeString: @"MODE %@", anObject];
		return self;
	}
	if ([(aMode = string_to_string(aMode, @" ")) length] == 0)
	{		
		[NSException raise: IRCException format:
		  @"[IRCObject setMode:'%@' on:'%@' withParams:'%@'] Unusable mode", 
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
	if ([(aChannel = string_to_string(aChannel, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject listChannel:'%@' onServer:'%@'] Unusable channel",
		  aChannel, aServer];
	}
	if ([aServer length] == 0)
	{
		[self writeString: @"LIST %@", aChannel];
		return self;
	}
	if ([(aChannel = string_to_string(aChannel, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject listChannel:'%@' onServer:'%@'] Unusable server",
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
	if ([(aPerson = string_to_string(aPerson, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject invite:'%@' to:'%@'] Unusable person",
		  aPerson, aChannel];
	}
	if ([(aChannel = string_to_string(aChannel, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject invite:'%@' to:'%@'] Unusable channel",
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
	if ([(aPerson = string_to_string(aPerson, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject kick:'%@' offOf:'%@' for:'%@'] Unusable person",
		  aPerson, aChannel, reason];
	}
	if ([(aChannel = string_to_string(aChannel, @" ")) length] == 0)
	{
		[NSException raise: IRCException format:
		 @"[IRCObject kick:'%@' offOf:'%@' for:'%@'] Unusable channel",
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
- sendPingWithArgument: (NSString *)aString
{
	if (!aString)
	{
		aString = @"";
	}

	[self writeString: @"PING :%@", aString];
	
	return self;
}
- sendPongWithArgument: (NSString *)aString
{
	if (!aString)
	{
		aString = @"";
	}

	[self writeString: @"PONG :%@", aString];
	
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
- CTCPRequestReceived: (NSString *)aCTCP
   withArgument: (NSString *)argument from: (NSString *)aPerson
{
	return self;
}
- CTCPReplyReceived: (NSString *)aCTCP
   withArgument: (NSString *)argument from: (NSString *)aPerson
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
- pingReceivedWithArgument: (NSString *)arg from: (NSString *)sender
{
	return self;
}
- pongReceivedWithArgument: (NSString *)arg from: (NSString *)sender
{
	return self;
}
- newNickNeededWhileRegistering
{
	[self changeNick: nick];
	
	return self;
}
- lineReceived: (NSData *)aLine
{
	NSString *prefix = nil;
	NSString *command = nil;
	NSMutableArray *paramList = nil;
	id object;
	void (*function)(IRCObject *, NSString *, NSString *, NSArray *);
	NSString *line, *orig;
	
	orig = line = AUTORELEASE([[NSString alloc] initWithData: aLine
	  encoding: NSISOLatin1StringEncoding]);

	if ([line length] == 0)
	{
		return self;
	}
	
	paramList = AUTORELEASE([NSMutableArray new]);
	
	line = get_IRC_prefix(line, &prefix); 
	
	if ([line length] == 0)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject lineReceived: '@'] Line ended prematurely.",
		 orig];
	}

	line = get_next_IRC_word(line, &command);
	if (command == nil)
	{
		[NSException raise: IRCException
		 format: @"[IRCObject lineReceived: '@'] Line ended prematurely.",
		 orig];
	}

	while (1)
	{
		line = get_next_IRC_word(line, &object);
		if (!object)
		{
			break;
		}
		[paramList addObject: object];
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

	if (!connected)
	{
		if ([command isEqualToString: ERR_NEEDMOREPARAMS] ||
			[command isEqualToString: ERR_ALREADYREGISTRED] ||
			[command isEqualToString: ERR_NONICKNAMEGIVEN])
		{
			[[NetApplication sharedInstance] disconnectObject: self];
			[self couldNotRegister: [NSString stringWithFormat:
			 @"%@ %@ %@", prefix, command, paramList]];
			return nil;
		}
		else if ([command isEqualToString: ERR_NICKNAMEINUSE] ||
		         [command isEqualToString: ERR_NICKCOLLISION] ||
				 [command isEqualToString: ERR_ERRONEUSNICKNAME])
		{
			[self newNickNeededWhileRegistering];
		}
		else if ([command isEqualToString: RPL_WELCOME])
		{
			connected = YES;
			[self registeredWithServer];
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
