/***************************************************************************
                              Ignore.m
                          -------------------
    begin                : Tue Oct 11 17:18:36 CDT 2005
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

#import "Ignore.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSString.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator.h>

NSString *IgnoreMaskList = @"IgnoreMaskList";

static NSInvocation *ignore_invoc = nil;
static NSDictionary *ignore_defaults = nil;

#define get_pref(__x) [Ignore defaultsObjectForKey: (__x)]
#define set_pref(__x,__y) [Ignore setDefaultsObject: (__y) forKey: (__x)]

BOOL is_ignored(NSAttributedString *sender, id connection)
{
	NSArray *array;
	NSEnumerator *iter;
	id object;
	NSString *from = [sender string];
	SEL aSel;

	aSel = [connection lowercasingSelector];
	if (!aSel) aSel = @selector(lowercaseString);

	array = [Ignore defaultsObjectForKey: IgnoreMaskList];
	if (!array) 
		return NO;
		
	from = [from performSelector: aSel];
	iter = [array objectEnumerator];
	while ((object = [iter nextObject]))
	{
		if ([from matchesIRCWildcard: [object performSelector: aSel]]) return YES;
	}

	return NO;
}

NSAttributedString *ignore_summary(void)
{
	NSMutableAttributedString *new;
	NSArray *array;
	NSEnumerator *iter;
	id object;

	new = AUTORELEASE([NSMutableAttributedString new]);

	array = [Ignore defaultsObjectForKey: IgnoreMaskList];
	if (!array || [array count] == 0) 
		return BuildAttributedString(_l(@"No ignore masks defined."), nil);
	
	[new appendAttributedString: BuildAttributedString(_l(@"Ignore masks:"), @"\n", nil)];
	iter = [array objectEnumerator];
	while ((object = [iter nextObject]))
	{
		[new appendAttributedString: BuildAttributedString(@"   ", object, @"\n", nil)];
	}

	[new appendAttributedString: BuildAttributedString(_l(@"End list."), nil)];

	return new;
}

@implementation Ignore
+ (void)initialize
{
	if (ignore_invoc) return;

	ignore_invoc = RETAIN([NSInvocation invocationWithMethodSignature: 
	  [self methodSignatureForSelector: @selector(commandIgnore:connection:)]]);
	[ignore_invoc retainArguments];
	[ignore_invoc setTarget: self];
	[ignore_invoc setSelector: @selector(commandIgnore:connection:)];

	/*
	ignore_defaults = [[NSMutableDictionary alloc] initWithContentsOfFile:
	  [[NSBundle bundleForClass: [Ignore class]] 
	  pathForResource: @"Defaults" ofType: @"plist"]];
	*/
	ignore_defaults = [NSMutableDictionary new];
}	
+ (NSAttributedString *)commandIgnore: (NSString *)args 
   connection: connection
{
	id x = [args separateIntoNumberOfArguments: 3];
	unsigned cnt = [x count];
	id array, cmd, lastarg;

	if (cnt == 0)
	{
		return BuildAttributedString(_l(@"Usage:"), 
		  @"\n   ", _l(@"/ignore - this screen"),
		  @"\n   ", _l(@"/ignore del mask - remove ignore mask"),
		  @"\n   ", _l(@"/ignore [add] mask - add ignore mask"),
		  @"\n", ignore_summary(), nil);
	}

	cmd = [x objectAtIndex: 0];
	if (cnt == 1)
	{
		if ([cmd isEqualToString: @"add"] || [cmd isEqualToString: @"del"])
			return BuildAttributedString(_l(@"Missing required argument."), @"\n",
			  [self commandIgnore: @"" connection: connection], nil);
		return [self commandIgnore: [NSString stringWithFormat: @"add %@", cmd]
		  connection: connection];
	}

	lastarg = [x objectAtIndex: 1];

	array = [self defaultsObjectForKey: IgnoreMaskList];
	if (!array) 
		array = AUTORELEASE([NSMutableArray new]);
	else
		array = [NSMutableArray arrayWithArray: array];

	if ([cmd isEqualToString: @"add"])
	{
		[array removeObject: lastarg];
		[array addObject: lastarg];
		[self setDefaultsObject: array forKey: IgnoreMaskList];
		return BuildAttributedFormat(_l(@"Added '%@' mask to ignore list."),
		  lastarg);
	}
	else if ([cmd isEqualToString: @"del"])
	{
		if (![array containsObject: lastarg])
			return BuildAttributedFormat(_l(@"Mask '%@' not found.\n%@"), lastarg,
			  [self commandIgnore: @"" connection: connection]);
		[array removeObject: lastarg];
		[self setDefaultsObject: array forKey: IgnoreMaskList];
		return BuildAttributedFormat(_l(@"Removed '%@' mask from ignore list."),
		  lastarg);
	} 

	return BuildAttributedFormat(_l(@"Subcommand '%@' not understood.\n%@"), cmd,
	  [self commandIgnore: @"" connection: connection]);
}
+ (NSDictionary *)defaultSettings
{
	return ignore_defaults;
}
+ (void)setDefaultsObject: aObject forKey: aKey
{
	NSUserDefaults *object = [NSUserDefaults standardUserDefaults];
	
	if ([aKey hasPrefix: @"Ignore"] && ![aKey isEqualToString: @"Ignore"])
	{
		NSMutableDictionary *y;
		NSDictionary *tmp;
		
		aKey = [aKey substringFromIndex: 12];
		tmp = [object objectForKey: @"Ignore"];
		
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
		
		[object setObject: y forKey: @"Ignore"];
	}
}
+ (id)defaultsObjectForKey: aKey
{
	NSDictionary *object = 
	  (NSMutableDictionary *)[NSUserDefaults standardUserDefaults];
	
	if ([aKey hasPrefix: @"Ignore"] && ![aKey isEqualToString: @"Ignore"])
	{
		aKey = [aKey substringFromIndex: 12];
		object = [object objectForKey: @"Ignore"];
		if (!(object))
		{
			[[NSUserDefaults standardUserDefaults] setObject:
			  object = ignore_defaults forKey: @"Ignore"];
		}
		return (object = [object objectForKey: aKey]) ? object : 
		  [ignore_defaults objectForKey: aKey];
	}
	
	return [object objectForKey: aKey];
}
+ (id)defaultDefaultsForKey: aKey
{
	return [ignore_defaults objectForKey: aKey];
}
- (NSAttributedString *)pluginDescription
{
	return BuildAttributedString([NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Author: "), @"Andrew Ruder\n\n",
	 [NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Description: "), _l(@"Adds /ignore command.  Special thanks goes to"
	  @" Patrick \"Diablo-D3\" McFarland for inspiring this plugin."),
	 nil);
}
- pluginActivated
{
	[_TS_ addCommand: @"ignore" withInvocation: ignore_invoc];
	return self;
}
- pluginDeactivated
{
	[_TS_ removeCommand: @"ignore"];
	return self;
}
- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	if (!is_ignored(sender, connection))
		[_TS_ messageReceived: aMessage to: to from: sender onConnection: connection
		  withNickname: aNick sender: self];
	return self;
}
- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	if (!is_ignored(sender, connection))
		[_TS_ noticeReceived: aMessage to: to from: sender onConnection: connection
		  withNickname: aNick sender: self];
	return self;
}
- actionReceived: (NSAttributedString *)anAction to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	if (!is_ignored(sender, connection))
		[_TS_ actionReceived: anAction to: to from: sender onConnection: connection
		  withNickname: aNick sender: self];
	return self;
}
@end

