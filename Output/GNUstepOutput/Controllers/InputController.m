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

#include "TalkSoupBundles/TalkSoup.h"
#include "Controllers/InputController.h"
#include "Controllers/ConnectionController.h"
#include "Controllers/ContentController.h"
#include "Controllers/QueryController.h"
#include "Views/ScrollingTextView.h"
#include "GNUstepOutput.h"

#include <Foundation/NSBundle.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSTextStorage.h>

id _output_ = nil; 

@interface InputController (PrivateInputController)
- (void)singleLineTyped: (NSString *)aLine;
@end


@implementation InputController
- initWithConnectionController: (ConnectionController *)aController
{
	if (!(self = [super init])) return nil;

	controller = RETAIN(aController);
	
	if (!(_output_))
	{
		_output_ = RETAIN([_TS_ pluginForOutput]);
	}
	
	if (![_output_ isKindOf: [GNUstepOutput class]])
	{
		RELEASE(self);
		return nil;
	}

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
	
	if (modIndex < [modHistory count])
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
	
	if (historyIndex == [history count])
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
	NSEnumerator *iter;
	id object;

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
				[self singleLineTyped: object2];
			}
		}
	}
	else
	{
		lines = [command componentsSeparatedByString: @"\n"];
		iter = [lines objectEnumerator];
		while ((object = [iter nextObject]))
		{
			[self singleLineTyped: object];
		}
	}	
}
- (void)enterPressed: (id)sender
{
	id string = AUTORELEASE(RETAIN([sender stringValue]));
	
	if ([string length] == 0) return;
	
	[self lineTyped: string];
	
	[modHistory removeAllObjects];
	[modHistory addObject: @""];
	
	[history addObject: string];	
	historyIndex = [history count];
	
	[sender setStringValue: @""];
	[[[controller contentController] window] makeFirstResponder: sender];
}
@end

@implementation InputController (PrivateInputController)
- (void)singleLineTyped: (NSString *)command
{
	id connection;
	id name;
	
	connection = AUTORELEASE(RETAIN(
	  [_output_ connectionToConnectionController: controller]));
	
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
			  onConnection: connection sender: _output_]; 
		}
		return;
	}

	if (!connection) return;
	
	name = [[controller contentController] currentViewName];
	if (name == ContentConsoleName)
	{
		return;
	}

	[_TS_ sendMessage: S2AS(command) to: S2AS(name)
	  onConnection: connection sender: _output_];
}
@end

@interface InputController (CommonCommands)
@end

@implementation InputController (CommonCommands)
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
	  sender: _output_];
	
	if (![connection connected])
	{
		[[controller contentController] setNickViewString:
		  [connection nick]];
	}
	
	return self;
}
- commandMe: (NSString *)aString
{
	if ([aString length] == 0)
	{
		[controller showMessage: 
		  S2AS(_l(@"Usage: /me <action>"))
		  onConnection: nil];
		return self;
	}
	
	[_TS_ sendAction: S2AS(aString) to: S2AS([[controller contentController]
	  currentViewName]) onConnection: [controller connection]
	  sender: _output_];
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
	
	[[controller contentController] addQueryWithName: o withLabel: o];
	
	return self;
}
- commandClose: (NSString *)aString
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	id o;
	
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
		  onConnection: [controller connection] sender: _output_];
	}
	
	[[controller contentController] closeViewWithName: o];

	return self;
}
- commandPart: (NSString *)args
{
	id x = [args separateIntoNumberOfArguments: 2];
	id name, msg;
	id content = [controller contentController];
	
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
	  onConnection: [controller connection] sender: _output_];
	
	return self;
}
- commandClear: (NSString *)command
{
	id x = [[controller contentController] controllerForViewWithName: 
	  [[controller contentController] currentViewName]];
	[[[x chatView] textStorage] setAttributedString: 
	  AUTORELEASE([[NSAttributedString alloc] initWithString: @""])];
	
	return self;
}	  
@end
