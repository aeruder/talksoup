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
#include "Controllers/ContentController.h"
#include "GNUstepOutput.h"

#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSWindow.h>

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

@interface InputController (PrivateInputController)
- (void)singleLineTyped: (NSString *)aLine;
@end

@implementation InputController
- initWithContentController: (ContentController *)aContent
{
	if (!(self = [super init])) return nil;

	content = aContent;
	output = [_TS_ output];
	
	if (![output isKindOf: [GNUstepOutput class]])
	{
		RELEASE(self);
		return nil;
	}

	return self;
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
	[[content window] makeFirstResponder: sender];
}
@end

@implementation InputController (PrivateInputController)
- (void)singleLineTyped: (NSString *)command
{
	id connection;
	
	connection = AUTORELEASE(RETAIN([output connectionToContent: content]));
	
	NSLog(@"Here we are!!!!!!! %@ %@", command, connection);
	
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
		substring = [array objectAtIndex: 0];

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
			else
			{
				commandSelector = 0;
			}
		}
		if (commandSelector == 0 && connection)
		{
			[_TS_ writeRawString: [NSString stringWithFormat: @"%@ %@", 
			    substring, arguments]
			  onConnection: [output connectionToContent: content] sender: output]; 
		}
		return;
	}

	if (!connection) return;
	
	if ([content currentViewName] == ContentConsoleName)
	{
		return;
	}

	[_TS_ sendMessage: S2AS(command) to: S2AS([content currentViewName])
	  onConnection: connection sender: output];
	[_TS_ messageReceived: S2AS(command) to: S2AS([content currentViewName])
	  from: S2AS([connection nick]) onConnection: connection 
	  sender: [_TS_ input]];
}
@end

