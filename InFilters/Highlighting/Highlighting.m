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

#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSAttributedString.h>
#include <Foundation/NSString.h>

static BOOL has_name(NSString *str, NSString *name)
{
	NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:
	 @".:, "];
	NSRange cur = {0};
	NSRange a = {0};
	unichar x;
	int len;
	BOOL is = NO;
	
	a.length = len = [str length];
	str = [str lowercaseString];
	name = [name lowercaseString];
	
	while (a.length >= 0)
	{
		cur = [str rangeOfString: name options: 0 range: a];
		
		if (cur.location == NSNotFound) return NO;
		
		is = YES;
		
		if (cur.location + a.location > 0)
		{
			x = [str characterAtIndex: cur.location + a.location - 1];
			is = [set characterIsMember: x];
		}
		if (cur.location + a.location + cur.length < len)
		{
			x = [str characterAtIndex: cur.location + a.location + cur.length];
			is |= [set characterIsMember: x];
		}
		
		if (is)
		{
			NSLog(@"It matches!!!");
			return YES;
		}
		
		a.location += cur.location + cur.length;
		a.length = len - a.location;
	}
	
	return NO;
}

@implementation Highlighting
- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin
{
	if (has_name([aMessage string], [connection nick]))
	{
		NSMutableAttributedString *x =
		 AUTORELEASE([[NSMutableAttributedString alloc] initWithAttributedString:
		  sender]);
		[x addAttribute: IRCColor value: IRCColorBlue range: 
		  NSMakeRange(0, [sender length])];
		sender = x;
	}
 
	[_TS_ messageReceived: aMessage to: to from: sender 
	  onConnection: connection sender: self];
	return self;
}
- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin
{
	if (has_name([aMessage string], [connection nick]))
	{
		NSMutableAttributedString *x = 
		 AUTORELEASE([[NSMutableAttributedString alloc] initWithAttributedString:
		  sender]);
		[x addAttribute: IRCColor value: IRCColorBlue range: 
		  NSMakeRange(0, [sender length])];
		sender = x;		
	}
	else
	
	[_TS_ noticeReceived: aMessage to: to from: sender 
	  onConnection: connection sender: self];
	return self;
}
- actionReceived: (NSAttributedString *)anAction to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin
{
	if (has_name([anAction string], [connection nick]))
	{
		NSMutableAttributedString *x =
		 AUTORELEASE([[NSMutableAttributedString alloc] initWithAttributedString:
		  sender]);
		[x addAttribute: IRCColor value: IRCColorBlue range: 
		  NSMakeRange(0, [sender length])];
		sender = x;		
	}
	
	[_TS_ actionReceived: anAction to: to from: sender 
	  onConnection: connection sender: self];
	return self;
}
@end

