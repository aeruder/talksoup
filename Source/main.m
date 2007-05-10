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
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSHost.h>

#include <Foundation/NSFileManager.h>
#include <Foundation/NSEnumerator.h>

#include <stdlib.h>

NSArray *InputPluginList = nil;
NSArray *OutputPluginList = nil;
NSArray *InFilterPluginList = nil;
NSArray *OutFilterPluginList = nil;

static NSArray *get_directories_with_talksoup()
{
	NSArray *x;
	NSMutableArray *y;
	NSFileManager *fm;
	id object;
	NSEnumerator *iter;
	BOOL isDir;

	x = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, 
	  NSAllDomainsMask, YES);

	fm = [NSFileManager defaultManager];

	iter = [x objectEnumerator];
	y = [NSMutableArray new];

	NSLog(@"%@", x);
	while ((object = [iter nextObject]))
	{
		object = [object stringByAppendingString: @"/TalkSoup"];
		
		if ([fm fileExistsAtPath: object isDirectory: &isDir] && isDir)
		{
			[y addObject: object];
		}
	}

	x = [NSArray arrayWithArray: y];
	RELEASE(y);

	return x;
}
static NSArray *get_bundles_in_directory(NSString *dir)
{
	NSFileManager *fm;
	NSEnumerator *iter;
	id object;
	BOOL isDir;
	NSMutableArray *y;
	NSArray *x;
	
	fm = [NSFileManager defaultManager];
	
	x = [fm directoryContentsAtPath: dir];

	if (!x)
	{
		return AUTORELEASE([NSArray new]);
	}
	
	y = [NSMutableArray new];

	iter = [x objectEnumerator];

	while ((object = [iter nextObject]))
	{
		object = [NSString stringWithFormat: @"%@/%@", dir, object];
		if ([fm fileExistsAtPath: object isDirectory: &isDir] && isDir)
		{
			if ([object hasSuffix: @".bundle"])
			{
				[y addObject: object];
			}
		}
	}

	x = [NSArray arrayWithArray: y];
	RELEASE(y);

	return x;
}
NSBundle *FindPluginInArray(NSString *aString, NSArray *arr)
{
	NSEnumerator *iter;
	id object;

	iter = [arr objectEnumerator];

	while ((object = [iter nextObject]))
	{
		if ([[object lastPathComponent] isEqualToString: aString])
		{
			return [NSBundle bundleWithPath: object];
		}
	}

	return nil;
}
void BuildPluginList()
{
	NSArray *dirList;
	id object;
	NSEnumerator *iter;
	
	dirList = get_directories_with_talksoup();

	iter = [dirList objectEnumerator];
	
	RELEASE(InputPluginList);
	RELEASE(OutputPluginList);
	RELEASE(InFilterPluginList);
	RELEASE(OutFilterPluginList);

	InputPluginList = AUTORELEASE([NSArray new]);
	OutputPluginList = AUTORELEASE([NSArray new]);
	InFilterPluginList = AUTORELEASE([NSArray new]);
	OutFilterPluginList = AUTORELEASE([NSArray new]);
	
	while ((object = [iter nextObject]))
	{
		InputPluginList = [InputPluginList arrayByAddingObjectsFromArray: 
		  get_bundles_in_directory(
		  [object stringByAppendingString: @"/Input"])];
		InFilterPluginList = [InFilterPluginList arrayByAddingObjectsFromArray: 
		  get_bundles_in_directory(
		  [object stringByAppendingString: @"/InFilter"])];
		OutFilterPluginList = [OutFilterPluginList 
		  arrayByAddingObjectsFromArray: get_bundles_in_directory(
		  [object stringByAppendingString: @"/OutFilter"])];
		OutputPluginList = [OutputPluginList arrayByAddingObjectsFromArray: 
		  get_bundles_in_directory(
		  [object stringByAppendingString: @"/Output"])];
	}
}

id GetSetting(NSString *key)
{
	id obj;
	NSUserDefaults *ud;

	ud = [NSUserDefaults standardUserDefaults];
	if (!(obj = [ud objectForKey: key]))
	{
		obj = [[NSDictionary dictionaryWithContentsOfFile: 
		  [[NSBundle mainBundle] pathForResource: @"Defaults" 
		  ofType: @"plist"]] objectForKey: key];
		
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
	NSBundle *x;
	id object;
	CREATE_AUTORELEASE_POOL(apr);

	[NSObject enableDoubleReleaseCheck: YES];

	[TalkSoup sharedInstance];
	
	defaultPlugins = GetSetting(@"Plugins");
	
	NSLog(@"Default Plugins: %@", defaultPlugins);
	BuildPluginList();	
	NSLog(@"Input: %@ Output: %@ InFilter: %@ OutFilter: %@", InputPluginList, 
	   OutputPluginList, InFilterPluginList, OutFilterPluginList);
	
	x = FindPluginInArray([defaultPlugins objectForKey: @"Input"], 
	  InputPluginList);
	if (!x)
	{
		NSLog(@"Could not load input plugin: %@",
		  [defaultPlugins objectForKey: @"Input"]);
	}

	object = [[[x principalClass] alloc] init];
		
	[_TS_ setInput: object];
	
	x = FindPluginInArray([defaultPlugins objectForKey: @"Output"],
	  OutputPluginList);
	if (!x)
	{
		NSLog(@"Could not load output plugin: %@",
		  [defaultPlugins objectForKey: @"Output"]);
	}

	object = [[[x principalClass] alloc] init];

	[_TS_ setOutput: object];

	[object run];
	
	DESTROY(apr);
	return EXIT_SUCCESS;
}
