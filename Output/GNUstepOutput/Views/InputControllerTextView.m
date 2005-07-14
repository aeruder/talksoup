/***************************************************************************
                      InputControllerTextView.m
                          -------------------
    begin                : Wed Jul 13 01:02:02 CDT 2005
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

#import "Views/InputControllerTextView.h"

#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator.h>
#import <AppKit/NSText.h>
#import <AppKit/NSEvent.h>

static NSCharacterSet *newline_set = nil;
static NSEvent *newline_event = nil;

@implementation InputControllerTextView
+ (void)initialize
{
	unichar enters[] = {
		NSEnterCharacter,
		NSNewlineCharacter,
		NSCarriageReturnCharacter
	};

	newline_set = RETAIN([NSCharacterSet characterSetWithCharactersInString: 
	  [NSString stringWithCharacters: enters length: 3]]);
	newline_event = RETAIN([NSEvent keyEventWithType: NSKeyDown
	  location: NSMakePoint(0, 0)
	  modifierFlags: 0
	  timestamp: 1
	  windowNumber: 1
	  context: nil
	  characters: [NSString stringWithCharacters: enters length: 1]
	  charactersIgnoringModifiers: [NSString stringWithCharacters: enters length: 1]
	  isARepeat: NO
	  keyCode: 0xBEEF]);
}
- (void)insertText: (NSString *)someText
{
	NSMutableArray *components = [NSMutableArray new];
	NSRange aRange;
	unsigned length;
	NSEnumerator *iter;
	NSString *arg;

	length = [someText length];

	aRange.length = length;
	aRange.location = 0;

	while (aRange.length > 0)
	{
		NSRange thisRange;
		thisRange = [someText rangeOfCharacterFromSet: newline_set
		  options: 0 range: aRange];
		if (thisRange.location == NSNotFound) break;
		[components addObject: [someText substringWithRange: 
		  NSMakeRange(aRange.location, thisRange.location - aRange.location)]];
		aRange.location = thisRange.location + thisRange.length;
		aRange.length = length - aRange.location;
	}

	iter = [components objectEnumerator];
	while ((arg = [iter nextObject])) 
	{
		BOOL (*function)(id, SEL, NSEvent *, id);
		if ([arg length])
			[super insertText: arg];

		if (!keyTarget || !keyAction)
		{
			continue;
		}
		
		function = (BOOL (*)(id, SEL, NSEvent *, id))
		   [keyTarget methodForSelector: keyAction];
		
		if (function)
		{
			function(keyTarget, keyAction, newline_event, self);
		}
	}

	if (aRange.length)
		[super insertText: [someText substringWithRange: aRange]];
}
@end
