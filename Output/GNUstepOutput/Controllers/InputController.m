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
#include "GNUstepOutput.h"

#include <Foundation/NSBundle.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSWindow.h>

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
		_output_ = RETAIN([_TS_ output]);
	}
	
	if (![_output_ isKindOf: [GNUstepOutput class]])
	{
		RELEASE(self);
		return nil;
	}

	return self;
}
- (void)dealloc
{
	RELEASE(controller);
	[super dealloc];
}
- (void)enterPressed: (id)sender
{
	id command;
	NSArray *lines;
	NSEnumerator *iter;
	id object;
	
	command = AUTORELEASE(RETAIN([sender stringValue]));

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
		
		if (commandSelector != 0)
		{
			if ([self respondsToSelector: commandSelector])
			{
				[self performSelector: commandSelector withObject: arguments];
			}
			else if ((invoc = [_TS_ invocationForCommand: substring]))
			{
				NSLog(@"Trying the invocation...");
				[invoc setArgument: &substring atIndex: 2];
				[invoc invoke];
			}
			else
			{
				commandSelector = 0;
			}
		}
		if (commandSelector == 0 && connection)
		{
			NSLog(@"Couldn't find nothin', gonna try raw string...");
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

	NSLog(@"Getting ready to send...");
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
- commandJoin: (NSString *)aString
{
	NSArray *x = [aString separateIntoNumberOfArguments: 3];
	id pass;
	
	if ([x count] == 0)
	{
		[controller showMessage: 
		  S2AS(_l(@"Usage: /join <channel1[,channel2...]> [password1[,password2...]]"))
		  onConnection: nil];
		return self;
	}
	
	pass = ([x count] == 2) ? [x objectAtIndex: 1] : nil;
	
	[_TS_ joinChannel: S2AS([x objectAtIndex: 0]) withPassword: S2AS(pass) 
	  onConnection: [_output_ connectionToConnectionController: controller]
	  sender: _output_];
	  
	return self;
}
- commandNick: (NSString *)aString
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	NSString *before;
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
		  [[controller connection] nick]];
		return self;
	}
	
	before = AUTORELEASE(RETAIN([connection nick]));
	[_TS_ changeNick: S2AS([x objectAtIndex: 0]) onConnection: connection
	  sender: [_TS_ output]];
	if (![connection connected])
	{
		if (![before isEqualToString: [connection nick]])
		{
			[[controller contentController] setNickViewString:
			  [connection nick]];
		}
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
- commandMsg: (NSString *)aString
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	
	if ([x count] < 2)
	{
		[controller showMessage:
		  S2AS(_l(@"Usage: /msg <person> <message>"))
		  onConnection: nil];
		return self;
	}
	
	[_TS_ sendMessage: S2AS([x objectAtIndex: 1]) to: 
	  S2AS([x objectAtIndex: 0])
	  onConnection: [controller connection] sender: _output_];

	return self;
}
- commandQuery: (NSString *)aString
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	id o;
	
	if ([x count] < 1)
	{
		[controller showMessage:
		  S2AS(_l(@"Usage: /query name"))
		 onConnection: nil];
		return self;
	}
	
	o = [x objectAtIndex: 0];
	
	[[controller contentController] addQueryWithName: o withLabel: o];
	
	return self;
}
@end