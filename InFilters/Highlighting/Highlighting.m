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
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSNull.h>

static id get_pref(NSString *x)
{
	id object = [NSUserDefaults standardUserDefaults];
	
	if ([x hasPrefix: @"Highlighting"] && ![x isEqualToString: @"Highlighting"])
	{
		x = [x substringFromIndex: 12];
		object = [object objectForKey: @"Highlighting"];
		if (!(object))
		{
			[[NSUserDefaults standardUserDefaults] setObject:
			  object = [NSDictionary dictionaryWithObjectsAndKeys: 
			  IRCColorBlue, @"UserColor",
			  @"IRCColorCustom 0.13 0.14 0.41", @"TabReferenceColor",
			  @"IRCColorCustom 0.41 0.13 0.14", @"TabAnythingColor",
			  nil] forKey: @"Highlighting"];
		}
	}
	
	return [object objectForKey: x];
}
		
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
	id color1 = get_pref(@"HighlightingUserColor");
	id myColor = get_pref(@"HighlightingTabReferenceColor");
	id anyColor = get_pref(@"HighlightingTabAnythingColor");
	
	id name = [to string];
	if ([[name lowercaseString] isEqualToString: 
	  [[connection nick] lowercaseString]])
	{
		name = [[IRCUserComponents(to) objectAtIndex: 0] string];
	}
	
	if (has_name([aMessage string], [connection nick]) && color1)
	{
		NSMutableAttributedString *x =
		 AUTORELEASE([[NSMutableAttributedString alloc] initWithAttributedString:
		  sender]);
		[x addAttribute: IRCColor value: color1 range: 
		  NSMakeRange(0, [sender length])];
		sender = x;
	
		if (myColor)
		{
			[_TS_ controlObject: [NSDictionary dictionaryWithObjectsAndKeys: 
			  myColor, @"TabColor",
			  name, @"TabName",
			  [NSNull null], @"TabPriority",
			  nil] onConnection: connection sender: aPlugin];
		}
	}
	else if (anyColor)
	{
		[_TS_ controlObject: [NSDictionary dictionaryWithObjectsAndKeys: 
		  anyColor, @"TabColor",
		  name, @"TabName",
		  nil] onConnection: connection sender: aPlugin];
	}		
 
	[_TS_ messageReceived: aMessage to: to from: sender 
	  onConnection: connection sender: self];
	return self;
}
- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin
{
	id color1 = get_pref(@"HighlightingUserColor");
	id myColor = get_pref(@"HighlightingTabReferenceColor");
	id anyColor = get_pref(@"HighlightingTabAnythingColor");
	
	id name = [to string];
	if ([[name lowercaseString] isEqualToString: 
	  [[connection nick] lowercaseString]])
	{
		name = [[IRCUserComponents(to) objectAtIndex: 0] string];
	}
	
	if (has_name([aMessage string], [connection nick]) && color1)
	{
		NSMutableAttributedString *x =
		 AUTORELEASE([[NSMutableAttributedString alloc] initWithAttributedString:
		  sender]);
		[x addAttribute: IRCColor value: color1 range: 
		  NSMakeRange(0, [sender length])];
		sender = x;
	
		if (myColor)
		{
			[_TS_ controlObject: [NSDictionary dictionaryWithObjectsAndKeys: 
			  myColor, @"TabColor",
			  name, @"TabName",
			  [NSNull null], @"TabPriority",
			  nil] onConnection: connection sender: aPlugin];
		}
	}
	else if (anyColor)
	{
		[_TS_ controlObject: [NSDictionary dictionaryWithObjectsAndKeys: 
		  anyColor, @"TabColor",
		  name, @"TabName",
		  nil] onConnection: connection sender: aPlugin];
	}		
	
	[_TS_ noticeReceived: aMessage to: to from: sender 
	  onConnection: connection sender: self];
	return self;
}
- actionReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin
{
	id color1 = get_pref(@"HighlightingUserColor");
	id myColor = get_pref(@"HighlightingTabReferenceColor");
	id anyColor = get_pref(@"HighlightingTabAnythingColor");
	
	id name = [to string];
	if ([[name lowercaseString] isEqualToString: 
	  [[connection nick] lowercaseString]])
	{
		name = [[IRCUserComponents(to) objectAtIndex: 0] string];
	}
	
	if (has_name([aMessage string], [connection nick]) && color1)
	{
		NSMutableAttributedString *x =
		 AUTORELEASE([[NSMutableAttributedString alloc] initWithAttributedString:
		  sender]);
		[x addAttribute: IRCColor value: color1 range: 
		  NSMakeRange(0, [sender length])];
		sender = x;
	
		if (myColor)
		{
			[_TS_ controlObject: [NSDictionary dictionaryWithObjectsAndKeys: 
			  myColor, @"TabColor",
			  name, @"TabName",
			  [NSNull null], @"TabPriority",
			  nil] onConnection: connection sender: aPlugin];
		}
	}
	else if (anyColor)
	{
		[_TS_ controlObject: [NSDictionary dictionaryWithObjectsAndKeys: 
		  anyColor, @"TabColor",
		  name, @"TabName",
		  nil] onConnection: connection sender: aPlugin];
	}		
	
	[_TS_ actionReceived: aMessage to: to from: sender 
	  onConnection: connection sender: self];
	return self;
}
@end

