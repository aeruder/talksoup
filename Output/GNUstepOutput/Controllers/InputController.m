/***************************************************************************
                                InputController.m
                          -------------------
    begin                : Thu Mar 13 13:18:48 CST 2003
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

#import <TalkSoupBundles/TalkSoup.h>
#import "Controllers/InputController.h"
#import "Controllers/ConnectionController.h"
#import "Controllers/ContentController.h"
#import "Controllers/QueryController.h"
#import "Views/ScrollingTextView.h"
#import "GNUstepOutput.h"

#import <Foundation/NSBundle.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSEnumerator.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextStorage.h>

#include <sys/time.h>
#include <time.h>

static void send_message(id command, id name, id connection)
{
	NSRange aRange = NSMakeRange(0, [command length]);
	id substring;
	id nick = S2AS([connection nick]);
	
	name = S2AS(name);
	
	while (aRange.length >= 450)
	{
		substring = [command substringWithRange: NSMakeRange(aRange.location, 450)];
		aRange.location += 450;
		aRange.length -= 450;
		[_TS_ sendMessage: S2AS(substring) to: name onConnection: connection
		  withNickname: nick sender: _GS_];
	}
	
	if (aRange.length > 0)
	{
		[_TS_ sendMessage: 
		  S2AS([command substringWithRange: aRange])
		  to: name onConnection: connection withNickname: nick sender: _GS_];
	}
}	

@interface InputController (PrivateInputController)
- (void)singleLineTyped: (NSString *)aLine;
@end


@implementation InputController
- initWithConnectionController: (ConnectionController *)aController
{
	if (!(self = [super init])) return nil;

	controller = RETAIN(aController);
	
	history = [NSMutableArray new];
	modHistory = [NSMutableArray new];
	[modHistory addObject: @""];

	return self;
}
- (void)dealloc
{
	RELEASE(modHistory);
	RELEASE(history);
	RELEASE(controller);
	[super dealloc];
}
- (void)previousHistoryItem: (NSText *)fieldEditor
{
	int modIndex;
	id string;
	
	if (historyIndex == 0)
	{
		return;
	}

	string = [NSString stringWithString: [fieldEditor string]];
	
	historyIndex--;
	modIndex = [history count] - historyIndex;

	[modHistory replaceObjectAtIndex: modIndex - 1 withObject: string];
	
	if (modIndex < (int)[modHistory count])
	{
		[modHistory replaceObjectAtIndex: modIndex - 1 withObject: string];

		[fieldEditor setString: [modHistory objectAtIndex: modIndex]];
	}
	else
	{
		string = [history objectAtIndex: historyIndex];
		[modHistory addObject: string];
		[fieldEditor setString: string];
	}
	
	[[[controller contentController] window] makeFirstResponder:
	  [[controller contentController] typeView]];
}
- (void)nextHistoryItem: (NSText *)fieldEditor
{
	int modIndex;
	
	if (historyIndex == (int)[history count])
	{
		return;
	}
	 
	historyIndex++;
	modIndex = [history count] - historyIndex;

	[modHistory replaceObjectAtIndex: modIndex + 1 withObject: 
	  [NSString stringWithString: [fieldEditor string]]];
	
	[fieldEditor setString: [modHistory objectAtIndex: modIndex]];

	[[[controller contentController] window] makeFirstResponder:
	  [[controller contentController] typeView]];
}
- (void)lineTyped: (NSString *)command
{
	NSArray *lines;
	NSEnumerator *iter, *iter2;
	id object, object2;

	lines = [command componentsSeparatedByString: @"\r\n"];
		
	iter = [lines objectEnumerator];
	while ((object = [iter nextObject]))
	{
		iter2 = [[object componentsSeparatedByString: @"\n"]
		  objectEnumerator];
		while ((object2 = [iter2 nextObject]))
		{
			if (![object2 isEqualToString: @""])
			{
				[self singleLineTyped: object2];
			}
		}
	}
}
- (void)enterPressed: (id)sender
{
	id string = AUTORELEASE(RETAIN([sender stringValue]));
	
	if ([string length] == 0)
	{
		[[[controller contentController] window] makeFirstResponder: sender];
		return;
	}
	
	[modHistory removeAllObjects];
	[modHistory addObject: @""];
	
	[self lineTyped: string];
	
	[sender setStringValue: @""];
	[[[controller contentController] window] makeFirstResponder: sender];
}
@end

@implementation InputController (PrivateInputController)
- (void)singleLineTyped: (NSString *)command
{
	id connection;
	id name;
	
	[history addObject: command];	
	historyIndex = [history count];
	
	connection = AUTORELEASE(RETAIN(
	  [_GS_ connectionToConnectionController: controller]));
	
	if ([command length] == 0)
	{
		return;
	}
	if ([command hasPrefix: @"/"])
	{
		id substring;
		id arguments;
		SEL commandSelector;
		id array;
		id invoc;

		command = [command substringFromIndex: 1];
		
		array = [command separateIntoNumberOfArguments: 2];
		if ([array count] == 0)
		{
			return;
		}
		
		if ([array count] == 1)
		{
			arguments = nil;
			substring = [array objectAtIndex: 0];
		}
		else
		{
			arguments = [array objectAtIndex: 1];
			substring = [array objectAtIndex: 0];
		}
		
		substring = GNUstepOutputLowercase(substring);
		
		commandSelector = NSSelectorFromString([NSString stringWithFormat: 
		  @"command%@:", [substring capitalizedString]]);
		
		if (commandSelector && [self respondsToSelector: commandSelector])
		{
				[self performSelector: commandSelector withObject: arguments];
				return;
		}
		
		if ((invoc = [_TS_ invocationForCommand: substring]))
		{
			[invoc setArgument: &arguments atIndex: 2];
			[invoc setArgument: &connection atIndex: 3]; 
			[invoc invoke];
			[invoc getReturnValue: &substring];
			arguments = nil;
			[invoc setArgument: &arguments atIndex: 2];
			[invoc setArgument: &arguments atIndex: 3];
			[controller showMessage: substring onConnection: nil];
			return;
		}

		if (connection)
		{
			[_TS_ writeRawString: 
			S2AS(([NSString stringWithFormat: @"%@ %@", 
			    substring, arguments]))
			  onConnection: connection 
			  withNickname: S2AS([connection nick])
			  sender: _GS_];
		}
		return;
	}

	if (!connection) return;
	
	name = [[controller contentController] currentViewName];
	if (name == ContentConsoleName)
	{
		return;
	}

	send_message(command, name, connection); 	
}
@end

@interface InputController (CommonCommands)
@end

@implementation InputController (CommonCommands)
- commandPing: (NSString *)aString
{
	NSArray *x;
	id who;
	struct timeval tv = {0,0};
	id arg;
	id connection;
	
	x = [aString separateIntoNumberOfArguments: 2];
	
	if ([x count] == 0)
	{
		[controller showMessage: 
		  S2AS(_l(@"Usage: /ping <receiver>" @"\n"
		  @"Sends a CTCP ping message to <receiver> (which may be a user "
		  @"or a channel).  Their reply should allow the amount of lag "
		  @"between you and them to be determined.")) onConnection: nil];
		return self;
	}
	
	who = [x objectAtIndex: 0];
	if (gettimeofday(&tv, NULL) == -1)
	{
		[controller showMessage:
		  S2AS(_l(@"gettimeofday() failed")) onConnection: nil];
		return self;
	}
	arg = [NSString stringWithFormat: @"%u.%u", (unsigned)tz.tv_sec, 
	  (unsigned)tz.tv_usec];
	
	connection = [controller connection];
	
	[_TS_ sendCTCPRequest: S2AS(@"PING")
	  withArgument: S2AS(arg) to: S2AS(who) 
	  onConnection: connection
	  withNickname: S2AS([connection nick])
	  sender: _GS_];
	return self;
}				
- commandTopic: (NSString *)aString
{
	NSArray *x;
	id content = [controller contentController];
	id name;
	id connection;
	id topic;

	x = [aString separateIntoNumberOfArguments: 1];
	if ([x count] == 0)
	{
		topic = nil;
	}
	else
	{
		topic = S2AS([x objectAtIndex: 0]);
	}
	
	if (![content isChannelName: name = [content currentViewName]])
	{
		name = nil;
	}
	
	if (!name)
	{
		return self;
	}

	connection = [controller connection];
	
	[_TS_ setTopicForChannel: S2AS(name) to: topic
	  onConnection: connection 
	  withNickname: S2AS([connection nick]) sender: _GS_];
	return self;
}
- commandJoin: (NSString *)aString
{
	NSMutableArray *x;
	x = [NSMutableArray arrayWithArray:
	  [aString separateIntoNumberOfArguments: 3]];
	NSInvocation *invoc;
	id connection;
	
	if ([x count] >= 1)
	{
		NSMutableArray *y;
		id tmp = [x objectAtIndex: 0];
		int z;
		int count;
		
		y = [NSMutableArray arrayWithArray: 
		  [tmp componentsSeparatedByString: @","]];
		
		count = [y count];
		for (z = 0; z < count; z++)
		{
			tmp = [y objectAtIndex: z];
			if ([tmp length] > 0)
			{
				if ([[NSCharacterSet alphanumericCharacterSet]
				  characterIsMember: [tmp characterAtIndex: 0]])
				{
					tmp = [NSString stringWithFormat: @"#%@", tmp];
					[y replaceObjectAtIndex: z withObject: tmp];
				}
			}
		}

		[x replaceObjectAtIndex: 0 withObject: 
		  [y componentsJoinedByString: @","]];
	}
	aString = [x componentsJoinedByString: @" "];
	
	if ((invoc = [_TS_ invocationForCommand: @"Join"]))
	{
		connection = [controller connection];
		
		[invoc setArgument: &aString atIndex: 2];
		[invoc setArgument: &connection atIndex: 3]; 
		[invoc invoke];
		connection = nil;
		[invoc setArgument: &connection atIndex: 2];
		[invoc setArgument: &connection atIndex: 3];
		[invoc getReturnValue: &connection];
		[controller showMessage: connection onConnection: nil];
	}
	return self;
}
- commandServer: (NSString *)aString
{
	NSArray *x = [aString separateIntoNumberOfArguments: 3];
	int aPort;

	if ([x count] == 0)
	{
		[controller showMessage:
		  S2AS(_l(@"Usage: /server <server> [port]"))
		  onConnection: nil];
		return self;
	}

	if ([x count] == 1)
	{
		aPort = 6667;
	}
	else
	{
		aPort = [[x objectAtIndex: 1] intValue];
	}

	[controller connectToServer: [x objectAtIndex: 0] onPort: aPort];

	return self;
}	
- commandNick: (NSString *)aString
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	id connection = [controller connection];
	
	if ([x count] == 0)
	{
		[controller showMessage: 
		  S2AS(_l(@"Usage: /nick <newnick>")) onConnection: nil];
		return self;
	}
	
	if (!connection)
	{
		[controller setNick: [x objectAtIndex: 0]];
		[[controller contentController] setNickViewString:
		  [controller nick]];
		return self;
	}
	
	[_TS_ changeNick: S2AS([x objectAtIndex: 0]) onConnection: connection
	  withNickname: S2AS([connection nick]) sender: _GS_];
	
	if (![connection connected])
	{
		[[controller contentController] setNickViewString:
		  [connection nick]];
	}
	
	return self;
}
- commandMe: (NSString *)aString
{
	id connection = [controller connection];

	if ([aString length] == 0)
	{
		[controller showMessage: 
		  S2AS(_l(@"Usage: /me <action>"))
		  onConnection: nil];
		return self;
	}
	
	[_TS_ sendAction: S2AS(aString) to: S2AS([[controller contentController]
	  currentViewName]) onConnection: connection
	  withNickname: S2AS([connection nick])
	  sender: _GS_];
	return self;
}
- commandQuery: (NSString *)aString
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	id o;
	
	if ([x count] < 1)
	{
		[controller showMessage:
		  S2AS(_l(@"Usage: /query <name>"))
		 onConnection: nil];
		return self;
	}
	
	o = [x objectAtIndex: 0];
	
	[[controller contentController] addQueryWithName: o withLabel: S2AS(o)];
	
	return self;
}
- commandClose: (NSString *)aString
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	id o;
	id connection = [controller connection];
	
	if ([x count] < 1)
	{
		if ([(o = [[controller contentController] currentViewName])
		     isEqualToString: ContentConsoleName])
		{			
			[controller showMessage:
			  S2AS(_l(@"Usage: /close <tab label>")) 
			  onConnection: nil];
			return self;
		}
	}
	else
	{
		o = [x objectAtIndex: 0];
	}

	if ([controller dataForChannelWithName: o])
	{
		[controller leaveChannel: o];
		[_TS_ partChannel: S2AS(o) withMessage: S2AS(@"")
		  onConnection: connection 
		  withNickname: S2AS([connection nick])
		  sender: _GS_];
	}
	
	[[controller contentController] closeViewWithName: o];

	return self;
}
- commandPart: (NSString *)args
{
	id x = [args separateIntoNumberOfArguments: 2];
	id name, msg;
	id content = [controller contentController];
	id connection = [controller connection];
	
	msg = nil;
	if (![content isChannelName: name = [content currentViewName]])
	{
		name = nil;
	}
	
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
		[controller showMessage:
		  S2AS(_l(@"Usage: /part <channel> [message]"))
		  onConnection: nil];
		return self;
	}
	
	[_TS_ partChannel: S2AS(name) withMessage: S2AS(msg) 
	  onConnection: connection
	  withNickname: S2AS([connection nick])
	  sender: _GS_];
	
	return self;
}
- commandClear: (NSString *)command
{
	id x = [[controller contentController] controllerForViewWithName: 
	  [[controller contentController] currentViewName]];
	[[x chatView] setString: @""]; 
	
	return self;
}	
- commandScrollback: (NSString *)command
{
	id x = [command separateIntoNumberOfArguments: 2];
	int length;
	
	if ([x count] == 0)
	{
		[controller showMessage:
		  BuildAttributedString(_l(@"Usage: /scrollback <characters>"),
		    @"\n", _l(@"Current value is: "), 
			 [_GS_ defaultsObjectForKey: GNUstepOutputScrollBack], nil) 
		  onConnection: nil];
		return self;
	}
	
	length = [[x objectAtIndex: 0] intValue];
	
	if (length < 512) length = 512;
	
	[_GS_ setDefaultsObject: [NSString stringWithFormat: @"%d", length]
	  forKey: GNUstepOutputScrollBack];
	
	return self;
}
@end
