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
#import "Windows/ChannelWindow.h"
#import "Views/ChannelView.h"
#import "Misc/Functions.h"
#import "Charla.h"

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

@interface ConnectionController (IRCHandler)
@end

@interface ConnectionController (WindowDelegate)
@end

@interface ConnectionController (TabViewItemDelegate)
@end

@interface ConnectionController (CommandHandler)
- (void)commandReceived: (NSString *)command;
- (void)commandPart: (NSString *)command;
- (void)commandQuit: (NSString *)command;
@end

@implementation ConnectionController
+ (void)initialize
{
	command_to_selector = NSCreateMapTable(NSObjectMapKeyCallBacks,
	  NSIntMapValueCallBacks, 3);
	
	NSMapInsert(command_to_selector, @"quit", @selector(commandQuit:));
	NSMapInsert(command_to_selector, @"part", @selector(commandPart:));
	NSMapInsert(command_to_selector, @"me", @selector(commandMe:));
	
	version_number =  RETAIN([[[NSBundle mainBundle] infoDictionary] 
	  objectForKey: @"ApplicationRelease"]);
}	
- init
{
	id temp;
	
	if (!(self = [super initWithNickname: @"Charla"
	  withUserName: nil withRealName: nil withPassword: nil])) return nil;
	
	window = [ChannelWindow new];
	[window setDelegate: self];
	[[window tabView] setDelegate: self];
	[window setTitle: @"Unconnected"];
	
	temp = [window typeView];
	[temp setAction: @selector(commandReceived:)];
	[temp setTarget: self];

	nameToTab = [NSMutableDictionary new];
	nameToChannel = [NSMutableDictionary new];
	
	[self addTabWithName: @"console tab" withLabel: @"Unconnected"];
	
	consoleTab = RETAIN([nameToTab objectForKey: @"console tab"]);
	consoleView = RETAIN([consoleTab view]);
	
	[window makeKeyAndOrderFront: nil];
	return self;
}
- (void)dealloc
{
	DESTROY(consoleTab);
	DESTROY(consoleView);
	DESTROY(currentTab);
	DESTROY(currentView);
	
	[window setDelegate: nil];
	[[window tabView] setDelegate: nil];
	
	DESTROY(window);
	DESTROY(connecting);
	DESTROY(nameToTab);
	DESTROY(nameToChannel);

	[super dealloc];
}
- addTabWithName: (NSString *)aName withLabel: (NSString *)aLabel
{
	id tab = AUTORELEASE([NSTabViewItem new]);
	id view = AUTORELEASE([ChannelView new]);
	id tabView;

	aName = [aName lowercaseString];

	[view setName: aName];

	[tab setLabel: aLabel];
	[tab setView: view];

	tabView = [window tabView];
	[tabView addTabViewItem: tab];
	[tabView setNeedsDisplay: YES];

	[nameToTab setObject: tab forKey: aName];
	[nameToChannel setObject: view forKey: aName];

	return self;
}
- connectionEstablished: aTransport
{
	id object = [aTransport address];
	[consoleTab setLabel: object];
	[[window tabView] setNeedsDisplay: YES];
	[window setTitle: object];

	return [super connectionEstablished: aTransport];
}	
- connectingStarted: (TCPConnecting *)aConnection
{
	connecting = RETAIN(aConnection);
	
	return self;
}
- connectingFailed: (NSString *)aReason
{
	DESTROY(connecting);

	return self;
}
- putMessage: (NSString *)message inChannel: channel
{
	id view;
	id chat;
	
	if (![message hasSuffix: @"\n"])
	{
		message = [message stringByAppendingString: @"\n"];
	}
	
	if ([channel isKindOf: [ChannelView class]])
	{
		view = channel;
	}
	else if ([channel isKindOf: [NSString class]])
	{
		view = [nameToChannel objectForKey: [channel lowercaseString]];
	}
	else if (channel == nil)
	{
		view = currentView;
	}
	else
	{
		return self;
	}

	chat = [view chatView];
	[chat appendText: message];
	[chat scrollPoint: NSMakePoint(0, NSMaxY([chat frame]))];	
	
	return self;
}
- (ChannelWindow *)window
{
	return window;
}
@end

@implementation ConnectionController (WindowDelegate)
- (void)windowWillClose: (NSNotification *)aNotification
{
	[window setDelegate: nil];
	[[window tabView] setDelegate: nil];

	[[NetApplication sharedInstance] disconnectObject: self];
	[[Charla sharedInstance] removeConnection: self];
}
@end

@implementation ConnectionController (WindowTabViewDelegate)
- (void)tabView:(NSTabView *)tabView 
     didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	RELEASE(currentTab);
	RELEASE(currentView);
	currentTab = RETAIN(tabViewItem);
	currentView = RETAIN([tabViewItem view]);
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
		NSRange range;
		id arguments;
		SEL commandSelector;

		range = [command rangeOfString: @" "];
		if (range.location == NSNotFound && range.length == 0)
		{
			substring = command;
			arguments = nil;
		}
		else
		{
			range.length = range.location - 1;
			range.location = 1;

			substring = [command substringWithRange: range];
			arguments = [[command substringFromIndex: range.length + 1] 
			  stringByTrimmingCharactersInSet: 
			    [NSCharacterSet whitespaceCharacterSet]];

			if ([arguments length] == 0)
			{
				arguments = nil;
			}
		}

		substring = [substring lowercaseString];
		commandSelector = NSMapGet(command_to_selector, substring);

		if (commandSelector != 0)
		{
			[self performSelector: commandSelector withObject: arguments];
		}
		else
		{
			NSLog(@"%@ %@");
			[self writeString: @"%@ %@", substring, arguments]; 
		}
		return;
	}

	if (currentView == consoleView)
	{
		[self putMessage: @"Join a channel first.\n" inChannel: consoleView];
		return;
	}

	[self putMessage: [NSString stringWithFormat: @"%@> %@\n", nick, command]
	  inChannel: nil];
	
	[self sendMessage: command to: [currentView name]];
}
- (void)commandPart: (NSString *)argument
{
	NSRange aRange;
	NSString *channel;
	NSString *message;

	argument = [argument stringByTrimmingCharactersInSet:
	  [NSCharacterSet whitespaceCharacterSet]];
	  
	if ([argument length] == 0)
	{
		[self putMessage: @"Usage: /part <channel> <message>" inChannel: nil];
		return;
	}
	
	aRange = [argument rangeOfString: @" "];

	if (aRange.location == NSNotFound && aRange.length == 0)
	{
		[self partChannel: argument withMessage: nil];
		return;
	}

	message = [[argument substringFromIndex: aRange.location] 
	  stringByTrimmingCharactersInSet: 
	   [NSCharacterSet whitespaceCharacterSet]];
	
	channel = [argument substringToIndex: aRange.location];

	[self partChannel: channel withMessage: message];
}
- (void)commandQuit: (NSString *)arguments
{
	[self quitWithMessage: arguments];
}
- (void)commandMe: (NSString *)argument
{
	if (currentView == consoleView)
	{
		[self putMessage: @"Join a channel first.\n" inChannel: consoleView];
		return;
	}

	[self putMessage: [NSString stringWithFormat: @"* %@ %@\n", nick, argument]
	  inChannel: nil];
	
	[self sendAction: argument to: [currentView name]];
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
	
	if ((view = [nameToChannel objectForKey: [to lowercaseString]]))
	{
		[self putMessage: 
		  [NSString stringWithFormat: @"%@> %@\n", ExtractIRCNick(sender),
		   aMessage] inChannel: view];
		return self;
	}
	
	if (ExtractIRCHost(sender))
	{	
		[self putMessage:
		  [NSString stringWithFormat: @"*** %@> %@\n", ExtractIRCNick(sender),
		   aMessage] inChannel: currentView];
	}
	else
	{
		[self putMessage:
		  [NSString stringWithFormat: @"%@\n", aMessage] inChannel: 
		    consoleView];
	}

	return self;
}
- noticeReceived: (NSString *)aMessage to: (NSString *)to
    from: (NSString *)sender
{
	id view;
	BOOL toMe;
	
	if ((view = [nameToChannel objectForKey: [to lowercaseString]]))
	{
		[self putMessage:
		  [NSString stringWithFormat: @"%@> %@\n", ExtractIRCNick(sender),
		   aMessage] inChannel: view];
		return self;
	}

	toMe = [to caseInsensitiveCompare: nick] == NSOrderedSame;
	
	if (ExtractIRCHost(sender) && toMe)
	{
		[self putMessage:
		  [NSString stringWithFormat: @"*** %@> %@\n", ExtractIRCNick(sender),
		   aMessage] inChannel: currentView];
	}
	else
	{
		if (toMe)
		{
			[self putMessage:
			  [NSString stringWithFormat: @"%@\n", aMessage] inChannel:
			    consoleView];
		}
		else
		{
			[self putMessage:
			  [NSString stringWithFormat: @"%@ :%@\n", to, aMessage] inChannel:
			    consoleView];
		}
	}

	return self;
}
- actionReceived: (NSString *)anAction to: (NSString *)to
    from: (NSString *)sender
{
	id view;

	if ((view = [nameToChannel objectForKey: [to lowercaseString]]))
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
		  anAction] inChannel: currentView];
	}

	return self;
}
- channelParted: (NSString *)channel withMessage: (NSString *)aMessage
   from: (NSString *)parter
{
	[self putMessage:
	  [NSString stringWithFormat: @"%@ (%@) has left %@ (%@)\n", 
	   ExtractIRCNick(parter), ExtractIRCHost(parter), channel, aMessage]
	  inChannel: channel];
	
	return self;
}
- channelJoined: (NSString *)channel from: (NSString *)joiner
{
	if ([ExtractIRCNick(joiner) caseInsensitiveCompare: nick] == NSOrderedSame)
	{
		[self addTabWithName: channel withLabel: channel];
		[[window tabView] selectTabViewItem: [nameToTab objectForKey: 
		  [channel lowercaseString]]];
	}
	
	[self putMessage:
	  [NSString stringWithFormat: @"%@ (%@) has joined %@\n",
	   ExtractIRCNick(joiner), ExtractIRCHost(joiner), channel]
	  inChannel: channel];
	
	return self;
}
- nickChangedTo: (NSString *)newName from: (NSString *)aPerson
{
	aPerson = ExtractIRCNick(aPerson);
	
	if ([newName caseInsensitiveCompare: nick] == NSOrderedSame)
	{
		[window updateNick: newName];
	}

	[self putMessage: [NSString stringWithFormat: @"%@ is now known as %@", 
	   aPerson, newName]
	  inChannel: consoleView];
	
	return self;
} 
- pingRequestReceived: (NSString *)argument from: (NSString *)aPerson
{
	[self sendPingReplyTo: ExtractIRCNick(aPerson) withArgument: argument];
	return self;
}
- versionRequestReceived: (NSString *)query from: (NSString *)aPerson
{
	[self sendVersionReplyTo: ExtractIRCNick(aPerson) name: @"Charla.app"
	  version: version_number environment: @"GNUstep CVS"];
	return self;
}
- numericCommandReceived: (NSString *)command withParams: (NSArray *)paramList
     from: (NSString *)sender
{
	[self putMessage: [paramList componentsJoinedByString: @" "] inChannel: consoleView];
	return self;
}
@end

