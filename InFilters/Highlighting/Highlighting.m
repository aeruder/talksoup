/***************************************************************************
                                Highlighting.m
                          -------------------
    begin                : Fri May  2 16:48:50 CDT 2003
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

#include "Highlighting.h"
#include "TalkSoupBundles/TalkSoup.h"

#include <Foundation/NSAttributedString.h>
#include <Foundation/NSString.h>

static inline NSAttributedString 
  *highlight_word(NSAttributedString *str, NSString *word, NSString *color)
{
	id string = [[str string] lowercaseString];
	int wordlen = [word length];
	int stringlen = [string length];
	NSMutableAttributedString *work =
	  AUTORELEASE([[NSMutableAttributedString alloc] initWithString: @""]);
	id x;
	NSRange currentRange = {0};

	word = [word lowercaseString];
	if ([word length] == 0) return nil;
	
	x = [string componentsSeparatedByString: [NSString stringWithFormat:
	 @" %@ ", word]];
	
	if ([x count] == 1)
	{
		return str;
	}
	else if ([x count] > 1)
	{
		int current;
		int count = [x count];

		for (current = 0; current < count; current++)
		{
			currentRange.length = [[x objectAtIndex: 0] length];
			if (currentRange.length > 0)
			{
				[work appendAttributedString: [str attributedSubstringWithRange: 
				  currentRange]];
			}
			if (current != count - 1)
			{
				currentRange.location += currentRange.length;
				currentRange.length = wordlen + 2;
				[work appendAttributedString: 
				  [str attributedSubstringWithRange: currentRange]];
				[work addAttribute: @"IRCColor" value: color 
				  range: 
				  NSMakeRange(currentRange.location + 1, currentRange.length - 1)];
			}
			currentRange.location += currentRange.length;
		}
	}
			
	if ([string hasPrefix: [NSString stringWithFormat: @"%@ ", word]])
	{
		[work addAttribute: @"IRCColor" value: color
		  range: NSMakeRange(0, wordlen)];
	}

	if ([string hasSuffix: [NSString stringWithFormat: @" %@", word]])
	{
		[work addAttribute: @"IRCColor" value: color
		  range: NSMakeRange(stringlen - wordlen, wordlen)];
	}

	return work;
}

@implementation Highlighting
- sendMessage: (NSAttributedString *)message to: (NSAttributedString *)receiver
   onConnection: aConnection sender: aPlugin
{
	[_TS_ sendMessage: highlight_word(message, [aConnection nick], IRCColorYellow)
	  to: receiver onConnection: aConnection sender: self];
	return self;
}
- sendNotice: (NSAttributedString *)message to: (NSAttributedString *)receiver
   onConnection: aConnection sender: aPlugin
{
	[_TS_ sendNotice: highlight_word(message, [aConnection nick], IRCColorYellow)
	  to: receiver onConnection: aConnection sender: self];
	return self;
}
- sendAction: (NSAttributedString *)anAction to: (NSAttributedString *)receiver
   onConnection: aConnection sender: aPlugin;
{
	[_TS_ sendMessage: highlight_word(anAction, [aConnection nick], IRCColorYellow)
	  to: receiver onConnection: aConnection sender: self];
	return self;
}
@end

