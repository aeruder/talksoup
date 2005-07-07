/***************************************************************************
                                main.m
                          -------------------
    begin                : Fri Jan 17 11:38:55 CST 2003
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

#import "commands.h"

#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSString.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSException.h>

#include <stdlib.h>
#include <signal.h>
#include <time.h>

@interface NSException (blah)
@end

@implementation NSException (blah)
#if 0
- (void)raise
{
	abort();
}
#endif
@end

id GetSetting(NSString *key)
{
	id obj;
	NSUserDefaults *ud;

	ud = [NSUserDefaults standardUserDefaults];
	if (!(obj = [ud objectForKey: key]))
	{
		obj = [NSDictionary dictionaryWithContentsOfFile:
		  [[NSBundle mainBundle] pathForResource: @"Defaults"
		  ofType: @"plist"]];
		if ([key isEqualToString: @"Plugins"])
		{
			NSEnumerator *iter;
			id object;
			
			iter = [obj keyEnumerator];
			while ((object = [iter nextObject]))
			{
				[ud setObject: [obj objectForKey: object] forKey: object];
			}
		}
		
		obj = [obj objectForKey: key];
		
		if (obj)
		{
			[ud setObject: obj forKey: key];
		}
	
	}
	return obj;
}

int main(void)
{
	NSDictionary *defaultPlugins;
	CREATE_AUTORELEASE_POOL(apr);

	signal(SIGPIPE, SIG_IGN);
#ifdef GNUSTEP 
#ifdef DOUBLE_RELEASE_COUNT
	[NSObject enableDoubleReleaseCheck: YES];
#endif
#endif
	srand(time(NULL));

	[TalkSoup sharedInstance];
	
	defaultPlugins = GetSetting(@"Plugins");
	
	[_TS_ setInput: [defaultPlugins objectForKey: @"Input"]];
	[_TS_ setOutput: [defaultPlugins objectForKey: @"Output"]];
	[_TS_ setActivatedInFilters: [defaultPlugins objectForKey: @"InFilters"]];
	[_TS_ setActivatedOutFilters: [defaultPlugins objectForKey: @"OutFilters"]];
	[_TS_ setupCommandList];
	[[_TS_ pluginForOutput] run];
	
	DESTROY(apr);
	return EXIT_SUCCESS;
}
