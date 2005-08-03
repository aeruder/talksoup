/***************************************************************************   
                                Highlighting.m
                          -------------------
    begin                : Fri May  2 16:48:50 CDT 2003
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

#import "Highlighting.h"
#import <TalkSoupBundles/TalkSoup.h>

#ifdef USE_APPKIT
#import "HighlightingPreferencesController.h"
#else
@protocol NoAppKitProtocolForHighlighting
- (void)reloadData;
@end
#endif

#import <Foundation/NSDictionary.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSRange.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSRange.h>

static NSDictionary *highlighting_defaults = nil;
static id main_controller = nil;

#define get_pref(__x) [Highlighting defaultsObjectForKey: (__x)]
#define set_pref(__x,__y) \
{	[Highlighting setDefaultsObject: (__y) forKey: (__x)];\
	[main_controller reloadData]; }
	

NSString *HighlightingShouldDoNick = @"HighlightingShouldDoNick";
NSString *HighlightingUserColor = @"HighlightingUserColor";
NSString *HighlightingTabReferenceColor = @"HighlightingTabReferenceColor";
NSString *HighlightingTabAnythingColor = @"HighlightingTabAnythingColor";
NSString *HighlightingExtraWords = @"HighlightingExtraWords";
NSString *TalkSoupHighlightingNotification = @"TalkSoupHighlightingNotification";
NSString *TalkSoupPrivateMessageNotification = @"TalkSoupPrivateMessageNotification";

static BOOL has_name(NSString *str, NSString *name, id connection)
{
	NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:
	 @".:,- '\"\t!@#$%^&*()[]+=/\\{};<>"];
	NSRange cur = {0};
	NSRange a = {0};
	unichar x;
	int len;
	BOOL is = NO;
	
	a.length = len = [str length];
	str = [str performSelector: [connection lowercasingSelector]];
	name = [name performSelector: [connection lowercasingSelector]];
	
	while ((int)a.location < len)
	{
		cur = [str rangeOfString: name options: 0 range: a];
		
		if (cur.location == NSNotFound) return NO;
		
		is = YES;
		
		if (cur.location > 0)
		{
			x = [str characterAtIndex: cur.location - 1];
			is = [set characterIsMember: x];
		}
		if ((int)cur.location + (int)cur.length < len)
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

NSString *get_destination(NSString *to, NSString *from, NSString *nick, id connection)
{
	id name = to;
	if ([connection caseInsensitiveCompare: name to: nick] == NSOrderedSame)
	{
		name = from;
	}
	return name;
}

void handle_notifications(id cont, NSAttributedString *msg, NSString *type, 
  NSAttributedString *sender, NSAttributedString *to, id connection,
  BOOL highlit)
{
	NSAttributedString *from;
	NSAttributedString *typeattr;

	from = [IRCUserComponents(sender) objectAtIndex: 0];
	typeattr = AUTORELEASE([[NSAttributedString alloc] initWithString: type]);
	
	if (highlit) 
	{
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: TalkSoupHighlightingNotification
		 object: msg 
		 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
		  msg, @"Message",
		  typeattr, @"Type",
		  from, @"From",
		  sender, @"FromFull",
		  to, @"To",
		  connection, @"Connection",
		  nil
		]];
	}

	if ([connection caseInsensitiveCompare: [to string] to: [connection nick]] 
	   == NSOrderedSame)
	{
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: TalkSoupPrivateMessageNotification
		 object: msg 
		 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
		  msg, @"Message",
		  typeattr, @"Type",
		  from, @"From",
		  sender, @"FromFull",
		  to, @"To",
		  connection, @"Connection",
		  nil
		]];
	}
}

NSAttributedString *do_highlighting(id cont, NSString *msg, 
  NSAttributedString *from, NSArray *words, NSString *where, id connection,
  NSAttributedString *aNick, BOOL *highlit)
{
	NSString *userColor = get_pref(HighlightingUserColor);
	NSString *refColor = get_pref(HighlightingTabReferenceColor);
	NSString *anyColor = get_pref(HighlightingTabAnythingColor);
	NSEnumerator *iter;
	id object;
	BOOL does = NO;
	
	iter = [words objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		if (has_name(msg, object, connection))
		{
			does = YES;
			break;
		}
	}
	
	if (highlit) *highlit = does;
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

#define COLOR_MSG _l(@"The color is any color listed by typing /colors.")
							  
@implementation Highlighting
+ (void)initialize
{
	invoc = RETAIN([NSInvocation invocationWithMethodSignature: 
	  [self methodSignatureForSelector: @selector(commandHighlighting:connection:)]]);
	[invoc retainArguments];
	[invoc setTarget: self];
	[invoc setSelector: @selector(commandHighlighting:connection:)];
	highlighting_defaults = [[NSDictionary alloc] initWithContentsOfFile:
	  [[NSBundle bundleForClass: [Highlighting class]] 
	  pathForResource: @"Defaults" ofType: @"plist"]];
}	
+ (NSDictionary *)defaultSettings
{
	return highlighting_defaults;
}
+ (void)setDefaultsObject: aObject forKey: aKey
{
	id object = [NSUserDefaults standardUserDefaults];
	
	if ([aKey hasPrefix: @"Highlighting"] && ![aKey isEqualToString: @"Highlighting"])
	{
		NSMutableDictionary *y;
		id tmp;
		
		aKey = [aKey substringFromIndex: 12];
		tmp = [object objectForKey: @"Highlighting"];
		
		if (!tmp)
		{
			y = AUTORELEASE([NSMutableDictionary new]);
		}
		else
		{
			y = [NSMutableDictionary dictionaryWithDictionary: tmp];
		}
		
		if (aObject)
		{
			[y setObject: aObject forKey: aKey];
		}
		else
		{
			[y removeObjectForKey: aKey];
		}
		
		[object setObject: y forKey: @"Highlighting"];
	}
}
+ (id)defaultsObjectForKey: aKey
{
	id object = [NSUserDefaults standardUserDefaults];
	
	if ([aKey hasPrefix: @"Highlighting"] && ![aKey isEqualToString: @"Highlighting"])
	{
		aKey = [aKey substringFromIndex: 12];
		object = [object objectForKey: @"Highlighting"];
		if (!(object))
		{
			[[NSUserDefaults standardUserDefaults] setObject:
			  object = highlighting_defaults forKey: @"Highlighting"];
		}
		return (object = [object objectForKey: aKey]) ? object : 
		  [highlighting_defaults objectForKey: aKey];
	}
	
	return [object objectForKey: aKey];
}
+ (id)defaultDefaultsForKey: aKey
{
	return [highlighting_defaults objectForKey: aKey];
}
+ (NSAttributedString *)commandHighlighting: (NSString *)args 
   connection: connection
{
	id x = [args separateIntoNumberOfArguments: 2];
	id key = nil, val;
	int cnt = [x count];
	id msg = @"";
	
	if (cnt > 0)
	{
		key = [x objectAtIndex: 0];
	}
	else
	{
		key = @"";
	}
	
	if ([key caseInsensitiveCompare: @"shouldhighlightnick"] == NSOrderedSame)
	{
		val = get_pref(HighlightingShouldDoNick);
		if (!val || [val isEqualToString: @"YES"])
		{
			val = @"NO";
			msg = _l(@"Turning off nick highlighting...\n");
		}
		else
		{
			val = @"YES";
			msg = _l(@"Turning on nick highlighting...\n");
		}
		set_pref(HighlightingShouldDoNick, val);
	}
	else if ([key caseInsensitiveCompare: @"usercolor"] == NSOrderedSame)
	{
		if (cnt == 1)
		{
			return BuildAttributedString(
			  _l(@"Usage: /highlighting usercolor <color>"), @"\n",
			  _l(@"This sets the highlighting color of a person who says your nickname. "),
			  COLOR_MSG, nil);
		}
		
		val = IRCColorFromUserColor([x objectAtIndex: 1]);
		
		if (!val)
		{
			return S2AS(COLOR_MSG);
		}
		
		set_pref(HighlightingUserColor, val);
	}
	else if ([key caseInsensitiveCompare: @"tabreferencecolor"] == NSOrderedSame)
	{
		if (cnt == 1)
		{
			return BuildAttributedString(
			  _l(@"Usage: /highlighting tabreferencecolor <color>"), @"\n",
			  _l(@"This sets the highlighting color of the tab when a person says "
			  @"your nickname. "),
			  COLOR_MSG, nil);
		}
		
		val = IRCColorFromUserColor([x objectAtIndex: 1]);
		
		if (!val)
		{
			return S2AS(COLOR_MSG);
		}
		
		set_pref(HighlightingTabReferenceColor, val);
	}
	else if ([key caseInsensitiveCompare: @"tabanythingcolor"] == NSOrderedSame)
	{
		if (cnt == 1)
		{
			return BuildAttributedString(
			  _l(@"Usage: /highlighting tabanythingcolor <color>"), @"\n",
			  _l(@"This sets the highlighting color of the tab when a person says anything. "),
			  COLOR_MSG, nil);
		}
		
		val = IRCColorFromUserColor([x objectAtIndex: 1]);
		
		if (!val)
		{
			return S2AS(COLOR_MSG);
		}
		
		set_pref(HighlightingTabAnythingColor, val);
	}
	else if ([key caseInsensitiveCompare: @"extrawords"] == NSOrderedSame)
	{
		val = [get_pref(HighlightingExtraWords) componentsJoinedByString: 
		  @"^"];
		if (!val) val = @"";
		
		if (cnt == 1)
		{
			return BuildAttributedString(
			  _l(@"Usage: /highlighting extrawords <words>"), @"\n",
			  _l(@"This sets other words that activate the highlighting besides your "
			  @"nickname. The argument should be a list of words separated by "
			  @"'^'.  If you simply specify '^', it will clear the list."), @"\n",
			  _l(@"The list is currently: "), val, nil);
		}
		
		val = [[x objectAtIndex: 1] componentsSeparatedByString: @"^"];
		
		val = [NSMutableArray arrayWithArray: val];
		[val removeObject: @""];
		
		if ([val count] == 0)
		{
			val = nil;
		}
		
		set_pref(HighlightingExtraWords, val);
	}
	else
	{
		return BuildAttributedString([NSNull null], IRCBold, IRCBoldValue, 
		  _l(@"Highlighting Configurator:"), @"\n",
		  _l(@"Type /highlighting usercolor"), @"\n",
		  _l(@"or /highlighting tabreferencecolor"), @"\n",
		  _l(@"or /highlighting tabanythingcolor"), @"\n",
		  _l(@"or /highlighting extrawords"), @"\n",
		  _l(@"or /highlighting shouldhighlightnick"), @"\n",
		  _l(@"for more information."), 
		  nil);
	}

	return S2AS(([NSString stringWithFormat: @"%@%@", msg, _l(@"Ok.")]));
}
- (NSAttributedString *)pluginDescription
{
	return BuildAttributedString([NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Author: "), @"Andrew Ruder\n\n",
	 [NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Description: "), _l(@"This bundle will highlight the names of people "
	 @"who say your name in the channel.  It will also handle the "
	 @"highlighting of the tabs.  The highlighting colors as well as "
	 @"other words to highlight can be setup through the /highlighting "
	 @"command when this bundle is loaded"),
	 @"\n\n",
	 _l(@"Copyright (C) 2005 by Andrew Ruder"),
	 nil);
}
- pluginActivated
{
#ifdef USE_APPKIT
	main_controller = controller = [HighlightingPreferencesController new];
	if (controller)
	{
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: @"PreferencesModuleAdditionNotification"
		 object: controller];
	}
#endif

	[_TS_ addCommand: @"highlighting" withInvocation: invoc];
	return self;
}
- pluginDeactivated
{
#ifdef USE_APPKIT
	if (controller)
	{
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: @"PreferencesModuleRemovalNotification" 
		 object: controller];
	}
	main_controller = nil;
	DESTROY(controller);
#endif

	[_TS_ removeCommand: @"highlighting"];
	return self;
}
- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick
   sender: aPlugin
{
	id from = [IRCUserComponents(sender) objectAtIndex: 0];
	id where = get_destination([to string], [from string], [connection nick], 
	  connection);
	id words = get_pref(HighlightingExtraWords);
	id shouldAdd = get_pref(HighlightingShouldDoNick);
	NSMutableArray *x = [NSMutableArray arrayWithObjects: nil]; 
	BOOL highlit;
	
	if (!shouldAdd || [shouldAdd isEqualToString: @"YES"])
	{
		[x addObject: [connection nick]];
	}
	
	if ([words isKindOfClass: [NSArray class]])
	{
		[x addObjectsFromArray: words];
	}
	
	sender = do_highlighting(self, [aMessage string], sender, x, 
	  where, connection, aNick, &highlit);
	handle_notifications(self, aMessage, @"Message", sender, to, connection, highlit);
 
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
	id where = get_destination([to string], [from string], [connection nick],
	  connection);
	id words = get_pref(HighlightingExtraWords);
	id shouldAdd = get_pref(HighlightingShouldDoNick);
	NSMutableArray *x = [NSMutableArray arrayWithObjects: nil]; 
	BOOL highlit;
	
	if (!shouldAdd || [shouldAdd isEqualToString: @"YES"])
	{
		[x addObject: [connection nick]];
	}
	
	if ([words isKindOfClass: [NSArray class]])
	{
		[x addObjectsFromArray: words];
	}
	sender = do_highlighting(self, [aMessage string], sender, x, 
	  where, connection, aNick, &highlit);
	handle_notifications(self, aMessage, @"Notice", sender, to, connection, highlit);
	
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
	id where = get_destination([to string], [from string], [connection nick],
	  connection);
	id words = get_pref(HighlightingExtraWords);
	id shouldAdd = get_pref(HighlightingShouldDoNick);
	NSMutableArray *x = [NSMutableArray arrayWithObjects: nil]; 
	BOOL highlit;
	
	if (!shouldAdd || [shouldAdd isEqualToString: @"YES"])
	{
		[x addObject: [connection nick]];
	}
	
	if ([words isKindOfClass: [NSArray class]])
	{
		[x addObjectsFromArray: words];
	}
	sender = do_highlighting(self, [aMessage string], sender, x, 
	  where, connection, aNick, &highlit); 
	handle_notifications(self, aMessage, @"Action", sender, to, connection, highlit);
	
	[_TS_ actionReceived: aMessage to: to from: sender 
	  onConnection: connection withNickname: aNick sender: self];
	return self;
}
@end

