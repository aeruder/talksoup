/***************************************************************************
                                ConnectionControllerTabCompletion.m
                          -------------------
    begin                : Tue May 20 18:38:20 CDT 2003
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

#include "Controllers/ConnectionController.h"
#include "TalkSoupBundles/TalkSoup.h"
#include "Controllers/InputController.h"
#include "Controllers/ContentController.h"
#include "GNUstepOutput.h"
#include "Views/KeyTextView.h"
#include "Misc/NSObjectAdditions.h"
#include "Models/Channel.h"

#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSString.h>
#include <Foundation/NSSet.h>
#include <AppKit/NSText.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSGraphics.h>

@interface ConnectionController (TabCompletionPrivate)
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

@implementation ConnectionController (TabCompletion)
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
		[inputController previousHistoryItem: sender];
		return NO;
	}
	if (character == NSDownArrowFunctionKey)
	{
		[inputController nextHistoryItem: sender];
		return NO;
	}
	
	return YES;
}	
@end

@implementation ConnectionController (TabCompletionPrivate)
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
	id field = [content typeView];
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
}
- (void)firstTabPressed: (id)sender
{
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
	
	if (start == [typed length]) return;
	
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
	
	iter = [[content allViews] objectEnumerator];
	while ((object = [iter nextObject]))
	{
		[x addObject: [content viewNameForController: object]];
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
	
	iter = [[[nameToChannelData objectForKey: 
	  GNUstepOutputLowercase([content currentViewName])]
	  userList] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[x addObject: [object userName]];
	}
	
	return [self completionsInArray: x startingWith: pre
	  largestValue: large];
}
@end
