/***************************************************************************
                                ConnectionController.m
                          -------------------
    begin                : Sun Oct  6 15:58:33 CDT 2002
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

#import "Controllers/ConnectionController.h"
#import "Controllers/TalkController.h"
#import "Controllers/ChannelController.h"
#import "Controllers/QueryController.h"
#import "Views/ScrollingTextView.h"
#import "Views/ColoredTabViewItem.h"
#import "Windows/ChannelWindow.h"
#import "Misc/Functions.h"
#import "Models/Channel.h"
#import "TalkSoup.h"
#import "netclasses/NetTCP.h"
#import "Views/TabTextField.h"

#import <Foundation/NSHost.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSArray.h>

#import <AppKit/NSTextStorage.h>
#import <AppKit/NSTabViewItem.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSView.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSCell.h>

static NSString *version_number = nil;
static NSString *console_name = nil;
static NSColor *highlight_color = nil;

static NSArray *command_names = nil;

static NSArray *get_first_word(NSString *arg)
{
	NSRange aRange;
	NSString *first, *rest;
	id white = [NSCharacterSet whitespaceCharacterSet];

	arg = [arg stringByTrimmingCharactersInSet: white];
	  
	if ([arg length] == 0)
	{
		return [NSArray arrayWithObjects: nil];
	}

	aRange = [arg rangeOfCharacterFromSet: white];

	if (aRange.location == NSNotFound && aRange.length == 0)
	{
		return [NSArray arrayWithObjects: arg, nil];
	}
	
	rest = [[arg substringFromIndex: aRange.location]
	  stringByTrimmingCharactersInSet: white];
	
	first = [arg substringToIndex: aRange.location];

	return [NSArray arrayWithObjects: first, rest, nil];
}

NSArray *SeparateIntoNumberOfArguments(NSString *string, int num)
{
	NSMutableArray *array = AUTORELEASE([NSMutableArray new]);
	id object;
	int temp;
	
	if (num <= 1)
	{
		return [NSArray arrayWithObject: [string 
		  stringByTrimmingCharactersInSet: 
		    [NSCharacterSet whitespaceCharacterSet]]];
	}
	if (num == 2)
	{
		return get_first_word(string);
	}
	
	while (num != 1)
	{
		object = get_first_word(string);
		temp = [object count];
		switch(temp)
		{
			case 0:
				return [NSArray arrayWithObjects: nil];
			case 1:
				[array addObject: [object objectAtIndex: 0]];
				return array;
			case 2:
				string = [object objectAtIndex: 1];
				[array addObject: [object objectAtIndex: 0]];
				num--;
		}
	}
	[array addObject: string];
	return array;
}	
	
@interface ConnectionController (IRCHandler)
@end

@interface ConnectionController (CTCPHandler)
@end

@interface ConnectionController (WindowDelegate)
@end

@interface ConnectionController (TabViewItemDelegate)
@end

@interface ConnectionController (CommandHandler)
- (void)linesTyped: (id)sender;
- (void)lineTyped: (id)sender;
@end

@interface ConnectionController (NumberCommandHandler)
@end

@implementation ConnectionController
+ (void)initialize
{
	version_number =  RETAIN([[[NSBundle mainBundle] infoDictionary] 
	  objectForKey: @"ApplicationRelease"]);
	console_name = [[NSString alloc] initWithString: @"console tab"];
	highlight_color = RETAIN([NSColor colorWithCalibratedRed: 0.41
	  green: 0.13 blue: 0.14 alpha: 1.0]);
}
+ (void)loadCommandNames
{
	NSMutableArray *array = AUTORELEASE([NSMutableArray new]);
	NSEnumerator *iter = [[self methodsDefinedForClass] objectEnumerator];
	id object;
	NSRange aRange;

	while ((object = [iter nextObject]))
	{
		if ([object hasPrefix: @"command"] && [object hasSuffix: @":"] &&
		    ![object isEqualToString: @"command:"])
		{
			aRange.location = 7;
			aRange.length = [object length] - 8;
			[array addObject: [NSString stringWithFormat: @"/%@", 
			  [[object substringWithRange: aRange] uppercaseIRCString]]];
		}
	}

	RELEASE(command_names);
	command_names = RETAIN([NSArray arrayWithArray: array]);
}		
- init
{
	if (!(self = [super initWithNickname: @"TalkSoup" withUserName: nil
	  withRealName: nil withPassword: nil])) return nil;

	nameToChannel = [NSMutableDictionary new];
	nameToChannelData = [NSMutableDictionary new];
	nameToQuery = [NSMutableDictionary new];
	nameToDeadChannel = [NSMutableDictionary new];
	nameToTalk = [NSMutableDictionary new];
	nameToTypedName = [NSMutableDictionary new];
	connectCommands = [NSMutableArray new];

	talkToHolder = NSCreateMapTable(NSObjectMapKeyCallBacks,
	  NSObjectMapValueCallBacks, 10);
	
	window = [ChannelWindow new];

	console = [QueryController new];
	[self addTabViewItemWithName: console_name withView: console];
	[nameToTypedName setObject: console_name forKey: console_name];

	[self updateHostName];

	[[TalkSoup sharedInstance] addConnection: self];

	[window makeKeyAndOrderFront: nil];
	
	[window setDelegate: self];
	[[window tabView] setDelegate: self];
	[[window typeView] setAction: @selector(linesTyped:)];
	[[window typeView] setTarget: self];
	[[window typeView] setDelegate: self];
	[window setReleasedWhenClosed: NO];
	
	[window updateNick: nick];

	if (!current)
	{
		current = RETAIN(console);
	}

	if (!command_names)
	{
		[[self class] loadCommandNames];
	}

	return self;
}
- (void)dealloc
{
	DESTROY(typedHost);
	DESTROY(currentHost);
	DESTROY(connectCommands);
	DESTROY(connecting);
	DESTROY(nameToChannel);
	DESTROY(nameToTalk);
	DESTROY(nameToChannelData);
	DESTROY(nameToTypedName);
	DESTROY(nameToQuery);
	DESTROY(nameToDeadChannel);
	DESTROY(console);
	DESTROY(current);
	
	NSFreeMapTable(talkToHolder);
	talkToHolder = 0;

	[super dealloc];
}
- (void)connectionLost
{
	NSEnumerator *iter;
	id object;
	id chan;
	
	DESTROY(currentHost);
	
	[self putMessage: @"Disconnected" in: [nameToTalk allValues]];
	iter = [[nameToChannel allKeys] objectEnumerator];

	while ((object = [iter nextObject]))
	{
		chan = [nameToChannel objectForKey: object];
		[self setLabel: [NSString stringWithFormat: @"(%@)", 
		  [nameToTypedName objectForKey: object]] forView: chan];
		
		[[chan userTable] setDataSource: nil];
		[nameToDeadChannel setObject: chan forKey: object];
		
		[nameToChannelData removeObjectForKey: object];
		[nameToChannel removeObjectForKey: object];
		[nameToTalk removeObjectForKey: object];
	}	
	
	[super connectionLost];

	[self updateHostName];
}
- connectionEstablished: (TCPTransport *)aTransport
{
	DESTROY(connecting);
	[super connectionEstablished: aTransport];

	if (currentHost != [[aTransport address] name])
	{
		RELEASE(currentHost);
		currentHost = RETAIN([[aTransport address] name]);
	}
	
	[self updateHostName];
	
	[self putMessage: @"Connected. Now logging in.." in: console];
	
	return self;
}
- connectingStarted: (TCPConnecting *)aConnection
{
	connecting = RETAIN(aConnection);
	[self updateHostName];

	return self;
}
- connectingFailed: (NSString *)anError
{
	[self putMessage: [NSString stringWithFormat: @"Connection Failed: %@", 
	   anError] in: console];
	
	DESTROY(connecting);
	[self updateHostName];
	
	return self;
}
- (ColoredTabViewItem *)addTabViewItemWithName: (NSString *)key
    withView: (TalkController *)aView
{
	id tab;
	
	if ([aView isKindOfClass: [ChannelController class]])
	{
		[nameToChannel setObject: aView forKey: key];
	}
	else if ([aView isKindOfClass: [QueryController class]])
	{
		[nameToQuery setObject: aView forKey: key];
	}
	[nameToTalk setObject: aView forKey: key];
	
	tab = AUTORELEASE([[ColoredTabViewItem alloc]
	  initWithIdentifier: key]);
	
	NSMapInsert(talkToHolder, aView, tab);
	
	[[window tabView] addTabViewItem: tab];
	[tab setView: [aView contentView]];

	[aView setIdentifier: key];

	return tab;
}
- removeTabViewItemWithName: (NSString *)key
{
	id tab;
	id view;

	view = AUTORELEASE(RETAIN([nameToTalk objectForKey: key]));
	if (!view)
	{
		view = AUTORELEASE(RETAIN([nameToDeadChannel objectForKey: key]));
	}
	[nameToChannel removeObjectForKey: key];
	[nameToQuery removeObjectForKey: key];
	[nameToTalk removeObjectForKey: key];
	[nameToDeadChannel removeObjectForKey: key];
	[nameToChannelData removeObjectForKey: key];
	[nameToTypedName removeObjectForKey: key];

	if ([view respondsToSelector: @selector(userTable)])
	{
		[[view userTable] setDataSource: nil];
	}
	
	tab = NSMapGet(talkToHolder, view);
	if ([[window tabView] selectedTabViewItem] == tab)
	{
		[[window tabView] selectPreviousTabViewItem: nil];
	}

	[[window tabView] removeTabViewItem: tab];

	return self;
}	
- setLabel: (NSString *)aLabel forView: (TalkController *)aView
{
	id tab;
	
	tab = NSMapGet(talkToHolder, aView);

	if ([tab isKindOf: [ColoredTabViewItem class]])
	{
		[tab setLabel: aLabel];
		[[tab tabView] setNeedsDisplay: YES];
	}
	
	return self;
}	
- putMessage: (NSString *)message in: channel
{
	id view = nil;
	id tab;
	
	if (![message hasSuffix: @"\n"])
	{
		message = [message stringByAppendingString: @"\n"];
	}
	
	if ([channel isKindOf: [TalkController class]])
	{
		view = channel;
	}
	else if ([channel isKindOf: [NSString class]])
	{
		view = [nameToTalk objectForKey: [channel lowercaseIRCString]];
	}
	else if ([channel isKindOf: [NSArray class]])
	{
		id object;
		NSEnumerator *iter;

		iter = [channel objectEnumerator];
		while ((object = [iter nextObject]))
		{
			[self putMessage: message in: object];
		}
	}
	else if ([channel isKindOf: [Channel class]])
	{
		view = [nameToChannel objectForKey: [[(Channel *)channel identifier] 
		   lowercaseIRCString]];
	}
	else if (channel == nil)
	{
		view = current;
	}
	else
	{
		return self;
	}

	if (view != current)
	{
		tab = NSMapGet(talkToHolder, view);
		if ([tab isKindOfClass: [ColoredTabViewItem class]])
		{
			[tab setLabelColor: highlight_color];
		}
	}

	[[view talkView] appendText: message];
	
	return self;
}
- (NSArray *)channelsWithUser: (NSString *)aUser
{
	id object;
	NSEnumerator *iter;
	NSMutableArray *list = AUTORELEASE([NSMutableArray new]);

	iter = [[nameToChannelData allValues] objectEnumerator];

	while ((object = [iter nextObject]))
	{
		if ([object containsUser: aUser])
		{
			[list addObject: object];
		}
	}

	return [NSArray arrayWithArray: list];
}
- addConnectCommands: (NSArray *)aCommand
{
	[connectCommands addObjectsFromArray: aCommand];
	return self;
}
- addConnectCommand: (NSString *)aCommand
{
	[connectCommands addObject: aCommand];
	return self;
}
- resetConnectCommands
{
	[connectCommands removeAllObjects];
	return self;
}
- updateHostName
{
	if (!transport && !connecting)
	{
		[self setLabel: @"Unconnected" forView: console];
		[window setTitle: @"Unconnected"];
	}
	if (!transport && connecting)
	{ 
		[self setLabel: @"Connecting" forView: console];
		[window setTitle: [NSString stringWithFormat: @"Connecting to %@",
		  typedHost]];
	}
	if (transport)
	{
		[self setLabel: currentHost forView: console];
		[window setTitle: currentHost];
	}	
	
	return self;
}
@end

@implementation ConnectionController (WindowTabViewDelegate)
- (void)tabView:(NSTabView *)tabView 
     didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	RELEASE(current);
	current = RETAIN([nameToTalk objectForKey: [tabViewItem identifier]]);
	if (!current)
	{
		current = RETAIN([nameToDeadChannel objectForKey: 
		  [tabViewItem identifier]]);
	}
	[window makeFirstResponder: [window typeView]];

	if ([tabViewItem isKindOfClass: [ColoredTabViewItem class]])
	{
		[(ColoredTabViewItem *)tabViewItem setLabelColor: nil];
	}
}
@end

@implementation ConnectionController (TextField)
- (void)textFieldReceivedTab: (TabTextField *)field
{
	NSString *aString = [field stringValue];
	NSRange aRange;
	int pos;
	NSString *word;
	id object;
	NSEnumerator *iter;
	NSMutableArray *out = AUTORELEASE([NSMutableArray new]);
	NSString *completion = nil;
	
	aRange = [aString rangeOfCharacterFromSet: 
	 [NSCharacterSet whitespaceAndNewlineCharacterSet]
	 options: NSBackwardsSearch];
	
	if (aRange.location == NSNotFound) aRange.location = 0;

	pos = aRange.location + aRange.length;

	if (pos == [aString length]) return;
	
	word = [aString substringFromIndex: pos];
	
	if ([word hasPrefix: @"/"] && pos == 0)
	{
		word = [word uppercaseIRCString];
		
		iter = [command_names objectEnumerator];
	
		while ((object = [iter nextObject]))
		{
			if ([object hasPrefix: word])
			{
				[out addObject: object];
				if (completion)
				{
					completion = [completion commonPrefixWithString: object
					  options: 0];
				}
				else
				{	
					completion = object;
				}
			}
		}
		
	}
	else if ([word hasPrefix: @"#"])
	{
		id temp = nil;
		
		word = [word lowercaseIRCString];

		iter = [[nameToChannel allKeys] objectEnumerator];

		while ((object = [iter nextObject]))
		{
			if ([object hasPrefix: word])
			{
				[out addObject: [nameToTypedName objectForKey: object]];
				if (completion)
				{
					completion = [completion commonPrefixWithString: object
					  options: 0];
				}
				else
				{
					completion = object;
				}
				temp = object;
			}
		}
		if (temp)
		{
			completion = [[nameToTypedName objectForKey: temp] substringToIndex:
			  [completion length]];
		}
	}
	else
	{
		if ([current isKindOfClass: [ChannelController class]])
		{
			id temp, temp2 = nil;
			
			word = [word lowercaseIRCString];

			iter = [[[nameToChannelData objectForKey: [current identifier]]
			  userList] objectEnumerator];

			while ((object = [iter nextObject]))
			{
				object = [object userName];
				temp = [object lowercaseIRCString];
				if ([temp hasPrefix: word])
				{
					[out addObject: object];
					if (completion)
					{
						completion = [completion commonPrefixWithString: temp
						  options: 0];
					}
					else
					{
						completion = temp;
					}
					temp2 = object;
				}
			}
			if (temp2)
			{
				completion = [temp2 substringToIndex: [completion length]];
			}
		}
	}
	
	if ([out count] == 0)
	{
		NSBeep();
	}
	else if ([out count] == 1)
	{
		[field setObjectValue: [NSString stringWithFormat: @"%@%@ ",
		  [aString substringToIndex: pos], [out objectAtIndex: 0]]];
	}
	else
	{
		[field setObjectValue: [NSString stringWithFormat: @"%@%@",
		  [aString substringToIndex: pos], completion]];
		[self putMessage: [out componentsJoinedByString: @"     "] in: nil];
	}
}
@end

@implementation ConnectionController (WindowDelegate)
- (void)windowWillClose: (NSNotification *)aNotification
{
	if (window != [aNotification object]) return;
	
	if (!connecting)
	{
		[[NetApplication sharedInstance] disconnectObject: self];
	}
	else
	{
		[connecting abortConnection];
	}
	
	[window setDelegate: nil];
	[[window tabView] setDelegate: nil];
	[[window typeView] setTarget: nil];
	[[window typeView] setDelegate: nil];
	DESTROY(window);
	
	[[TalkSoup sharedInstance] removeConnection: self];
}
- (void)windowDidBecomeKey: (NSNotification *)aNotification
{
	if (window != [aNotification object]) return;
	[window makeFirstResponder: [window typeView]];
}
@end

@implementation ConnectionController (CommandHandler)
// This method should handle mixed \r\n and \n strings just fine
// I'm not sure if this is necessary, but just in case...
- (void)linesTyped: (id)sender
{
	id command = AUTORELEASE(RETAIN([sender stringValue]));
	NSArray *lines;
	NSEnumerator *iter;
	id object;
	
	[sender setStringValue: @""];
	[window makeFirstResponder: sender];

	if ([lines = [command componentsSeparatedByString: @"\r\n"] count] > 1)
	{
		NSEnumerator *iter2;
		id object2;
		
		iter = [lines objectEnumerator];
		while ((object = [iter nextObject]))
		{
			iter2 = [[object componentsSeparatedByString: @"\n"]
			  objectEnumerator];
			while ((object2 = [iter2 nextObject]))
			{
				[self lineTyped: object2];
			}
		}
	}
	else
	{
		lines = [command componentsSeparatedByString: @"\n"];
		iter = [lines objectEnumerator];
		while ((object = [iter nextObject]))
		{
			[self lineTyped: object];
		}
	}	
}
- (void)lineTyped: (NSString *)command
{
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

		command = [command substringFromIndex: 1];
		
		array = SeparateIntoNumberOfArguments(command, 2);

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
		
		substring = [substring lowercaseIRCString];
		commandSelector = NSSelectorFromString([NSString stringWithFormat: 
		  @"command%@:", [substring capitalizedString]]);
		
		if (commandSelector != 0)
		{
			if ([self respondsToSelector: commandSelector])
			{
				[self performSelector: commandSelector withObject: arguments];
			}
			else
			{
				commandSelector = 0;
			}
		}
		if (commandSelector == 0)
		{
			[self writeString: @"%@ %@", substring, arguments]; 
		}
		return;
	}

	if (current == console)
	{
		[self putMessage: @"Join a channel first.\n" in: console];
		return;
	}

	[self putMessage: [NSString stringWithFormat: @"<%@> %@\n", nick, command]
	  in: nil];
	
	[self sendMessage: command to: [current identifier]];
}
- (void)commandMe: (NSString *)argument
{
	if (current == console)
	{
		[self putMessage: @"Join a channel first.\n" in: console];
		return;
	}

	[self putMessage: [NSString stringWithFormat: @"* %@ %@\n", nick, argument]
	  in: nil];
	
	[self sendAction: argument to: [current identifier]];
}
- (void)commandPart: (NSString *)argument
{
	id array;
	int x;

	array = SeparateIntoNumberOfArguments(argument, 2);

	x = [array count];
	if (x == 0)
	{
		[self putMessage: @"Usage: /part <channel> |<message>|" 
		  in: nil];
	}
	else if (x == 1)
	{
		[self partChannel: [array objectAtIndex: 0] withMessage: nil];
	}
	else
	{
		[self partChannel: [array objectAtIndex: 0] withMessage:
		  [array objectAtIndex: 1]];
	}
}
- (void)commandMsg: (NSString *)argument
{
	id array;

	array = SeparateIntoNumberOfArguments(argument, 2);

	if ([array count] < 2)
	{
		[self putMessage: @"Usage: /msg <destination> <message>" 
		  in: nil];
	}
	else
	{
		id object;
		id message = [array objectAtIndex: 1];
		id to = [array objectAtIndex: 0];
		
		if ((object = [nameToTalk objectForKey: to]))
		{
			[self putMessage: [NSString stringWithFormat: @"<%@> %@",
			    nick, message]
			  in: object];
		}
		else
		{
			[self putMessage: [NSString stringWithFormat: @">%@< %@", 
			    to, message]
			  in: nil];
		}
		
		[self sendMessage: message to: to];
	}
}
- (void)commandQuit: (NSString *)arguments
{
	[self quitWithMessage: arguments];
}
- (void)commandClose: (NSString *)command
{
	id array;
	id view;
	BOOL in = YES;
	
	array = SeparateIntoNumberOfArguments(command, 2);
	
	if ([array count] == 0)
	{
		view = current;
		if ([nameToDeadChannel objectForKey: [current identifier]]) in = NO;
	}
	else
	{
	
		command = [array objectAtIndex: 0];
		
		if (!(view = [nameToTalk objectForKey: [command lowercaseIRCString]]))
		{
			in = NO;
			
			if (!(view = [nameToDeadChannel objectForKey: 
			  [command lowercaseIRCString]]))
			{
				[self putMessage: @"Usage: /close |tab name|" in: nil];
				return;
			}
		}
	}
	if (view == console)
	{
		[self putMessage: @"You can't close that." in: nil];
		return;
	}
	
	if ([view isKindOfClass: [ChannelController class]] && in)
	{
		[self partChannel: [view identifier] withMessage: nil];
	}
	
	[self removeTabViewItemWithName: [view identifier]];
}
- (void)commandQuery: (NSString *)command
{
	id array;
	id name;
	id tab;
	id view;
	
	array = SeparateIntoNumberOfArguments(command, 2);
	if ([array count] == 0)
	{
		[self putMessage: @"Usage: /query <nick>" in: nil];
		return;
	}
	
	command = [array objectAtIndex: 0];
	
	name = [command lowercaseIRCString];
	
	if ([nameToTalk objectForKey: name])
	{
		return;
	}
		
	view = AUTORELEASE([QueryController new]);
	
	tab = [self addTabViewItemWithName: name withView: view];
	[nameToTypedName setObject: command forKey: name];

	[self setLabel: command forView: view];
	
	[[window tabView] selectTabViewItem: tab];
}
- (void)commandClear: (NSString *)command
{
	[[[current talkView] textStorage] setAttributedString: 
	  AUTORELEASE([[NSAttributedString alloc] initWithString: @""])];
}	  
- (void)commandCtcp: (NSString *)command
{
	id array;
	id ctcp;
	id args;
	id who;
	
	array = SeparateIntoNumberOfArguments(command, 3);
	
	if ([array count] <= 1)
	{
		[self putMessage: @"Usage: /ctcp <nick> <ctcp> |args|" in: nil];
		return;
	}

	if ([array count] == 3)
	{
		args = [array objectAtIndex: 2];
	}
	else
	{
		args = nil;
	}
	
	ctcp = [[array objectAtIndex: 1] uppercaseIRCString];
	who = [array objectAtIndex: 0];

	if (args)
	{
		[self putMessage: [NSString stringWithFormat:
		  @">%@< CTCP %@ %@", who, ctcp, args] in: nil];
	}
	else
	{
		[self putMessage: [NSString stringWithFormat:
		  @">%@< CTCP %@", who, ctcp] in: nil];
	}
	
	[self sendCTCPRequest: ctcp withArgument: args
	  to: who];
}	
- (void)commandVersion: (NSString *)command
{
	id array;
	id who;
	
	array = SeparateIntoNumberOfArguments(command, 2);

	if ([array count] == 0)
	{
		[self putMessage: @"Usage: /version <nick>" in: nil];
		return;
	}

	who = [array objectAtIndex: 0];
	
	[self putMessage: [NSString stringWithFormat: @">%@< CTCP VERSION", who]
	  in: nil];

	[self sendCTCPRequest: @"VERSION" withArgument: nil
	  to: who];
}
- (void)commandClientinfo: (NSString *)command
{
	id array;
	id who;
	
	array = SeparateIntoNumberOfArguments(command, 2);

	if ([array count] == 0)
	{
		[self putMessage: @"Usage: /clientinfo <nick>" in: nil];
		return;
	}

	who = [array objectAtIndex: 0];
	
	[self putMessage: [NSString stringWithFormat: @">%@< CTCP CLIENTINFO", who]
	  in: nil];

	[self sendCTCPRequest: @"CLIENTINFO" withArgument: nil
	  to: who];
}
- (void)commandUserinfo: (NSString *)command
{
	id array;
	id who;
	
	array = SeparateIntoNumberOfArguments(command, 2);

	if ([array count] == 0)
	{
		[self putMessage: @"Usage: /userinfo <nick>" in: nil];
		return;
	}

	who = [array objectAtIndex: 0];
	
	[self putMessage: [NSString stringWithFormat: @">%@< CTCP USERINFO", who]
	  in: nil];

	[self sendCTCPRequest: @"USERINFO" withArgument: nil
	  to: who];
}
- (void)commandServer: (NSString *)command
{
	id array;
	NSHost *host;

	array = SeparateIntoNumberOfArguments(command, 3);

	if ([array count] == 0)
	{
		[self putMessage: @"Usage: /server <server> |port|" in: nil];
		return;
	}

	if ([array count] >= 2)
	{
		typedPort = [[array objectAtIndex: 1] intValue];
	}
	else
	{
		typedPort = 6667;
	}
	
	if (transport)
	{
		[[NetApplication sharedInstance] disconnectObject: self];
		if (transport)
		{
			[NSException raise: FatalNetException format: 
			  @"[ConnectionController commandServer: %@] How did I get here?",
			  command];
		}
	}

	RELEASE(typedHost);
	typedHost = RETAIN([array objectAtIndex: 0]);
	
	[self putMessage: [NSString stringWithFormat: @"Looking up %@..", 
	  typedHost] in: console];
	
	[NSHost setHostCacheEnabled: NO];
	host = [NSHost hostWithName: typedHost];
	[NSHost setHostCacheEnabled: YES];

	[self putMessage: [NSString stringWithFormat: 
	  @"Connecting to %@ (%@) port %d..", [host name], [host address], 
	    typedPort] in: console];
	
	[[TCPSystem sharedInstance] connectNetObjectInBackground: self
	  toHost: host
	  onPort: typedPort withTimeout: 30];
}
- (void)commandReconnect: (NSString *)command
{
	NSArray *array;
	NSHost *host;
		
	if (!typedHost)
	{
		typedHost = [[NSString alloc] initWithString: @"irc.freenode.net"];
		typedPort = 6667;
	}

	if (transport)
	{
		array = [nameToChannel allKeys];
		[[NetApplication sharedInstance] disconnectObject: self];
		if (transport)
		{
			[NSException raise: FatalNetException format:
			  @"[ConnectionController commandReconnect] How did I get here?"];
		}
	}
	else
	{
		array = [nameToDeadChannel allKeys];
	}
	
	[self putMessage: [NSString stringWithFormat: @"Looking up %@..", 
	  typedHost] in: console];
	
	[NSHost setHostCacheEnabled: NO];
	host = [NSHost hostWithName: typedHost];
	[NSHost setHostCacheEnabled: YES];

	[self putMessage: [NSString stringWithFormat: 
	  @"Connecting to %@ (%@) port %d..", [host name], [host address], 
	    typedPort] in: console];
	
	[[TCPSystem sharedInstance] connectNetObjectInBackground: self
	  toHost: host
	  onPort: typedPort withTimeout: 30];			  

	[self resetConnectCommands];
	
	if ([array count] >= 1)
	{
		[self addConnectCommand: [NSString stringWithFormat: @"/join %@",
		  [array componentsJoinedByString: @","]]];
	}
}
- (void)commandNick: (NSString *)command
{
	id array;

	array = SeparateIntoNumberOfArguments(command, 2);
	
	if ([array count] == 0)
	{
		[self putMessage: @"Usage: /nick <nickname>" in: nil];
	}
	
	if (transport)
	{
		[self changeNick: [array objectAtIndex: 0]];
	}
	else
	{
		[self setNickname: [array objectAtIndex: 0]];
		[window updateNick: nick];
	}
}
@end

#define IS_ME(_x) \
       ([ExtractIRCNick(_x) caseInsensitiveIRCCompare: nick] == NSOrderedSame)

@implementation ConnectionController (IRCHandler)
- registeredWithServer
{
	id object;
	NSEnumerator *iter;

	iter = [[NSArray arrayWithArray: connectCommands] objectEnumerator];

	while ((object = [iter nextObject]))
	{
		[self lineTyped: object];
	}

	[connectCommands removeAllObjects];

	[window updateNick: nick];
	return self;
}
- errorReceived: (NSString *)anError
{
	[self putMessage: [NSString stringWithFormat: @"ERROR: %@", anError] 
	   in: [nameToTalk allValues]];
	
	return self;
}
- wallopsReceived: (NSString *)message from: (NSString *)sender
{
	[self putMessage: [NSString stringWithFormat: @"-%@/Wallops- %@", 
	  ExtractIRCNick(sender), message] in: console];
	
	return self;
}
- userKicked: (NSString *)aPerson outOf: (NSString *)aChannel
         for: (NSString *)reason from: (NSString *)kicker
{
	id channelKey = [aChannel lowercaseIRCString];
	id cont = [nameToChannel objectForKey: channelKey];
	
	if (IS_ME(aPerson))
	{
		[self putMessage: [NSString stringWithFormat:  
		  @"You were kicked out of %@ by %@ (%@)", aChannel,
		    ExtractIRCNick(kicker), reason] in: nil];
	
		[self setLabel: [NSString stringWithFormat: @"(%@)", aChannel] 
		       forView: cont];
		
		[nameToDeadChannel setObject: cont forKey: channelKey];
		
		[nameToChannel removeObjectForKey: channelKey];
		[nameToTalk removeObjectForKey: channelKey];
		
		[[cont userTable] setDataSource: nil];
		[nameToChannelData removeObjectForKey: channelKey];
	}
	else
	{
		id data = [nameToChannelData objectForKey: channelKey];
		
		aChannel = [nameToTypedName objectForKey: channelKey];
		
		[self putMessage: [NSString stringWithFormat:
		 @"%@ was kicked from %@ by %@ (%@)", aPerson, aChannel,
		   ExtractIRCNick(kicker),
		   reason] in: cont];
		 
		[data removeUser: aPerson];

		[[cont userTable] reloadData];
	}
	return self;
}
- invitedTo: (NSString *)aChannel from: (NSString *)inviter
{
	[self putMessage: [NSString stringWithFormat: 
	  @"You have been invited to %@ by %@", aChannel,
	    ExtractIRCNick(inviter)]
	  in: nil];
	
	return self;
}
- numericCommandReceived: (NSString *)command withParams: (NSArray *)paramList
     from: (NSString *)sender
{
	SEL sel = NSSelectorFromString([NSString stringWithFormat: 
	  @"numericHandler%@:", command]);
	
	if (sel == 0) 
	{
		[self putMessage: [paramList componentsJoinedByString: @" "] 
		  in: console];
	}
	else if ([self respondsToSelector: sel])
	{
		if (![self performSelector: sel withObject: paramList])
		{
			[self putMessage: [paramList componentsJoinedByString: @" "]
			  in: console];
		}
	}

	if ([command caseInsensitiveIRCCompare: @"001"] == NSOrderedSame)
	{
		RELEASE(currentHost);
		currentHost = RETAIN(sender);
		[self updateHostName];
	}
	
	return self;
}
- nickChangedTo: (NSString *)newName from: (NSString *)aPerson
{
	NSEnumerator *iter;
	id object;
	NSString *string;
	id oldNick = ExtractIRCNick(aPerson);

	if (IS_ME(newName))
	{
		string = [NSString stringWithFormat: @"You are now known as %@", 
		  newName];
		[window updateNick: newName];
	}
	else
	{
		string = [NSString stringWithFormat: @"%@ is now known as %@",
		  oldNick, newName];
	}
	
	iter = [[self channelsWithUser: oldNick] objectEnumerator];
	while ((object = [iter nextObject]))
	{
		[object userRenamed: oldNick to: newName];
		[[[nameToChannel objectForKey: [object identifier]] userTable]
		   reloadData];
		[self putMessage: string in: object];
	}

	return self;
}
- channelJoined: (NSString *)channel from: (NSString *)joiner
{	
	id channelKey = [channel lowercaseIRCString];
	if (IS_ME(joiner))
	{
		id tab;
		Channel *data;
		ChannelController *temp;
		
		if ((temp = [nameToDeadChannel objectForKey: channelKey]))
		{
			[nameToChannel setObject: temp forKey: channelKey];
			[nameToTalk setObject: temp forKey: channelKey];
			
			[nameToDeadChannel removeObjectForKey: channelKey];
			
			[nameToTypedName setObject: channel forKey: channelKey];
			
			tab = NSMapGet(talkToHolder, temp);
			if (![tab isKindOfClass: [ColoredTabViewItem class]])
			{
				tab = nil;
			}
		}
		else
		{
			temp = [ChannelController new];
			[temp setIdentifier: channelKey];
		
			if ([nameToQuery objectForKey: channelKey])
			{
				[self removeTabViewItemWithName: channelKey];
			}
			
			tab = [self addTabViewItemWithName: channelKey withView: temp];
			
			[nameToTypedName setObject: channel forKey: channelKey];
		}
		
		data = AUTORELEASE([Channel new]);
		[data setIdentifier: channelKey];
		
		[nameToChannelData setObject: data forKey: channelKey];

		[[temp userTable] setDataSource: data];
		
		[self setLabel: channel forView: temp];
	
		if (tab)
		{
			[[window tabView] selectTabViewItem: tab];
		}
	}
	else
	{
		[[nameToChannelData objectForKey: channelKey]
		  addUser: ExtractIRCNick(joiner)];

		[[[nameToChannel objectForKey: channelKey]
		  userTable] reloadData];
	}
		   
	channel = [nameToTypedName objectForKey: channelKey];

	[self putMessage: [NSString stringWithFormat: @"%@ (%@) has joined %@", 
	    ExtractIRCNick(joiner), ExtractIRCHost(joiner), channel] in: 
	  channel];

	return self;
}
- channelParted: (NSString *)channel withMessage: (NSString *)aMessage
    from: (NSString *)parter
{
	id channelKey = [channel lowercaseIRCString];
	id cont = [nameToChannel objectForKey: channelKey];
	
	if (!cont) return self;

	if (IS_ME(parter))
	{
		[self putMessage: [NSString stringWithFormat:  
		  @"You have left %@ (%@)", channel, aMessage] in: cont];
	
		[self setLabel: [NSString stringWithFormat: @"(%@)", channel] 
		       forView: cont];
		[nameToTypedName setObject: channel forKey: channelKey];
	
		[nameToDeadChannel setObject: cont forKey: channelKey];
		
		[nameToChannel removeObjectForKey: channelKey];
		[nameToTalk removeObjectForKey: channelKey];
		
		[[cont userTable] setDataSource: nil];
		[nameToChannelData removeObjectForKey: channelKey];
	}
	else
	{
		id data = [nameToChannelData objectForKey: channelKey];
	
		channel = [nameToTypedName objectForKey: channelKey];
		
		[self putMessage: [NSString stringWithFormat:
		 @"%@ has left %@ (%@)", ExtractIRCNick(parter), channel,
		   aMessage] in: cont];
		 
		[data removeUser: ExtractIRCNick(parter)];
		
		[[cont userTable] reloadData];
	}
	return self;
}
- quitIRCWithMessage: (NSString *)aMessage from: (NSString *)quitter
{
	NSEnumerator *iter;
	id object;
	NSString *string;
	NSString *who = ExtractIRCNick(quitter);

	string = [NSString stringWithFormat: @"%@ has quit (%@)", 
	  who, aMessage];
	
	iter = [[self channelsWithUser: who] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[object removeUser: who];
		[[[nameToChannel objectForKey: [object identifier]] userTable]
		  reloadData];
		
		[self putMessage: string in: object];
		
	}
	
	return self;
}
- messageReceived: (NSString *)aMessage to: (NSString *)to
   from: (NSString *)sender
{
	id toKey = [to lowercaseIRCString];
	id fromNick = ExtractIRCNick(sender);
	id fromKey = [fromNick lowercaseIRCString];
	id target;

	target = [nameToChannel objectForKey: toKey];
	if (!target)
	{
		target = [nameToQuery objectForKey: fromKey];
	}

	if (!fromNick)
	{
		[self putMessage: aMessage in: console];
	}
	
	if (target)
	{
		[self putMessage: [NSString stringWithFormat: 
		  @"<%@> %@", fromNick, aMessage] in: target];
	}
	else
	{
		[self putMessage: [NSString stringWithFormat:
		  @"*%@* %@", fromNick, aMessage] in: nil];
	}

	return self;
} 
- noticeReceived: (NSString *)aMessage to: (NSString *)to
   from: (NSString *)sender
{
	id toKey = [to lowercaseIRCString];
	id fromNick = ExtractIRCNick(sender);
	id fromKey = [sender lowercaseIRCString];
	id target;

	target = [nameToChannel objectForKey: toKey];
	if (!target)
	{
		if (IS_ME(to))
		{
			target = [nameToQuery objectForKey: fromKey];
		}
	}


	if (target)
	{
		[self putMessage: [NSString stringWithFormat: 
		  @"<%@> %@", fromNick, aMessage] in: target];
	}
	else
	{
		if (IS_ME(to))
		{
			if (fromNick)
			{
				[self putMessage: [NSString stringWithFormat:
				  @"*%@* %@", fromNick, aMessage] in: nil];
			}
			else
			{
				[self putMessage: [NSString stringWithFormat:
				  @"%@", aMessage] in: console];
			}
		}
		else
		{
			[self putMessage: [NSString stringWithFormat:
			  @"%@ :%@", to, aMessage] in: console];
		}
	}

	return self;
}
- actionReceived: (NSString *)aMessage to: (NSString *)to
   from: (NSString *)sender
{
	id toKey = [to lowercaseIRCString];
	id fromNick = ExtractIRCNick(sender);
	id fromKey = [sender lowercaseIRCString];
	id target;

	target = [nameToChannel objectForKey: toKey];
	if (!target)
	{
		target = [nameToQuery objectForKey: fromKey];
	}

	if (target)
	{
		[self putMessage: [NSString stringWithFormat: 
		  @"* %@ %@", fromNick, aMessage] in: target];
	}
	else
	{
		[self putMessage: [NSString stringWithFormat:
		  @"* %@ %@", fromNick, aMessage] in: console];
	}

	return self;
}
@end

#undef IS_ME

// These can return anything, but if they return nil, the 
// command will also be printed to the console
@implementation ConnectionController (NumberCommandHandler)
// RPL_NAMREPLY
- numericHandler353: (NSArray *)arguments
{
	id channel = [nameToChannelData objectForKey: [[arguments objectAtIndex: 1]
	  lowercaseIRCString]];

	if (!channel)
	{
		return nil;
	}

	[channel addServerUserList: [arguments objectAtIndex: 2]];

	return self;
}
// RPL_ENDOFNAMES
- numericHandler366: (NSArray *)arguments
{
	id name = [[arguments objectAtIndex: 0] lowercaseIRCString];
	id cont = [nameToChannel objectForKey: name];
	id channel = [nameToChannelData objectForKey: name];

	if (!channel)
	{
		return nil;
	}

	[channel endServerUserList];

	[[cont userTable] reloadData]; 

	return self;
}
// RPL_TOPIC
- numericHandler332: (NSArray *)arguments
{
	id channel = [arguments objectAtIndex: 0];
	
	[self putMessage: [NSString stringWithFormat:
	  @"Topic for %@ is \"%@\"", channel, [arguments objectAtIndex: 1]] 
	  in: channel];

	return self;
}
// RPL_TOPIC (extension???)
- numericHandler333: (NSArray *)arguments
{
	id channel = [arguments objectAtIndex: 0];
	id who = [arguments objectAtIndex: 1];
	double secs = [[arguments objectAtIndex: 2] doubleValue];
	id date = [NSDate dateWithTimeIntervalSince1970: secs];

	[self putMessage: [NSString stringWithFormat:
	 @"Topic for %@ set by %@ at %@", channel, who, 
	 [date descriptionWithCalendarFormat: @"%a %b %e %H:%M:%S"
	   timeZone: nil locale: nil]] in: channel];
	
	return self;
}
@end

@implementation ConnectionController (CTCPHandler)
- CTCPRequestPING: (NSString *)argument from: (NSString *)aPerson
{
	[self sendCTCPReply: @"PING" withArgument: argument 
	  to: ExtractIRCNick(aPerson)];
	
	[self putMessage: [NSString stringWithFormat:
	 @"Received a CTCP PING from %@", ExtractIRCNick(aPerson)] in: console];
	
	return self;
}
- CTCPRequestVERSION: (NSString *)query from: (NSString *)aPerson
{
	[self sendCTCPReply: @"VERSION" withArgument:
	  [NSString stringWithFormat: @"%@ %@ on %@", @"TalkSoup.app",
	    version_number, @"GNUstep CVS"]
	  to: ExtractIRCNick(aPerson)];

	return nil;
}
- CTCPRequestCLIENTINFO: (NSString *)query from: (NSString *)aPerson
{
	[self sendCTCPReply: @"CLIENTINFO" withArgument: 
	  @"TalkSoup can be obtained from 1 of 4 places: "
	  @"http://linuks.mine.nu/andy/ "
	  @"http://www.freshmeat.net/talksoup/ "
	  @"http://beregorn.homelinux.com or "
	  @"http://andyruder.tripod.com "
	  @"in order of preference."
	 to: ExtractIRCNick(aPerson)];

	return nil;
}
- CTCPRequestXYZZY: (NSString *)query from: (NSString *)aPerson
{
	[self sendCTCPReply: @"XYZZY" withArgument:
	  @"Nothing happened." to: ExtractIRCNick(aPerson)];
	
	return nil;
}
- CTCPRequestRFM: (NSString *)query from: (NSString *)aPerson
{
	[self sendCTCPReply: @"RFM" withArgument:
	  @"Problems? Blame RFM." to: ExtractIRCNick(aPerson)];

	return nil;
}
- CTCPRequestReceived: (NSString *)aCTCP
   withArgument: (NSString *)argument from: (NSString *)aPerson
{
	SEL sid = NSSelectorFromString([NSString stringWithFormat: 
	   @"CTCPRequest%@:from:", [aCTCP uppercaseIRCString]]);
	BOOL show = YES;
	
	if (sid)
	{
		if ([self respondsToSelector: sid])
		{
			show = ([self performSelector: sid withObject: argument
			          withObject: aPerson] == nil);
		}
	}
	
	if (show)
	{
		if ([argument length])
		{
			[self putMessage: [NSString stringWithFormat:
			 @"Received a CTCP '%@ %@' from %@", aCTCP, argument,
			  ExtractIRCNick(aPerson)] in: console];
	 	}
		else
		{
			[self putMessage: [NSString stringWithFormat:
			 @"Received a CTCP %@ from %@", aCTCP,
			  ExtractIRCNick(aPerson)] in: console];
		}
	}
	return self;
}
- CTCPReplyReceived: (NSString *)aCTCP
   withArgument: (NSString *)argument from: (NSString *)aPerson
{
	SEL sid = NSSelectorFromString([NSString stringWithFormat: 
	   @"CTCPReply%@:from:", [aCTCP uppercaseIRCString]]);
	BOOL show = YES;
	
	if (sid)
	{
		if ([self respondsToSelector: sid])
		{
			show = ([self performSelector: sid withObject: argument
			          withObject: aPerson] == nil);
		}
	}
	
	if (show)
	{
		if ([argument length])
		{
			[self putMessage: [NSString stringWithFormat:
			 @"-%@- %@ %@", ExtractIRCNick(aPerson), aCTCP, 
			  argument] in: nil];
	 	}
		else
		{
			[self putMessage: [NSString stringWithFormat:
			 @"-%@- %@", ExtractIRCNick(aPerson), aCTCP,
			  ExtractIRCNick(aPerson)] in: nil];
		}
	}
	return self;
}
@end

