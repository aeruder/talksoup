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

#import "Controllers/ChannelViewController.h"
#import "Controllers/ConnectionController.h"
#import "Windows/ChannelWindow.h"
#import "Views/ChannelView.h"
#import "Views/ConsoleView.h"
#import "Misc/Functions.h"
#import "Models/Channel.h"
#import "TalkSoup.h"

#import <Foundation/NSNotification.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSBundle.h>
#import <AppKit/NSTabViewItem.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSView.h>
#import <AppKit/NSScrollView.h>

static NSMapTable *command_to_selector = 0;
static NSString *version_number = nil;

NSArray *SeparateOutFirstWord(NSString *argument)
{
	NSRange aRange;
	NSString *first;
	NSString *rest;

	argument = [argument stringByTrimmingCharactersInSet:
	  [NSCharacterSet whitespaceCharacterSet]];
	  
	if ([argument length] == 0)
	{
		return nil;
	}

	aRange = [argument rangeOfString: @" "];

	if (aRange.location == NSNotFound && aRange.length == 0)
	{
		return [NSArray arrayWithObjects: argument, nil];
	}
	
	rest = [[argument substringFromIndex: aRange.location]
	  stringByTrimmingCharactersInSet:
	    [NSCharacterSet whitespaceCharacterSet]];
	
	first = [argument substringToIndex: aRange.location];

	return [NSArray arrayWithObjects: first, rest, nil];
}

@interface ConnectionController (IRCHandler)
@end

@interface ConnectionController (CTCPHandler)
@end

@interface ConnectionController (WindowDelegate)
@end

@interface ConnectionController (TabViewItemDelegate)
@end

@interface ConnectionController (NumberCommandHandler)
@end

@interface ConnectionController (CommandHandler)
- (void)commandReceived: (NSString *)command;
- (void)commandPart: (NSString *)command;
- (void)commandQuit: (NSString *)command;
- (void)commandMsg: (NSString *)command;
- (void)commandClose: (NSString *)command;
- (void)commandQuery: (NSString *)command;
@end

@implementation ConnectionController
+ (void)initialize
{
	command_to_selector = NSCreateMapTable(NSObjectMapKeyCallBacks,
	  NSIntMapValueCallBacks, 7);
	
	NSMapInsert(command_to_selector, @"quit", @selector(commandQuit:));
	NSMapInsert(command_to_selector, @"part", @selector(commandPart:));
	NSMapInsert(command_to_selector, @"me", @selector(commandMe:));
	NSMapInsert(command_to_selector, @"msg", @selector(commandMsg:));
	NSMapInsert(command_to_selector, @"close", @selector(commandClose:));
	NSMapInsert(command_to_selector, @"query", @selector(commandQuery:));
	//NSMapInsert(command_to_selector, @"server", @selector(commandServer:));
	
	version_number =  RETAIN([[[NSBundle mainBundle] infoDictionary] 
	  objectForKey: @"ApplicationRelease"]);
}	
- init
{
	id temp;
	
	if (!(self = [super initWithNickname: @"TalkSoup"
	  withUserName: nil withRealName: nil withPassword: nil])) return nil;
	
	[[TalkSoup sharedInstance] addConnection: self];
	
	window = [ChannelWindow new];
	[window setDelegate: self];
	[[window tabView] setDelegate: self];
	[window setTitle: @"Unconnected"];
	
	temp = [window typeView];
	[temp setAction: @selector(commandReceived:)];
	[temp setTarget: self];

	nameToChannel = [NSMutableDictionary new];
	nameToDeadChannel = [NSMutableDictionary new];
	
	console = RETAIN([self addTabWithName: nil withLabel: @"Unconnected"
	  withUserList: NO]);
	
	[window makeKeyAndOrderFront: nil];
	
	return self;
}
- (void)dealloc
{
	DESTROY(console);
	DESTROY(current);
	
	[window setDelegate: nil];
	[[window tabView] setDelegate: nil];
	
	DESTROY(window);
	DESTROY(connecting);
	DESTROY(nameToChannel);

	[super dealloc];
}
- connectionEstablished: aTransport
{
	id object = [aTransport address];
	[console setTabLabel: object];
	[window setTitle: object];
	DESTROY(connecting);

	return [super connectionEstablished: aTransport];
}	
- connectingStarted: (TCPConnecting *)aConnection
{
	[window setTitle: @"Connecting..."];
	connecting = RETAIN(aConnection);
	
	return self;
}
- connectingFailed: (NSString *)aReason
{
	DESTROY(connecting);

	return self;
}
/*
- (void)connectionLost
{
	NSEnumerator *iter;
	id object;
	
	NSLog(@"Blah");
	[self putMessage: @"Disconnected..." inChannel: console];
	[self putMessage: @"Disconnected..." inChannel: [nameToChannel allValues]];
	[self putMessage: @"Disconnected..." inChannel: 
	   [nameToDeadChannel allValues]];
	[window setTitle: @"Unconnected"];
	NSLog(@"Blah 2");
	
	[super connectionLost];
	
	NSLog(@"Blah 3");
	if (nextServer)
	{
		iter = [[nameToChannel allValues] objectEnumerator];
		while ((object = [iter nextObject]))
		{
			[object setTabItem: nil];
		}

		iter = [[nameToDeadChannel allValues] objectEnumerator];
		while ((object = [iter nextObject]))
		{
			[object setTabItem: nil];
		}

		[nameToChannel removeAllObjects];
		[nameToDeadChannel removeAllObjects];
		
		[[TCPSystem sharedInstance] connectNetObjectInBackground: self
		  toHost: nextServer onPort: 6667 withTimeout: 30];

		DESTROY(nextServer);
	}
	NSLog(@"Blah 4");
}
*/
- putMessage: (NSString *)message inChannel: channel
{
	id view = nil;
	
	if (![message hasSuffix: @"\n"])
	{
		message = [message stringByAppendingString: @"\n"];
	}
	
	if ([channel isKindOf: [ChannelViewController class]])
	{
		view = channel;
	}
	else if ([channel isKindOf: [NSString class]])
	{
		view = [nameToChannel objectForKey: [channel lowercaseIRCString]];
	}
	else if ([channel isKindOf: [NSArray class]])
	{
		id object;
		NSEnumerator *iter;

		iter = [channel objectEnumerator];
		while ((object = [iter nextObject]))
		{
			[self putMessage: message inChannel: object];
		}
	}
	else if ([channel isKindOf: [Channel class]])
	{
		view = [nameToChannel objectForKey: [[(Channel *)channel name] 
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

	[view putMessage: message];
	
	return self;
}
- (ChannelViewController *)addTabWithName: (NSString *)aName 
    withLabel: (NSString *)aLabel withUserList: (BOOL)flag
{
	id tab = AUTORELEASE([NSTabViewItem new]);
	id view = AUTORELEASE(((flag) ? [ChannelView new] : [ConsoleView new]));
	ChannelViewController *cont = AUTORELEASE([ChannelViewController new]);

	if (aName)
	{
		[nameToChannel setObject: cont forKey: aName];
	}

	[cont setName: aName];
	
	[[window tabView] addTabViewItem: tab];
	[cont setTabItem: tab];
	[cont setTabLabel: aLabel];
	[cont setView: view];
	
	return cont;
}
- (void)removeTabWithName: (NSString *)aName
{
	id cont = [nameToChannel objectForKey: aName];
	id tab = [cont tabItem];
	id tabView = [window tabView];
	
	if (current == cont)
	{
		[tabView selectPreviousTabViewItem: self];
	}

	[tabView removeTabViewItem: tab];
	[tabView setNeedsDisplay: YES];

	[cont setTabItem: nil];

	[cont setChannelModel: nil];
	[cont reloadUserList];

	[nameToChannel removeObjectForKey: aName];
	[nameToDeadChannel removeObjectForKey: aName];
}
- (ChannelWindow *)window
{
	return window;
}
- (NSArray *)channelsWithUser: (NSString *)aUser
{
	id object;
	NSEnumerator *iter;
	NSMutableArray *list = AUTORELEASE([NSMutableArray new]);

	iter = [[nameToChannel allValues] objectEnumerator];

	while ((object = [iter nextObject]))
	{
		if ([[object channelModel] containsUser: aUser])
		{
			[list addObject: object];
		}
	}

	return [NSArray arrayWithArray: list];
}
@end

@implementation ConnectionController (WindowDelegate)
- (void)windowWillClose: (NSNotification *)aNotification
{
	if (window != [aNotification object]) return;
	[window setDelegate: nil];
	[[window tabView] setDelegate: nil];

	[[NetApplication sharedInstance] disconnectObject: self];
	[[TalkSoup sharedInstance] removeConnection: self];
}
- (void)windowDidBecomeKey: (NSNotification *)aNotification
{
	if (window != [aNotification object]) return;
	[window makeFirstResponder: [window typeView]];
}
@end

@implementation ConnectionController (WindowTabViewDelegate)
- (void)tabView:(NSTabView *)tabView 
     didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	RELEASE(current);
	current = RETAIN([ChannelViewController lookupByTab: tabViewItem]);
}
@end

// These can return anything, but if they return nil, the 
// command will also be printed to the console
@implementation ConnectionController (NumberCommandHandler)
// RPL_NAMREPLY
- numericHandler353: (NSArray *)arguments
{
	NSLog(@"353: %@", arguments);
	id channel = [[nameToChannel objectForKey: [[arguments objectAtIndex: 1]
	  lowercaseIRCString]] channelModel];

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
	NSLog(@"366: %@", arguments);
	id name = [[arguments objectAtIndex: 0] lowercaseIRCString];
	id cont = [nameToChannel objectForKey: name];
	id channel = [cont channelModel];

	if (!channel)
	{
		return nil;
	}

	[channel endServerUserList];

	[cont reloadUserList];

	return self;
}
@end

@implementation ConnectionController (CommandHandler)
- (void)commandReceived: (id)sender
{
	id command = AUTORELEASE(RETAIN([sender stringValue]));
	[sender setStringValue: @""];
	[window makeFirstResponder: sender];

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
		
		array = SeparateOutFirstWord(command);

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
		commandSelector = NSMapGet(command_to_selector, substring);

		if (commandSelector != 0)
		{
			[self performSelector: commandSelector withObject: arguments];
		}
		else
		{
			[self writeString: @"%@ %@", substring, arguments]; 
		}
		return;
	}

	if (current == console)
	{
		[self putMessage: @"Join a channel first.\n" inChannel: console];
		return;
	}

	[self putMessage: [NSString stringWithFormat: @"<%@> %@\n", nick, command]
	  inChannel: nil];
	
	
	[self sendMessage: command to: [current name]];
}
- (void)commandServer: (NSString *)command
{
	id array;

	array = SeparateOutFirstWord(command);

	if ([array count] == 0)
	{
		[self putMessage: @"Usage: /server <server>"
		  inChannel: nil];
	}
	else
	{
		if (connected)
		{
			[self quitWithMessage: nil];
			nextServer = [[NSString alloc] 
			  initWithString: [array objectAtIndex: 0]];
		}
	}
}
- (void)commandPart: (NSString *)argument
{
	id array;
	int x;

	array = SeparateOutFirstWord(argument);

	x = [array count];
	if (x == 0)
	{
		[self putMessage: @"Usage: /part <channel> |<message>|" 
		  inChannel: nil];
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

	array = SeparateOutFirstWord(argument);

	if ([array count] < 2)
	{
		[self putMessage: @"Usage: /msg <destination> <message>" 
		  inChannel: nil];
	}
	else
	{
		id object;
		id message = [array objectAtIndex: 1];
		id to = [array objectAtIndex: 0];
		
		if ((object = [nameToChannel objectForKey: to]))
		{
			[self putMessage: [NSString stringWithFormat: @"<%@> %@",
			    nick, message]
			  inChannel: object];
		}
		else
		{
			[self putMessage: [NSString stringWithFormat: @">%@< %@", 
			    to, message]
			  inChannel: nil];
		}
		
		[self sendMessage: message to: to];
	}
}
- (void)commandQuit: (NSString *)arguments
{
	[self quitWithMessage: arguments];
}
- (void)commandMe: (NSString *)argument
{
	if (current == console)
	{
		[self putMessage: @"Join a channel first.\n" inChannel: console];
		return;
	}

	[self putMessage: [NSString stringWithFormat: @"* %@ %@\n", nick, argument]
	  inChannel: nil];
	
	[self sendAction: argument to: [current name]];
}
- (void)commandClose: (NSString *)command
{
	if ([current hasUserList])
	{
		[self partChannel: [current name] withMessage: nil];
	}
	[self removeTabWithName: [current name]];
}
- (void)commandQuery: (NSString *)command
{
	id name = [command lowercaseIRCString];
	id cont = [self addTabWithName: name withLabel: command
	  withUserList: NO];
	[[window tabView] selectTabViewItem: [cont tabItem]];
}
@end

@implementation ConnectionController (IRCHandler)
- registeredWithServer
{
	[window updateNick: nick];
	return self;
}
- messageReceived: (NSString *)aMessage to: (NSString *)to
          from: (NSString *)sender
{
	id view;
	id senderNick = ExtractIRCNick(sender);
	BOOL toMe = [to caseInsensitiveIRCCompare: nick] == NSOrderedSame;
	
	view = [nameToChannel objectForKey: [to lowercaseIRCString]];
	view = (view == nil && toMe) ? [nameToChannel objectForKey: 
	  [senderNick lowercaseIRCString]] : view;

	if ((view))
	{
	
		[self putMessage: 
		  [NSString stringWithFormat: @"<%@> %@\n", senderNick,
		   aMessage] inChannel: view];
		return self;
	}
	
	if (ExtractIRCHost(sender))
	{	
		if (toMe)
		{
			[self putMessage:
			  [NSString stringWithFormat: @"*** <%@> %@\n", 
			     ExtractIRCNick(sender), aMessage] 
			   inChannel: current];
		}
		else
		{
			[self putMessage:
			  [NSString stringWithFormat: @"*** <%@:%@> %@\n",
			    ExtractIRCNick(sender), to, aMessage]
			  inChannel: current];
		}
	}
	else
	{
		[self putMessage:
		  [NSString stringWithFormat: @"%@\n", aMessage] inChannel: 
		    console];
	}

	return self;
}
- noticeReceived: (NSString *)aMessage to: (NSString *)to
    from: (NSString *)sender
{
	id view;
	BOOL toMe = [to caseInsensitiveIRCCompare: nick] == NSOrderedSame;
	NSString *senderNick = ExtractIRCNick(sender);
	
	view = [nameToChannel objectForKey: [to lowercaseIRCString]];
	view = (view == nil && toMe) ? [nameToChannel objectForKey:
	  [senderNick lowercaseIRCString]] : view;
	
	if ((view))
	{
		[self putMessage:
		  [NSString stringWithFormat: @"<%@> %@\n", senderNick,
		    aMessage] inChannel: view];
		return self;
	}
	
	if (ExtractIRCHost(sender))
	{	
		if (toMe)
		{
			[self putMessage:
			  [NSString stringWithFormat: @"*** <%@> %@\n", 
			     ExtractIRCNick(sender), aMessage] 
			   inChannel: current];
		}
		else
		{
			[self putMessage:
			  [NSString stringWithFormat: @"*** <%@:%@> %@\n",
			    ExtractIRCNick(sender), to, aMessage]
			  inChannel: current];
		}
	}
	else
	{
		if (toMe)
		{
			[self putMessage:
			  [NSString stringWithFormat: @"%@\n", aMessage] inChannel: 
			    console];
		}
		else
		{
			[self putMessage:
			  [NSString stringWithFormat: @"%@ :%@\n", to, aMessage]
			   inChannel: console];
		}
	}

	return self;
}
- actionReceived: (NSString *)anAction to: (NSString *)to
    from: (NSString *)sender
{
	id view;

	if ((view = [nameToChannel objectForKey: [to lowercaseIRCString]]))
	{
		[self putMessage:
		  [NSString stringWithFormat: @"* %@ %@\n", ExtractIRCNick(sender),
		   anAction] inChannel: view];
		return self;
	}

	if (sender)
	{
		[self putMessage:
		 [NSString stringWithFormat: @"*** * %@ %@\n", ExtractIRCNick(sender),
		  anAction] inChannel: current];
	}

	return self;
}
- channelParted: (NSString *)channel withMessage: (NSString *)aMessage
   from: (NSString *)parter
{
	id channelName = [channel lowercaseIRCString];
	id channelCont = [nameToChannel objectForKey: channelName];
	id parterNick = ExtractIRCNick(parter);
	
	if ([parterNick caseInsensitiveIRCCompare: nick] 
	     == NSOrderedSame)
	{
		[channelCont setTabLabel: 
		   [NSString stringWithFormat: @"(%@)", channel]];
		
		RETAIN(channelCont);
		[nameToChannel removeObjectForKey: channelName];
		[nameToDeadChannel setObject: channelCont forKey: channelName];
		RELEASE(channelCont);
		
		[channelCont setChannelModel: nil];
		[channelCont reloadUserList];
	}
	else
	{
		[[channelCont channelModel] removeUser: parterNick];
		[channelCont reloadUserList];
	}
	
	[self putMessage:
	  [NSString stringWithFormat: @"%@ (%@) has left %@ (%@)\n", 
	   parterNick, ExtractIRCHost(parter), channel, aMessage]
	  inChannel: channelCont];
	
	return self;
}
- channelJoined: (NSString *)channel from: (NSString *)joiner
{
	id newNick = ExtractIRCNick(joiner);
	
	if ([newNick caseInsensitiveIRCCompare: nick] == NSOrderedSame)
	{
		id channelModel = AUTORELEASE([Channel new]);
		id channelName = [channel lowercaseIRCString];
		id cont;
		if ((cont = [nameToDeadChannel objectForKey: channelName]))
		{
			[cont setTabLabel: channel];
			RETAIN(cont);
			[nameToDeadChannel removeObjectForKey: channelName];
			[nameToChannel setObject: cont forKey: channelName];
			RELEASE(cont);
		}
		else
		{
			cont = [self addTabWithName: channelName
		   withLabel: channel withUserList: YES];
		}
		   
		[[window tabView] selectTabViewItem: [cont tabItem]];
		
		[channelModel setName: channel];
		[cont setChannelModel: channelModel];
	}
	else
	{
		id cont = [nameToChannel objectForKey: [channel lowercaseIRCString]];
		id model = [cont channelModel];
		[model addUser: newNick];
		
		[cont reloadUserList];
	}

	[self putMessage:
	  [NSString stringWithFormat: @"%@ (%@) has joined %@\n",
	   newNick, ExtractIRCHost(joiner), channel]
	  inChannel: channel];
	
	return self;
}
- nickChangedTo: (NSString *)newName from: (NSString *)aPerson
{
	NSEnumerator *iter;
	id object;
	id model;
		
	aPerson = ExtractIRCNick(aPerson);
	
	if ([newName caseInsensitiveIRCCompare: nick] == NSOrderedSame)
	{
		[window updateNick: newName];
	}

	iter = [[self channelsWithUser: aPerson] objectEnumerator];

	while ((object = [iter nextObject]))
	{
		model = [object channelModel];
		[model removeUser: aPerson];
		[model addUser: newName];
		[object reloadUserList];
		[self putMessage: [NSString stringWithFormat: @"%@ is now known as %@", 
		   aPerson, newName]
		  inChannel: object];
	}
	
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
		  inChannel: console];
	}
	else if ([self respondsToSelector: sel])
	{
		if (![self performSelector: sel withObject: paramList])
		{
			[self putMessage: [paramList componentsJoinedByString: @" "]
			  inChannel: console];
		}
	}
	
	return self;
}
- quitIRCWithMessage: (NSString *)aMessage from: (NSString *)quitter
{
	id object;
	NSEnumerator *iter;
	id quitNick = ExtractIRCNick(quitter);

	iter = [[self channelsWithUser: quitNick] objectEnumerator];

	while ((object = [iter nextObject]))
	{
		[[object channelModel] removeUser: quitNick];
		[object reloadUserList];
	
		[self putMessage:
		  [NSString stringWithFormat: @"%@ (%@) has quit (%@)\n", 
		   ExtractIRCNick(quitter), ExtractIRCHost(quitter), aMessage]
		  inChannel: object];
	}
	return self;
}
@end

@implementation ConnectionController (CTCPHandler)
- pingRequestReceived: (NSString *)argument from: (NSString *)aPerson
{
	[self sendPingReplyTo: ExtractIRCNick(aPerson) withArgument: argument];
	return self;
}
- versionRequestReceived: (NSString *)query from: (NSString *)aPerson
{
	[self sendVersionReplyTo: ExtractIRCNick(aPerson) name: @"TalkSoup.app"
	  version: version_number environment: @"GNUstep CVS"];
	return self;
}
- customCTCPRequestReceived: (NSString *)aCTCP
   withArgument: (NSString *)argument from: (NSString *)aPerson
{
	if ([aCTCP caseInsensitiveIRCCompare: @"XYZZY"] == NSOrderedSame)
	{
		[self sendCustomCTCP: @"XYZZY" withArgument: @"Nothing Happens."
		  to: ExtractIRCNick(aPerson)];
	}
	if ([aCTCP caseInsensitiveIRCCompare: @"RFM"] == NSOrderedSame)
	{
		[self sendCustomCTCP: @"RFM" withArgument: @"Problems?  Blame RFM."
		  to: ExtractIRCNick(aPerson)];
	}
	return self;
}
@end

