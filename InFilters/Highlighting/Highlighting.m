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
#include <Foundation/NSInvocation.h>

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
		
static void set_pref(NSString *x, id val)
{
	id object = [NSUserDefaults standardUserDefaults];
	
	if ([x hasPrefix: @"Highlighting"] && ![x isEqualToString: @"Highlighting"])
	{
		NSMutableDictionary *y;
		id tmp;
		
		x = [x substringFromIndex: 12];
		tmp = [object objectForKey: @"Highlighting"];
		
		if (!tmp)
		{
			y = AUTORELEASE([NSMutableDictionary new]);
		}
		else
		{
			y = [NSMutableDictionary dictionaryWithDictionary: tmp];
		}
		
		if (val)
		{
			[y setObject: val forKey: x];
		}
		else
		{
			[y removeObjectForKey: x];
		}
		
		[object setObject: y forKey: @"Highlighting"];
	}
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
  NSAttributedString *from, NSArray *words, NSString *where, id connection,
  NSAttributedString *aNick)
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
			  nil] onConnection: connection 
			  withNickname: aNick sender: cont];
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
			  nil] onConnection: connection 
			  withNickname: aNick sender: cont];
		}
	}
		
	return from;
}

static NSInvocation *invoc = nil;

#define COLOR_MSG @"The color is any color listed by typing /colors."
							  
@implementation Highlighting
+ (void)initialize
{
	invoc = RETAIN([NSInvocation invocationWithMethodSignature: 
	  [self methodSignatureForSelector: @selector(commandHighlighting:connection:)]]);
	[invoc retainArguments];
	[invoc setTarget: self];
	[invoc setSelector: @selector(commandHighlighting:connection:)];
}	
+ (NSAttributedString *)commandHighlighting: (NSString *)args 
   connection: connection
{
	id x = [args separateIntoNumberOfArguments: 2];
	id key = nil, val;
	int cnt = [x count];
	
	if (cnt > 0)
	{
		key = [x objectAtIndex: 0];
	}
	else
	{
		key = @"";
	}
	
	if ([key caseInsensitiveCompare: @"usercolor"] == NSOrderedSame)
	{
		if (cnt == 1)
		{
			return BuildAttributedString(
			  @"Usage: /highlighting usercolor <color>", @"\n",
			  @"This sets the color a person will change if that person says your nickname. ",
			  COLOR_MSG, nil);
		}
		
		val = IRCColorFromUserColor([x objectAtIndex: 1]);
		
		if (!val)
		{
			return S2AS(COLOR_MSG);
		}
		
		set_pref(@"HighlightingUserColor", val);
	}
	else if ([key caseInsensitiveCompare: @"tabreferencecolor"] == NSOrderedSame)
	{
		if (cnt == 1)
		{
			return BuildAttributedString(
			  @"Usage: /highlighting tabreferencecolor <color>", @"\n",
			  @"This sets the color that the tab will turn when a person says "
			  @"your nickname. ",
			  COLOR_MSG, nil);
		}
		
		val = IRCColorFromUserColor([x objectAtIndex: 1]);
		
		if (!val)
		{
			return S2AS(COLOR_MSG);
		}
		
		set_pref(@"HighlightingTabReferenceColor", val);
	}
	else if ([key caseInsensitiveCompare: @"tabanythingcolor"] == NSOrderedSame)
	{
		if (cnt == 1)
		{
			return BuildAttributedString(
			  @"Usage: /highlighting tabanythingcolor <color>", @"\n",
			  @"This sets the color that the tab will change when a person says anything. ",
			  COLOR_MSG, nil);
		}
		
		val = IRCColorFromUserColor([x objectAtIndex: 1]);
		
		if (!val)
		{
			return S2AS(COLOR_MSG);
		}
		
		set_pref(@"HighlightingTabAnythingColor", val);
	}
	else if ([key caseInsensitiveCompare: @"extrawords"] == NSOrderedSame)
	{
		val = [get_pref(@"HighlightingExtraWords") componentsJoinedByString: 
		  @"^"];
		if (!val) val = @"";
		
		if (cnt == 1)
		{
			return BuildAttributedString(
			  @"Usage: /highlighting extrawords <words>", @"\n",
			  @"This sets other words that activate the highlighting besides your "
			  @"nickname. The argument should be a list of words separated by "
			  @"'^'.  If you simply specify '^', it will clear the list.", @"\n",
			  @"The list is currently: ", val, nil);
		}
		
		val = [[x objectAtIndex: 1] componentsSeparatedByString: @"^"];
		
		if ([[x objectAtIndex: 1] caseInsensitiveCompare: @"^"] == NSOrderedSame)
		{
			val = nil;
		}
		
		set_pref(@"HighlightingExtraWords", val);
	}
	else
	{
		return BuildAttributedString([NSNull null], IRCBold, @"bold", 
		  @"Highlighting Configurator:", @"\n",
		  @"Type /highlighting usercolor", @"\n",
		  @"or /highlighting tabreferencecolor", @"\n",
		  @"or /highlighting tabanythingcolor", @"\n",
		  @"or /highlighting extrawords" @"\n",
		  @"for more information.", 
		  nil);
	}

	return nil;
}
- pluginActivated
{
	[_TS_ addCommand: @"highlighting" withInvocation: invoc];
	return self;
}
- pluginDeactivated
{
	[_TS_ removeCommand: @"highlighting"];
	return self;
}
- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick
   sender: aPlugin
{
	id from = [IRCUserComponents(sender) objectAtIndex: 0];
	id where = get_destination([to string], [from string], [connection nick]);
	id words = get_pref(@"HighlightingExtraWords");
	NSMutableArray *x = [NSMutableArray arrayWithObject: [connection nick]];

	if ([words isKindOf: [NSArray class]])
	{
		[x addObjectsFromArray: words];
	}
	
	sender = do_highlighting(self, [aMessage string], sender, x, 
	  where, connection, aNick);
 
	[_TS_ messageReceived: aMessage to: to from: sender 
	  onConnection: connection withNickname: aNick sender: self];	
	return self;
}
- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick
   sender: aPlugin
{
	id from = [IRCUserComponents(sender) objectAtIndex: 0];
	id where = get_destination([to string], [from string], [connection nick]);
	id words = get_pref(@"HighlightingExtraWords");
	NSMutableArray *x = [NSMutableArray arrayWithObject: [connection nick]];

	if ([words isKindOf: [NSArray class]])
	{
		[x addObjectsFromArray: words];
	}
	sender = do_highlighting(self, [aMessage string], sender, x, 
	  where, connection, aNick);
	
	[_TS_ noticeReceived: aMessage to: to from: sender 
	  onConnection: connection withNickname: aNick sender: self];
	return self;
}
- actionReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick
   sender: aPlugin
{
	id from = [IRCUserComponents(sender) objectAtIndex: 0];
	id where = get_destination([to string], [from string], [connection nick]);
	id words = get_pref(@"HighlightingExtraWords");
	NSMutableArray *x = [NSMutableArray arrayWithObject: [connection nick]];

	if ([words isKindOf: [NSArray class]])
	{
		[x addObjectsFromArray: words];
	}
	sender = do_highlighting(self, [aMessage string], sender, x, 
	  where, connection, aNick); 
	
	[_TS_ actionReceived: aMessage to: to from: sender 
	  onConnection: connection withNickname: aNick sender: self];
	return self;
}
@end

