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
#import "Controllers/ContentControllers/ContentController.h"
#import "Controllers/ContentControllers/StandardQueryController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "Views/ScrollingTextView.h"
#import "Misc/NSObjectAdditions.h"
#import "GNUstepOutput.h"

#import <Foundation/NSBundle.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSSet.h>
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

- (void)nextHistoryItem: (NSText *)aFieldEditor;

- (void)previousHistoryItem: (NSText *)aFieldEditor;
@end

@interface InputController (TabCompletion)
- (BOOL)keyPressed: (NSEvent *)aEvent sender: (id)sender;

- (void)nonTabPressed: (id)sender;

- (void)tabPressed: (id)sender;

- (void)extraTabPressed: (id)sender;

- (void)firstTabPressed: (id)sender;

- (NSArray *)completionsInArray: (NSArray *)x
  startingWith: (NSString *)pre
  largestValue: (NSString **)large;

- (NSArray *)commandStartingWith: (NSString *)pre 
  largestValue: (NSString **)large;

- (NSArray *)channelStartingWith: (NSString *)pre 
  largestValue: (NSString **)large;

- (NSArray *)nameStartingWith: (NSString *)pre 
  largestValue: (NSString **)large;
@end

@implementation InputController
- initWithView: (id <ContentControllerQueryView>)aViewController
    contentController: (id <ContentController>)aContentController
{
	if (!(self = [super init])) return nil;

	content = RETAIN(aContentController);
	view = RETAIN(aViewController);
	controller = [content connectionController];
	
	NSLog(@"Initializing with %@ %@", content, self);
	history = [NSMutableArray new];
	modHistory = [NSMutableArray new];
	[modHistory addObject: @""];

	fieldEditor = [KeyTextView new];
	[fieldEditor setFieldEditor: YES];
	[fieldEditor setKeyTarget: self];
	[fieldEditor setKeyAction: @selector(keyPressed:sender:)];

	return self;
}
- (void)dealloc
{
	[fieldEditor setKeyTarget: nil];
	RELEASE(fieldEditor);
	RELEASE(modHistory);
	RELEASE(history);
	RELEASE(content);
	RELEASE(view);
	[super dealloc];
}
- (NSText *)fieldEditorForField: (NSTextField *)aField
{
	activeTextField = aField;
	NSLog(@"Returning that dern field editor");
	return fieldEditor;
}
- (void)commandTyped: (NSString *)command
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
		/*
		[[[controller contentController] window] makeFirstResponder: sender];
		FIXME */
		return;
	}
	
	[modHistory removeAllObjects];
	[modHistory addObject: @""];
	
	[self commandTyped: string];
	
	[sender setStringValue: @""];
	/* FIXME
	[[[controller contentController] window] makeFirstResponder: sender];
	*/
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
	
	/* FIXME
	name = [[controller contentController] currentViewName];
	if (name == ContentConsoleName)
	{
		return;
	}
	*/

	send_message(command, name, connection); 	
}
- (void)previousHistoryItem: (NSText *)aFieldEditor
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
	
	// FIXME
	//[[[controller contentController] window] makeFirstResponder:
	//  [[controller contentController] typeView]];
}
- (void)nextHistoryItem: (NSText *)aFieldEditor
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

	/* FIXME
	[[[controller contentController] window] makeFirstResponder:
	  [[controller contentController] typeView]];
	*/
}
@end

@implementation InputController (TabCompletion)
- (BOOL)keyPressed: (NSEvent *)aEvent sender: (id)sender
{
	NSString *characters = [aEvent characters];
	unichar character = 0;
	
	if ([characters length] == 0)
	{
		return YES;
	}

   character = [characters characterAtIndex: 0];

	if (character == NSTabCharacter)
	{
		[self tabPressed: sender];
		return NO;
	}
	else
	{
		[self nonTabPressed: sender];
	}
	
	if (character == NSUpArrowFunctionKey)
	{
		[self previousHistoryItem: sender];
		return NO;
	}
	if (character == NSDownArrowFunctionKey)
	{
		[self nextHistoryItem: sender];
		return NO;
	}
	if (character == NSPageUpFunctionKey)
	{
// FIXME		id x = [content controllerForViewWithName: [content currentViewName]];
	//	[[x chatView] pageUp];
		return NO;
	}
	if (character == NSPageDownFunctionKey)
	{
	//	id x = [content controllerForViewWithName: [content currentViewName]];
	//	[[x chatView] pageDown];
		return NO;
	}
	
	return YES;
}	
- (void)nonTabPressed: (id)sender
{
	if (tabCompletion)
	{
		DESTROY(tabCompletion);
	}
}
- (void)tabPressed: (id)sender
{
	if (tabCompletion)
	{
		[self extraTabPressed: sender];
	}
	else
	{
		[self firstTabPressed: sender];
	}
}
- (void)extraTabPressed: (id)sender
{
	// FIXME
/*	id field = [content typeView];
	NSString *typed = [field stringValue];
	int start;
	NSRange range;

	if (tabCompletionIndex == -1)
	{
		tabCompletionIndex = 0;
		[content putMessage: [tabCompletion componentsJoinedByString: @"     "] in: nil];
	}
	
	range = [typed rangeOfCharacterFromSet:
	  [NSCharacterSet whitespaceAndNewlineCharacterSet]
	  options: NSBackwardsSearch];
	
	if (range.location == NSNotFound) range.location = 0;
	
	start = range.location + range.length;

	[fieldEditor setStringValue: [NSString stringWithFormat: @"%@%@",
	  [typed substringToIndex: start], 
	  [tabCompletion objectAtIndex: tabCompletionIndex]]];
	tabCompletionIndex = (tabCompletionIndex + 1) % [tabCompletion count];
*/
}
- (void)firstTabPressed: (id)sender
{
	/* FIXME
	id field = [content typeView];
	NSString *typed = [field stringValue];
	NSArray *possibleCompletions;
	int start;
	NSRange range;
	NSString *largest;
	NSString *word;
	
	range = [typed rangeOfCharacterFromSet:
	  [NSCharacterSet whitespaceAndNewlineCharacterSet]
	  options: NSBackwardsSearch];
	
	if (range.location == NSNotFound) range.location = 0;
	
	start = range.location + range.length;
	
	if (start == (int)[typed length]) return;
	
	word = [typed substringFromIndex: start];
	
	if (start == 0 && [word hasPrefix: @"/"])
	{
		possibleCompletions = [self commandStartingWith: word 
		  largestValue: &largest];
	}
	else if ([word hasPrefix: @"#"])
	{
		possibleCompletions = [self channelStartingWith: word
		  largestValue: &largest];
	}
	else 
	{
		possibleCompletions = [self nameStartingWith: word
		  largestValue: &largest];
		if (start == 0 && [possibleCompletions count] == 1)
		{
			largest = [largest stringByAppendingString: @":"];
		}
	}
	
	if ([possibleCompletions count] == 0)
	{
		NSBeep();
	}
	else if ([possibleCompletions count] == 1)
	{
		[fieldEditor setStringValue: [NSString stringWithFormat: @"%@%@ ",
		  [typed substringToIndex: start], largest]];
	}
	else if ([possibleCompletions count] > 1)
	{
		[fieldEditor setStringValue: [NSString stringWithFormat: @"%@%@",
		  [typed substringToIndex: start], largest]];
		NSBeep();
		tabCompletionIndex = -1;
		tabCompletion = RETAIN(possibleCompletions);
	}
	*/
}
- (NSArray *)completionsInArray: (NSArray *)x
  startingWith: (NSString *)pre
  largestValue: (NSString **)large
{
	NSEnumerator *iter;
	id object;
	NSString *lar = nil;
	id lowObject;
	NSMutableArray *out = AUTORELEASE([NSMutableArray new]);
	
	pre = GNUstepOutputLowercase(pre);
	
	iter = [x objectEnumerator];
	while ((object = [iter nextObject]))
	{
		lowObject = GNUstepOutputLowercase(object);
		if ([lowObject hasPrefix: pre])
		{
			[out addObject: object];
			if (lar)
			{
				lar = [GNUstepOutputLowercase(lar) commonPrefixWithString: 
				  lowObject options: 0];
				lar = [object substringToIndex: [lar length]];
			}
			else
			{	
				lar = object;
			}
		}
	}
	if (large) *large = lar;
	
	return out;
}
- (NSArray *)commandStartingWith: (NSString *)pre 
  largestValue: (NSString **)large
{
	NSMutableSet *aSet = [NSMutableSet new];
	id x;
	NSEnumerator *iter;
	
	iter = [[InputController methodsDefinedForClass] objectEnumerator];
	
	while ((x = [iter nextObject]))
	{
		if ([x hasPrefix: @"command"] && [x hasSuffix: @":"] &&
		  ![x isEqualToString: @"command:"])
		{
			x = [x substringFromIndex: 7];
			x = [x substringToIndex: [x length] - 1];
			x = [@"/" stringByAppendingString: [x uppercaseString]];
		
			[aSet addObject: x];
		}
	}
	
	iter = [[_TS_ allCommands] objectEnumerator];
	while ((x = [iter nextObject]))
	{
		[aSet addObject: [@"/" stringByAppendingString: [x uppercaseString]]];
	}
	
	x = AUTORELEASE(RETAIN([aSet allObjects]));
	RELEASE(aSet);
	
	return [self completionsInArray: x startingWith: pre
	  largestValue: large];
}
- (NSArray *)channelStartingWith: (NSString *)pre 
  largestValue: (NSString **)large
{
	NSMutableArray *x = AUTORELEASE([NSMutableArray new]);
	NSEnumerator *iter;
	id object;
	
	iter = [[[controller contentController] allNames] objectEnumerator];
	while ((object = [iter nextObject]))
	{
		[x addObject: object];
	}
	
	return [self completionsInArray: x startingWith: pre
	  largestValue: large];
}
- (NSArray *)nameStartingWith: (NSString *)pre 
  largestValue: (NSString **)large
{
	/*
	NSMutableArray *x = AUTORELEASE([NSMutableArray new]);
	NSEnumerator *iter;
	id object;
	
	iter = [[[nameToChannelData objectForKey: 
	  GNUstepOutputLowercase([content currentViewName])]
	  userList] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[x addObject: [object userName]];
	}
	
	return [self completionsInArray: x startingWith: pre
	  largestValue: large];
	FIXME*/
	return AUTORELEASE([NSArray new]);
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
	arg = [NSString stringWithFormat: @"%u.%u", (unsigned)tv.tv_sec, 
	  (unsigned)(tv.tv_usec / 1000)];
	
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
	
	/*
	if (![content isChannelName: name = [content currentViewName]])
	{
		name = nil;
	}
	FIXME */
	
	if (!name)
	{
		return self;
	}

	connection = [controller connection];
	
	[_TS_ setTopicForChannel: S2AS(name) to: topic
	  onConnection: connection 
	  withNickname: S2AS([connection nick]) sender: _GS_];

	if (topic)
	{
		[_TS_ setTopicForChannel: S2AS(name) to: nil
		  onConnection: connection withNickname: S2AS([connection nick])
		  sender: _GS_];
	}
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
		[[controller contentController] setNickname:
		  [controller nick]];
		return self;
	}
	
	[_TS_ changeNick: S2AS([x objectAtIndex: 0]) onConnection: connection
	  withNickname: S2AS([connection nick]) sender: _GS_];
	
	if (![connection connected])
	{
		[[controller contentController] setNickname:
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
	
	/*
	[_TS_ sendAction: S2AS(aString) to: S2AS([[controller contentController]
	  currentViewName]) onConnection: connection
	  withNickname: S2AS([connection nick])
	  sender: _GS_];
	  FIXME */
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
	
	/* FIXME
	[[controller contentController] addQueryWithName: o withLabel: S2AS(o)];
	*/
	
	return self;
}
- commandClose: (NSString *)aString
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	id o;
	id connection = [controller connection];
	
	if ([x count] < 1)
	{
		/*
		if ([(o = [[controller contentController] currentViewName])
		     isEqualToString: ContentConsoleName])
		{			
			[controller showMessage:
			  S2AS(_l(@"Usage: /close <tab label>")) 
			  onConnection: nil];
			return self;
		}
		FIXME */ 
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
	
	/* 
	[[controller contentController] closeViewWithName: o];
	FIXME */

	return self;
}
- commandPart: (NSString *)args
{
	id x = [args separateIntoNumberOfArguments: 2];
	id name, msg;
	id content = [controller contentController];
	id connection = [controller connection];
	
	msg = nil;
	/* 
	if (![content isChannelName: name = [content currentViewName]])
	{
		name = nil;
	}
	FIXME */

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
	/* FIXME
	id x = [[controller contentController] controllerForViewWithName: 
	  [[controller contentController] currentViewName]];
	[[x chatView] setString: @""]; 
	*/
	
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
			 [_PREFS_ preferenceForKey: GNUstepOutputScrollBack], nil) 
		  onConnection: nil];
		return self;
	}
	
	length = [[x objectAtIndex: 0] intValue];
	
	if (length < 512) length = 512;
	
	[_PREFS_ setPreference: [NSString stringWithFormat: @"%d", length]
	  forKey: GNUstepOutputScrollBack];
	
	return self;
}
@end
