/***************************************************************************
                                InputController.m
                          -------------------
    begin                : Thu Mar 13 13:18:48 CST 2003
    copyright            : (C) 2005 by Andrew Ruder
    email                : aeruder@ksu.edu
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

#import "Controllers/ConnectionController.h"
#import "Controllers/ContentControllers/ContentController.h"
#import "Controllers/ContentControllers/StandardQueryController.h"
#import "Controllers/InputController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "Controllers/Preferences/GeneralPreferencesController.h"
#import "GNUstepOutput.h"
#import "Misc/HelperExecutor.h"
#import "Misc/NSObjectAdditions.h"
#import "Models/Channel.h"
#import "Views/ScrollingTextView.h"

#import <AppKit/NSTextField.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSTask.h>
#import <Foundation/NSRange.h>
#import <AppKit/NSText.h>
#import <AppKit/NSEvent.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSObject.h>
#import <AppKit/NSGraphics.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSDistributedNotificationCenter.h>

#include <sys/time.h>
#include <time.h>
#include <stdlib.h>

NSString *TaskExecutionOutputNotification = @"TaskExecutionOutputNotification";
static NSString *exec_helper = @"exec_helper";

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
- (void)viewControllerRemoved: (NSNotification *)aNotification;
- (void)nextHistoryItem: (NSText *)aFieldEditor;
- (void)previousHistoryItem: (NSText *)aFieldEditor;
- (BOOL)chatKeyPressed: (NSEvent *)aEvent sender: (id)sender;
- (BOOL)fieldKeyPressed: (NSEvent *)aEvent sender: (id)sender;
- (void)taskExecutionOutput: (NSNotification *)aNotification;
@end

@interface InputController (TabCompletion)
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
- (NSArray *)historyStartingWith: (NSString *)pre 
  largestValue: (NSString **)large;
@end

@implementation InputController
- initWithViewController: (id <ContentControllerQueryController>)aController
    contentController: (id <ContentController>)aContentController
{
	NSString *aIdentifier;
	if (!(self = [super init])) return nil;

	content = RETAIN(aContentController);
	view = RETAIN(aController);
	controller = [content connectionController];
	
	history = [NSMutableArray new];
	modHistory = [NSMutableArray new];
	[modHistory addObject: @""];

	[(KeyTextView *)[view chatView] setKeyTarget: self];
	[(KeyTextView *)[view chatView] 
	  setKeyAction: @selector(chatKeyPressed:sender:)];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(viewControllerRemoved:)
	  name: ContentControllerRemovedFromMasterControllerNotification
	  object: content];

	aIdentifier = [NSString stringWithFormat: @"%p%@%ld",
	  self, self, rand()];
	helper = [[HelperExecutor alloc] initWithHelperName: exec_helper 
	  identifier: aIdentifier];

	[(NSDistributedNotificationCenter *)[NSDistributedNotificationCenter defaultCenter] 
	  addObserver: self
	  selector: @selector(taskExecutionOutput:)
	  name: TaskExecutionOutputNotification
	  object: aIdentifier 
	  suspensionBehavior: NSNotificationSuspensionBehaviorDeliverImmediately];

	return self;
}
- (void)dealloc
{
	[(NSDistributedNotificationCenter *)[NSDistributedNotificationCenter defaultCenter]
	  removeObserver: self];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[fieldEditor setKeyTarget: nil];
	[fieldEditor setDelegate: nil];
	[(KeyTextView *)[view chatView] setKeyTarget: nil];
	RELEASE(helper);
	RELEASE(fieldEditor);
	RELEASE(modHistory);
	RELEASE(history);
	RELEASE(content);
	RELEASE(view);
	[super dealloc];
}
- (void)setConnectionController: (ConnectionController *)aController
{
	controller = aController;
}
- (void)loseTextField: (KeyTextView *)aField
   forMasterController: (id <MasterController>)aMaster
{
	int modIndex;

	if (fieldEditor != aField)
		NSLog(@"fieldEditor != aField!!!");

	modIndex = [history count] - historyIndex;

	[modHistory replaceObjectAtIndex: modIndex withObject: 
	  [NSString stringWithString: [fieldEditor string]]];
	savedRange = [fieldEditor selectedRange];

	[fieldEditor setKeyTarget: nil];

	DESTROY(fieldEditor);
}
- (void)handleTextField: (KeyTextView *)aField
   forMasterController: (id <MasterController>)aMaster;
{
	int modIndex;
	id string;
	unsigned length;

	modIndex = [history count] - historyIndex;

	lastMaster = aMaster;

	string = [modHistory objectAtIndex: modIndex];

	ASSIGN(fieldEditor, aField);
	[fieldEditor setStringValue: string];

	[fieldEditor setKeyTarget: self];
	[fieldEditor setKeyAction: @selector(fieldKeyPressed:sender:)];

	length = [string length];
	if ((savedRange.length + savedRange.location) > length)
	{
		savedRange.length = 0;
		savedRange.location = length;
	}

	[fieldEditor setSelectedRange: savedRange];
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
				[history addObject: object2];	
				historyIndex = [history count];
				[modHistory removeAllObjects];
				[modHistory addObject: @""];
				[self processSingleCommand: object2];
			}
		}
	}

	[fieldEditor setStringValue: @""];
}
- (void)processSingleCommand: (NSString *)aCommand
{
	id connection;
	id name;
	
	connection = AUTORELEASE(RETAIN(
	  [_GS_ connectionToConnectionController: controller]));
	
	if ([aCommand length] == 0)
	{
		return;
	}

	/* First check for aliases */
	if ([aCommand hasPrefix: @"/"] && ![aCommand hasPrefix: @"//"])
	{
		id tempCommand;
		id array;

		tempCommand = [aCommand substringFromIndex: 1];
		array = [tempCommand separateIntoNumberOfArguments: 2];
		
		if ([array count] >= 1)
		{
			id alias;
			id aliases;

			alias = [array objectAtIndex: 0];
			alias = [alias lowercaseString];

			aliases = [_PREFS_ preferenceForKey: GNUstepOutputAliases];

			if ((tempCommand = [aliases objectForKey: alias]))
			{
				if ([array count] > 1)
				{
					aCommand = [NSString stringWithFormat: @"%@ %@", tempCommand, 
					  [array objectAtIndex: 1]];
				}
				else
				{
					aCommand = tempCommand;
				}
			}
		}
	}

	/* Now the real deal */
	if ([aCommand hasPrefix: @"/"] && ![aCommand hasPrefix: @"//"])
	{
		id substring;
		id arguments;
		SEL commandSelector;
		id array;
		id invoc;

		aCommand = [aCommand substringFromIndex: 1];
		
		array = [aCommand separateIntoNumberOfArguments: 2];
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
		
		substring = GNUstepOutputLowercase(substring, controller);
		
		commandSelector = NSSelectorFromString([NSString stringWithFormat: 
		  @"ircCommand%@:", [substring capitalizedString]]);
		
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
	} else if ([aCommand hasPrefix: @"/"]) {
		aCommand = [aCommand substringFromIndex: 1];
	}

	if (!connection) return;
	
	name = [content nameForViewController: view];
	if (GNUstepOutputCompare(name, ContentConsoleName, controller))
	{
		return;
	}

	send_message(aCommand, name, connection); 	
}
@end

@implementation InputController (PrivateInputController)
- (void)viewControllerRemoved: (NSNotification *)aNotification
{
	[helper cleanup];
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

		[fieldEditor setStringValue: [modHistory objectAtIndex: modIndex]];
	}
	else
	{
		string = [history objectAtIndex: historyIndex];
		[modHistory addObject: string];
		[fieldEditor setStringValue: string];
	}
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
	
	[fieldEditor setStringValue: [modHistory objectAtIndex: modIndex]];
}
- (BOOL)chatKeyPressed: (NSEvent *)aEvent sender: (id)sender
{
	id typeview;
	typeview = [lastMaster typeView];
	if ([[lastMaster window] makeFirstResponder: typeview])
	{
		[fieldEditor keyDown: aEvent]; 
	}
	return NO;
}
- (BOOL)fieldKeyPressed: (NSEvent *)aEvent sender: (id)sender
{
	NSString *characters = [aEvent charactersIgnoringModifiers];
	unichar character = 0;
	
	if ([characters length] == 0)
	{
		return YES;
	}

	character = [characters characterAtIndex: 0];

	if (character == NSCarriageReturnCharacter || 
	    character == NSEnterCharacter)
	{
		[self commandTyped: [sender string]];
		return NO;
	}

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
		[(ScrollingTextView *)[view chatView] pageUp];
		return NO;
	}
	if (character == NSPageDownFunctionKey)
	{
		[(ScrollingTextView *)[view chatView] pageDown];
		return NO;
	}
	
	return YES;
}	
- (void)taskExecutionOutput: (NSNotification *)aNotification
{
	id userInfo = [aNotification userInfo];
	id message = [userInfo objectForKey: @"Output"];
	id dest = [userInfo objectForKey: @"Destination"];
	
	if ([controller connection] && [dest length])
	{
		send_message(AUTORELEASE([message copy]), 
		 AUTORELEASE([dest copy]), [controller connection]);
	} 
	else
	{
		[controller showMessage: S2AS(AUTORELEASE([message copy])) 
		  onConnection: nil];
	}
}
@end

@implementation InputController (TabCompletion)
- (void)nonTabPressed: (id)sender
{
	if (tabCompletion)
	{
		DESTROY(tabCompletion);
	}
}
- (void)tabPressed: (id)sender
{
	NSRange aRange;

	aRange = [fieldEditor selectedRange];
	if (aRange.length != 0 || 
	    aRange.location != [[fieldEditor string] length])
		return;
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
	NSString *typed = [NSString stringWithString: [fieldEditor string]];
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
}
- (void)firstTabPressed: (id)sender
{
	NSString *typed = [NSString stringWithString: [fieldEditor string]];
	NSArray *possibleCompletions;
	int start;
	NSRange range;
	NSString *largest;
	NSString *word;
	NSString *filler = @" ";
	
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
	else if ([word hasPrefix: @"s/"])
	{
		possibleCompletions = [self historyStartingWith: word
		  largestValue: &largest];
		filler = @"/";
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
		[fieldEditor setStringValue: [NSString stringWithFormat: @"%@%@%@",
		  [typed substringToIndex: start], largest, filler]];
	}
	else if ([possibleCompletions count] > 1)
	{
		[fieldEditor setStringValue: [NSString stringWithFormat: @"%@%@",
		  [typed substringToIndex: start], largest]];
		NSBeep();
		tabCompletionIndex = -1;
		tabCompletion = RETAIN(possibleCompletions);
	}
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
	
	pre = GNUstepOutputLowercase(pre, controller);
	
	iter = [x objectEnumerator];
	while ((object = [iter nextObject]))
	{
		lowObject = GNUstepOutputLowercase(object, controller);
		if ([lowObject hasPrefix: pre])
		{
			[out addObject: object];
			if (lar)
			{
				lar = [GNUstepOutputLowercase(lar, controller) commonPrefixWithString: 
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
		if ([x hasPrefix: @"ircCommand"] && [x hasSuffix: @":"] &&
		  ![x isEqualToString: @"ircCommand:"])
		{
			x = [x substringFromIndex: 10];
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
	
	iter = [[content allNames] objectEnumerator];
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
	NSMutableArray *x = AUTORELEASE([NSMutableArray new]);
	NSEnumerator *iter;
	id object;
	id <ContentControllerChannelController> channel;

	if ([view conformsToProtocol: @protocol(ContentControllerChannelController)])
	{
		channel = (id <ContentControllerChannelController>)view;
	}
	else
	{
		return AUTORELEASE([NSArray new]);
	}

	iter = [[[channel channelSource]
	  userList] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[x addObject: [object userName]];
	}
	
	return [self completionsInArray: x startingWith: pre
	  largestValue: large];
}
- (NSArray *)historyStartingWith: (NSString *)pre 
  largestValue: (NSString **)large
{
	NSMutableArray *x = AUTORELEASE([NSMutableArray new]);
	NSMutableArray *y = AUTORELEASE([NSMutableArray new]);
	NSString *historyString;
	unsigned count;
	unsigned len;
	NSRange leftRange, wordRange, foundRange;
	NSEnumerator *iter;
	id object;

	count = [history count];

	if (count > 0)
	{
		historyString = [history objectAtIndex: [history count] - 1];
		len = [historyString length];
		leftRange = NSMakeRange(0, len);

		while (leftRange.length > 0) 
		{ 
			foundRange = [historyString rangeOfCharacterFromSet:
			  [NSCharacterSet whitespaceAndNewlineCharacterSet]
			  options: 0 range: leftRange];
			if (foundRange.location == NSNotFound) 
			{ 
				[x addObject: [historyString substringWithRange: leftRange]];
				break;
			} 
			else 
			{
				wordRange.location = leftRange.location;
				wordRange.length = foundRange.location - leftRange.location;
				if (wordRange.length > 0)
					[x addObject: [historyString substringWithRange: wordRange]];
				leftRange.location = foundRange.location + foundRange.length;
				leftRange.length = len - leftRange.location;
			}
		}
	}

	iter = [x objectEnumerator];
	while ((object = [iter nextObject]))
	{
		object = [NSString stringWithFormat: @"s/%@", object];
		[y addObject: object];
	}

	return [self completionsInArray: y startingWith: pre
	  largestValue: large];
}
@end

@interface InputController (CommonCommands)
@end

@implementation InputController (CommonCommands)
- ircCommandPing: (NSString *)aString
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
- ircCommandSay: (NSString *)aString
{
	NSString *name;

	if ([aString length] == 0)
	{
		[controller showMessage:
		  S2AS(_l(@"Usage: /say <text>" @"\n"
		  @"Sends text to the current channel."))
		  onConnection: nil];
		return self;
	}

	name = [content nameForViewController: view];
	if (GNUstepOutputCompare(name, ContentConsoleName, controller))
		return self;

	if (![controller connection])
		return self;
		
	send_message(aString, name, [controller connection]);
	return self;
}
- ircCommandTopic: (NSString *)aString
{
	NSArray *x;
	id connection;
	id topic;
	id name;

	x = [aString separateIntoNumberOfArguments: 1];
	topic = ([x count]) ? (S2AS([x objectAtIndex: 0])) : nil;

	name = [content nameForViewController: view];
	if (![[content typeForName: name] isEqualToString: 
	       ContentControllerChannelType])
		return self;

	connection = [controller connection];
	
	[_TS_ setTopicForChannel: S2AS(name) to: topic
	  onConnection: connection 
	  withNickname: S2AS([connection nick]) sender: _GS_];

	return self;
}
- ircCommandJoin: (NSString *)aString
{
	NSMutableArray *x;
	NSInvocation *invoc;
	id connection;
	x = [NSMutableArray arrayWithArray:
	  [aString separateIntoNumberOfArguments: 3]];
	
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
- ircCommandServer: (NSString *)aString
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
- ircCommandNick: (NSString *)aString
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
		[content setNickname: [controller nick]];
		return self;
	}
	
	[_TS_ changeNick: S2AS([x objectAtIndex: 0]) onConnection: connection
	  withNickname: S2AS([connection nick]) sender: _GS_];
	
	if (![connection connected])
	{
		[content setNickname: [connection nick]];
	}
	
	return self;
}
- ircCommandMe: (NSString *)aString
{
	id connection = [controller connection];

	if ([aString length] == 0)
	{
		[controller showMessage: 
		  S2AS(_l(@"Usage: /me <action>"))
		  onConnection: nil];
		return self;
	}
	
	[_TS_ sendAction: S2AS(aString) 
	  to: S2AS([content nameForViewController: view])
	  onConnection: connection
	  withNickname: S2AS([connection nick])
	  sender: _GS_];

	return self;
}
- ircCommandQuery: (NSString *)aString
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	id name;
	id cont;
	
	if ([x count] < 1)
	{
		[controller showMessage:
		  S2AS(_l(@"Usage: /query <name>"))
		 onConnection: nil];
		return self;
	}
	
	name = [x objectAtIndex: 0];
	
	cont = [content addViewControllerOfType: ContentControllerQueryType
	  withName: name withLabel: S2AS(name) 
	  inMasterController: lastMaster]; 

	[[NSRunLoop currentRunLoop] performSelector: @selector(selectViewController:)
	  target: lastMaster
	  argument: cont
	  order: 0
	  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
	
	return self;
}
- ircCommandClose: (NSString *)aString
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	id name;
	id connection = [controller connection];
	
	name = [content nameForViewController: view];
	if ([x count] < 1)
	{
		if (GNUstepOutputCompare(name, ContentConsoleName, controller))
		{			
			[controller showMessage:
			  S2AS(_l(@"Usage: /close <tab label>")) 
			  onConnection: nil];
			return self;
		}
	}
	else
	{
		name = [x objectAtIndex: 0];
	}
	
	/* Closing a tab could very well kill us...
	 */
	AUTORELEASE(RETAIN(self));

	if ([controller dataForChannelWithName: name])
	{
		[controller leaveChannel: name];
		[_TS_ partChannel: S2AS(name) withMessage: S2AS(@"")
		  onConnection: connection 
		  withNickname: S2AS([connection nick])
		  sender: _GS_];
	}
	
	[content removeViewControllerWithName: name];

	return self;
}
- ircCommandQuit: (NSString *)args
{
	id x = [args separateIntoNumberOfArguments: 1];
	id connection = [controller connection];
	id msg;

	msg = ([x count]) ? [x objectAtIndex: 0] : 
	  [_PREFS_ preferenceForKey: GNUstepOutputDefaultQuitMessage];

	[_TS_ quitWithMessage: S2AS(msg) onConnection: connection
	  withNickname: S2AS([connection nick]) sender: _GS_];

	return self;
}
- ircCommandPart: (NSString *)args
{
	id x = [args separateIntoNumberOfArguments: 2];
	id name, msg;
	id connection = [controller connection];
	
	msg = nil;

	name = [content nameForViewController: view];
	if (![[content typeForName: name] isEqualToString: 
	       ContentControllerChannelType])
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
- ircCommandClear: (NSString *)command
{
	[[view chatView] setString: @""]; 
	
	return self;
}	
- ircCommandScrollback: (NSString *)command
{
	id x = [command separateIntoNumberOfArguments: 2];
	int length;
	
	if ([x count] == 0)
	{
		[controller showMessage:
		  BuildAttributedString(_l(@"Usage: /scrollback <lines>"),
		    @"\n", _l(@"Current value is: "), 
			 [_PREFS_ preferenceForKey: GNUstepOutputBufferLines], nil) 
		  onConnection: nil];
		return self;
	}
	
	length = [[x objectAtIndex: 0] intValue];
	if (length < 0) length = 10;
	
	[_PREFS_ setPreference: [NSString stringWithFormat: @"%d", length]
	  forKey: GNUstepOutputBufferLines];
	
	return self;
}
- ircCommandAlias: (NSString *)command
{
	id x = [command separateIntoNumberOfArguments: 2];
	id aliases = [_PREFS_ preferenceForKey: GNUstepOutputAliases];
	id alias, to;

	if ([x count] == 0)
	{
		id object;
		NSEnumerator *iter;

		[controller showMessage:
		  S2AS(_l(@"Usage: /alias <alias> <command>"))
		  onConnection: nil];
		[controller showMessage:
		  S2AS(_l(@"Current aliases:"))
		  onConnection: nil];

		iter = [aliases keyEnumerator];
		while ((object = [iter nextObject]))
		{
			[controller showMessage:
			  BuildAttributedFormat(@"  /%@ = '%@'",
			  object, [aliases objectForKey: object])
			  onConnection: nil];
		}
		[controller showMessage:
		  S2AS(_l(@"End of alias list."))
		  onConnection: nil];

		return self;
	}

	alias = [x objectAtIndex: 0];
	if ([alias hasPrefix: @"/"]) alias = [alias substringFromIndex: 1];
	alias = [alias lowercaseString];

	if ([x count] == 1)
	{
		id to = [aliases objectForKey: alias];
		if (!to)
		{
			[controller showMessage:
			  BuildAttributedFormat(_l(@"/%@ is not currently aliased."),
			  alias)
			  onConnection: nil];
		}
		else
		{
			[controller showMessage:
			  BuildAttributedFormat(_l(@"/%@ is currently aliased to '%@'"),
			  alias, to)
			  onConnection: nil];
		}
		return self;
	}

	to = [x objectAtIndex: 1];

	[aliases setObject: to forKey: alias];
	[_PREFS_ setPreference: aliases forKey: GNUstepOutputAliases];

	[controller showMessage:
	  BuildAttributedFormat(_l(@"/%@ aliased to '%@'"),
	  alias, to)
	  onConnection: nil];
		  
	return self;
}
- ircCommandUnalias: (NSString *)command
{
	id x = [command separateIntoNumberOfArguments: 2];
	id aliases = [_PREFS_ preferenceForKey: GNUstepOutputAliases];
	id alias, to;

	if ([x count] == 0)
	{
		id object;
		NSEnumerator *iter;

		[controller showMessage:
		  S2AS(_l(@"Usage: /unalias <alias>"))
		  onConnection: nil];
		[controller showMessage:
		  S2AS(_l(@"Current aliases:"))
		  onConnection: nil];

		iter = [aliases keyEnumerator];
		while ((object = [iter nextObject]))
		{
			[controller showMessage:
			  BuildAttributedFormat(@"  /%@ = '%@'",
			  object, [aliases objectForKey: object])
			  onConnection: nil];
		}
		[controller showMessage:
		  S2AS(_l(@"End of alias list."))
		  onConnection: nil];

		return self;
	}

	alias = [x objectAtIndex: 0];
	if ([alias hasPrefix: @"/"]) alias = [alias substringFromIndex: 1];
	alias = [alias lowercaseString];

	to = [aliases objectForKey: alias];
	if (!to)
	{
		[controller showMessage:
		  BuildAttributedFormat(_l(@"/%@ is not currently aliased."),
		  alias)
		  onConnection: nil];
	}
	else
	{
		[aliases removeObjectForKey: alias];
		[_PREFS_ setPreference: aliases forKey: GNUstepOutputAliases];
		[controller showMessage:
		  BuildAttributedFormat(_l(@"/%@ unaliased."),
		  alias)
		  onConnection: nil];
	}
	return self;
}
- ircCommandExec: (NSString *)command
{
	id x = [command separateIntoNumberOfArguments: 1];
	id newcommand = nil;
	id destination = nil;

	if ([x count] > 0 && [[x objectAtIndex: 0] hasPrefix: @"-o "])
	{
		x = [command separateIntoNumberOfArguments: 2];
		if ([x count] == 2)
		{
			newcommand = [x objectAtIndex: 1];
			destination = [content nameForViewController: view];
			if (GNUstepOutputCompare(destination, ContentConsoleName, controller))
				destination = nil;
		}
	} 
	else if ([x count] > 0)
	{
		newcommand = [x objectAtIndex: 0];	
	}

	if (!newcommand)
	{
		[controller showMessage:
		  S2AS(_l(@"Usage: /exec [-o] <command>"))
		 onConnection: nil];
		return self;
	}

	if (!helper)
	{
		[controller showMessage:
		  S2AS(_l(@"Something went wrong initializing the helper application. Can't execute."))
		  onConnection: nil];
		return self;
	}
	
	[helper runWithArguments: [NSArray arrayWithObjects: TaskExecutionOutputNotification, 
	  newcommand, destination, nil]];

	return self;
}
@end
