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
			  @"IRCColorCustom 130 140 410", @"TabReferenceColor",
			  @"IRCColorCustom 410 130 140", @"TabAnythingColor",
			  nil] forKey: @"Highlighting"];
		}
	}
	
	return [object objectForKey: x];
}
		
static BOOL has_name(NSString *str, NSString *name)
{
	NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:
	 @".:,- '\""];
	NSRange cur = {0};
	NSRange a = {0};
	unichar x;
	int len;
	BOOL is = NO;
	
	a.length = len = [str length];
	str = [str lowercaseString];
	name = [name lowercaseString];
	
	while (a.location < len)
	{
		cur = [str rangeOfString: name options: 0 range: a];
		
		if (cur.location == NSNotFound) return NO;
		
		is = YES;
		
		if (cur.location > 0)
		{
			x = [str characterAtIndex: cur.location - 1];
			is = [set characterIsMember: x];
		}
		if (cur.location + cur.length < len)
		{
			x = [str characterAtIndex: cur.location + cur.length];
			is &= [set characterIsMember: x];
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

NSString *get_destination(NSString *to, NSString *from, NSString *nick)
{
	id name = to;
	if ([[name lowercaseString] isEqualToString: [nick lowercaseString]])
	{
		name = from;
	}
	return name;
}

NSAttributedString *do_highlighting(id cont, NSString *msg, 
  NSAttributedString *from, NSArray *words, NSString *where, id connection)
{
	NSString *userColor = get_pref(@"HighlightingUserColor");
	NSString *refColor = get_pref(@"HighlightingTabReferenceColor");
	NSString *anyColor = get_pref(@"HighlightingTabAnythingColor");
	NSEnumerator *iter;
	id object;
	BOOL does = NO;
	
	iter = [words objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		if (has_name(msg, object))
		{
			does = YES;
			break;
		}
	}
	
	if (does)
	{
		if (refColor)
		{
			[_TS_ controlObject: [NSDictionary dictionaryWithObjectsAndKeys:
			  @"HighlightTab", @"Process",
			  refColor, @"TabColor",
			  where, @"TabName",
			  [NSNull null], @"TabPriority",
			  nil] onConnection: connection sender: cont];
		}
		
		if (userColor)
		{
			object = AUTORELEASE([[NSMutableAttributedString alloc]
			  initWithAttributedString: from]);
			[object addAttribute: IRCColor value: userColor range: 
			  NSMakeRange(0, [object length])];
			return object;
		}
	}
	else
	{
		if (anyColor)
		{
			[_TS_ controlObject: [NSDictionary dictionaryWithObjectsAndKeys:
			  @"HighlightTab", @"Process",
			  anyColor, @"TabColor",
			  where, @"TabName",
			  nil] onConnection: connection sender: cont];
		}
	}
		
	return from;
}

@implementation Highlighting
- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin
{
	id from = [IRCUserComponents(sender) objectAtIndex: 0];
	id where = get_destination([to string], [from string], [connection nick]);
	id words = get_pref(@"HighlightingExtraWords");
	NSMutableArray *x = [NSMutableArray arrayWithObject: [connection nick]];

	if (![[[from string] lowercaseString] isEqualToString: 
	  [[connection nick] lowercaseString]])
	{
		if ([words isKindOf: [NSArray class]])
		{
			[x addObjectsFromArray: words];
		}
		sender = do_highlighting(self, [aMessage string], sender, x, 
		  where, connection);
 
 	}
	
	[_TS_ messageReceived: aMessage to: to from: sender 
	  onConnection: connection sender: self];	
	return self;
}
- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin
{
	id from = [IRCUserComponents(sender) objectAtIndex: 0];
	id where = get_destination([to string], [from string], [connection nick]);
	id words = get_pref(@"HighlightingExtraWords");
	NSMutableArray *x = [NSMutableArray arrayWithObject: [connection nick]];

	if (![[[from string] lowercaseString] isEqualToString: 
	  [[connection nick] lowercaseString]])
	{
		if ([words isKindOf: [NSArray class]])
		{
			[x addObjectsFromArray: words];
		}
		sender = do_highlighting(self, [aMessage string], sender, x, 
		  where, connection);
 
 	}
	
	[_TS_ noticeReceived: aMessage to: to from: sender 
	  onConnection: connection sender: self];
	return self;
}
- actionReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin
{
	id from = [IRCUserComponents(sender) objectAtIndex: 0];
	id where = get_destination([to string], [from string], [connection nick]);
	id words = get_pref(@"HighlightingExtraWords");
	NSMutableArray *x = [NSMutableArray arrayWithObject: [connection nick]];

	if (![[[from string] lowercaseString] isEqualToString: 
	  [[connection nick] lowercaseString]])
	{
		if ([words isKindOf: [NSArray class]])
		{
			[x addObjectsFromArray: words];
		}
		sender = do_highlighting(self, [aMessage string], sender, x, 
		  where, connection); 
 	}
	
	[_TS_ actionReceived: aMessage to: to from: sender 
	  onConnection: connection sender: self];
	return self;
}
@end

