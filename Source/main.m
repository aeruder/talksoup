/***************************************************************************
                                main.m
                          -------------------
    begin                : Fri Jan 17 11:38:55 CST 2003
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

#include "TalkSoup.h"

#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSString.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSHost.h>

#include <Foundation/NSEnumerator.h>

#include <stdlib.h>

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

	[NSObject enableDoubleReleaseCheck: YES];

	[TalkSoup sharedInstance];
	
	defaultPlugins = GetSetting(@"Plugins");
	
	NSLog(@"Default Plugins: %@", defaultPlugins);
	
	[_TS_ setInput: [defaultPlugins objectForKey: @"Input"]];
	[_TS_ setOutput: [defaultPlugins objectForKey: @"Output"]];
	[_TS_ setActivatedInFilters: [defaultPlugins objectForKey: @"InFilters"]];
	[_TS_ setActivatedOutFilters: [defaultPlugins objectForKey: @"OutFilters"]];
	[[_TS_ pluginForOutput] run];
	
	DESTROY(apr);
	return EXIT_SUCCESS;
}
