/***************************************************************************
                                TalkSoup.m
                          -------------------
    begin                : Fri Jan 17 11:04:36 CST 2003
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

#include <Foundation/NSString.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSPathUtilities.h>

NSString *IRCDefaultsNick =  @"Nick";
NSString *IRCDefaultsRealName = @"RealName";
NSString *IRCDefaultsUserName = @"UserName";
NSString *IRCDefaultsPassword = @"Password";

NSString *IRCColor = @"IRCColor";
NSString *IRCBackgroundColor = @"IRCBackgroundColor";
NSString *IRCColorWhite = @"IRCColorWhite";
NSString *IRCColorBlack = @"IRCColorBlack";
NSString *IRCColorBlue = @"IRCColorBlue";
NSString *IRCColorGreen = @"IRCColorGreen";
NSString *IRCColorRed = @"IRCColorRed";
NSString *IRCColorMaroon = @"IRCColorMaroon";
NSString *IRCColorMagenta = @"IRCColorMagenta";
NSString *IRCColorOrange = @"IRCColorOrange";
NSString *IRCColorYellow = @"IRCColorYellow";
NSString *IRCColorLightGreen = @"IRCColorLightGreen";
NSString *IRCColorTeal = @"IRCColorTeal";
NSString *IRCColorLightCyan = @"IRCColorLightCyan";
NSString *IRCColorLightBlue = @"IRCColorLightBlue";
NSString *IRCColorLightMagenta = @"IRCColorLightMagenta";
NSString *IRCColorGrey = @"IRCColorGrey";
NSString *IRCColorLightGrey = @"IRCColorLightGrey";
NSString *IRCColorCustom = @"IRCColorCustom";
NSString *IRCBold = @"IRCBold";
NSString *IRCUnderline = @"IRCUnderline";

id _TS_;
id _TSDummy_;

@interface NSException (blah)
@end

#if 0
@implementation NSException (blah)
- (void)raise
{
	abort();
}
@end
#endif

static inline id activate_bundle(NSDictionary *a, NSString *name)
{
	id dir;
	id bundle;
	
	if (!name)
	{
		NSLog(@"Can't activate a bundle with a nil name!");
		return nil;
	}
	
	if (!(dir = [a objectForKey: name]))
	{
		NSLog(@"Could not load '%@' from '%@'", name, [a allValues]);
		return nil;
	}
	
	bundle = [NSBundle bundleWithPath: dir];
	if (!bundle)
	{
		NSLog(@"Could not load '%@' from '%@'", name, dir);
		return nil;
	}
	
	return AUTORELEASE([[[bundle principalClass] alloc] init]);
}
static inline void carefully_add_bundles(NSMutableDictionary *a, NSArray *arr)
{
	NSEnumerator *iter;
	id object;
	id bundle;
	
	iter = [arr objectEnumerator];
	while ((object = [iter nextObject]))
	{
		bundle = [object lastPathComponent];
		if (![a objectForKey: bundle])
		{
			[a setObject: object forKey: bundle];
		}
	}
}	
static inline NSArray *get_directories_with_talksoup()
{
	NSArray *x;
	NSMutableArray *y;
	NSFileManager *fm;
	id object;
	NSEnumerator *iter;
	BOOL isDir;

	x = NSSearchPathForDirectoriesInDomains(GSApplicationSupportDirectory, 
	  NSAllDomainsMask, YES);

	NSLog(@"%@", x);

	fm = [NSFileManager defaultManager];

	iter = [x objectEnumerator];
	y = [NSMutableArray new];

	NSLog(@"%@", x);
	while ((object = [iter nextObject]))
	{
		object = [object stringByAppendingString: 
		  @"/TalkSoup"];
		
		if ([fm fileExistsAtPath: object isDirectory: &isDir] && isDir)
		{
			[y addObject: object];
		}
	}

	x = [NSArray arrayWithArray: y];
	RELEASE(y);

	return x;
}
static inline NSArray *get_bundles_in_directory(NSString *dir)
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

@implementation TalkSoup
+ (TalkSoup *)sharedInstance
{
	if (!_TS_)
	{
		AUTORELEASE([TalkSoup new]);
		if (!_TS_)
		{
			NSLog(@"Couldn't initialize the TalkSoup object");
		}
		_TSDummy_ = [TalkSoupDummyProtocolClass new];
	}

	return _TS_;
}
- init
{
	if (_TS_) return nil;
	
	if (!(self = [super init])) return nil;

	[self refreshPluginList];
	commandList = [NSMutableDictionary new];
		
	activatedInFilters = [NSMutableArray new];
	inObjects = [NSMutableDictionary new];
	
	activatedOutFilters = [NSMutableArray new];
	outObjects = [NSMutableDictionary new];
	
	_TS_ = RETAIN(self);
	
	return self;
}
- (void)refreshPluginList
{
	NSArray *dirList;
	id object;
	NSEnumerator *iter;
	id arr;
	
	dirList = get_directories_with_talksoup();

	iter = [dirList objectEnumerator];
	
	RELEASE(inputNames);
	RELEASE(outputNames);
	RELEASE(inNames);
	RELEASE(outNames);

	inputNames = [NSMutableDictionary new];
	outputNames = [NSMutableDictionary new];
	inNames = [NSMutableDictionary new];
	outNames = [NSMutableDictionary new];
	
	while ((object = [iter nextObject]))
	{
		arr = get_bundles_in_directory(
		  [object stringByAppendingString: @"/Input"]);
		carefully_add_bundles(inputNames, arr);
		
		arr = get_bundles_in_directory(
		  [object stringByAppendingString: @"/InFilters"]);
		carefully_add_bundles(inNames, arr);

		arr = get_bundles_in_directory(
		  [object stringByAppendingString: @"/OutFilters"]);
		carefully_add_bundles(outNames, arr);
		
		arr = get_bundles_in_directory(
		  [object stringByAppendingString: @"/Output"]);
		carefully_add_bundles(outputNames, arr);
	}
}
- (NSInvocation *)invocationForCommand: (NSString *)aCommand
{
	return [commandList objectForKey: [aCommand uppercaseString]];
}
- addCommand: (NSString *)aCommand withInvocation: (NSInvocation *)invoc
{
	[commandList setObject: invoc forKey: [aCommand uppercaseString]];
	return self;
}
- removeCommand: (NSString *)aCommand
{
	[commandList removeObjectForKey: [aCommand uppercaseString]];
	return self;
}
- (NSArray *)allCommands
{
	return [commandList allKeys];
}
- (BOOL)respondsToSelector: (SEL)aSel
{
	if ([_TSDummy_ respondsToSelector: aSel]) return YES;

	return [super respondsToSelector: aSel];
}
- (NSMethodSignature *)methodSignatureForSelector: (SEL)aSel
{
	id object;
	
	if ((object = [_TSDummy_ methodSignatureForSelector: aSel]))
		return object;
	
	return [super methodSignatureForSelector: aSel];
}
- (void)forwardInvocation: (NSInvocation *)aInvocation
{
	NSMutableArray *in;
	NSMutableArray *out;
	SEL sel;
	id selString;
	int args;
	int index = NSNotFound;
	id sender;
	id next;

	sel = [aInvocation selector];
	selString = NSStringFromSelector(sel);
	args = [[selString componentsSeparatedByString: @":"] count] - 1;
	
	if (![selString hasSuffix: @"sender:"])
	{
		[super forwardInvocation: aInvocation];
		return;
	}

	[aInvocation retainArguments];

	in = [NSMutableArray arrayWithObjects: input, nil];
	out = [NSMutableArray arrayWithObjects: output, nil];

	[in addObjectsFromArray: activatedInFilters];
	[out addObjectsFromArray: activatedOutFilters];

	[aInvocation getArgument: &sender atIndex: args + 1];

	if ((index = [in indexOfObjectIdenticalTo: sender]) != NSNotFound)
	{
		NSLog(@"In %@ by %@", selString, sender);
		if (index == ([in count] - 1))
		{
			next = output;
		}
		else
		{
			next = [in objectAtIndex: index + 1];
		}
		
		if ([next respondsToSelector: sel])
		{
			[aInvocation invokeWithTarget: next];
			return;
		}
		else
		{
			if (next != output)
			{
				[aInvocation setArgument: &next atIndex: args + 1];
				[self forwardInvocation: aInvocation];
			}
		}
	}
	else if ((index = [out indexOfObjectIdenticalTo: sender]) != NSNotFound)
	{
		id connection;
		NSLog(@"Out %@ by %@", selString, sender);
		if (![selString hasSuffix: @"Connection:sender:"])
		{
			[super forwardInvocation: aInvocation];
			return;
		}
		if (index == ([out count] - 1))
		{
			[aInvocation getArgument: &connection atIndex: args];
			next = connection;
		}
		else
		{
			next = [out objectAtIndex: index + 1];
		}

		if ([next respondsToSelector: sel])
		{
			[aInvocation invokeWithTarget: next];
			return;
		}
		else
		{
			if (next != connection)
			{
				[aInvocation setArgument: &next atIndex: args + 1];
				[self forwardInvocation: aInvocation];
			}
		}
	}
}
- (NSString *)input
{
	return activatedInput;
}
- (NSString *)output
{
	return activatedOutput;
}
- (NSDictionary *)allInputs
{
	return [NSDictionary dictionaryWithDictionary: inputNames];
}
- (NSDictionary *)allOutputs
{
	return [NSDictionary dictionaryWithDictionary: outputNames];
}
- setInput: (NSString *)aInput
{
	if (activatedInput) return self;
	
	input = RETAIN(activate_bundle(inputNames, aInput));
	
	if (input)
	{
		activatedInput = RETAIN(aInput);
	}
	
	if ([input respondsToSelector: @selector(pluginActivated)])
	{
		[input pluginActivated];
	}
	
	return self;
}			
- setOutput: (NSString *)aOutput
{
	if (activatedOutput) return self;
	
	output = RETAIN(activate_bundle(outputNames, aOutput));
	
	if (output)
	{
		activatedOutput = RETAIN(aOutput);
	}

	if ([output respondsToSelector: @selector(pluginActivated)])
	{
		[output pluginActivated];
	}
	
	return self;
}
- (NSArray *)activatedInFilters
{
	return [NSArray arrayWithArray: activatedInFilters];
}
- (NSArray *)activatedOutFilters
{
	return [NSArray arrayWithArray: activatedOutFilters];
}
- (NSDictionary *)allInFilters
{
	return [NSDictionary dictionaryWithDictionary: inNames];
}
- (NSDictionary *)allOutFilters
{
	return [NSDictionary dictionaryWithDictionary: outNames];
}
- activateInFilter: (NSString *)aFilt
{
	if (!aFilt) return self;
	id obj;
	
	if ((obj = [inObjects objectForKey: aFilt]))
	{
		if ([activatedInFilters containsObject: obj])
		{
			[activatedInFilters removeObject: obj];
			if ([obj respondsToSelector: @selector(pluginDeactivated)])
			{
				[obj pluginDeactivated];
			}
		}
		[activatedInFilters addObject: obj];
		if ([obj respondsToSelector: @selector(pluginActivated)])
		{
			[obj pluginActivated];
		}
		return self;
	}
	
	obj = activate_bundle(inNames, aFilt);
	if (!obj)
	{
		return self;
	}
	[inObjects setObject: obj forKey: aFilt];
	[activatedInFilters addObject: obj];
	
	if ([obj respondsToSelector: @selector(pluginActivated)])
	{
		[obj pluginActivated];
	}
	
	return self;
}
- activateOutFilter: (NSString *)aFilt
{
	if (!aFilt) return self;
	id obj;
	
	if ((obj = [outObjects objectForKey: aFilt]))
	{
		if ([activatedOutFilters containsObject: obj])
		{
			[activatedOutFilters removeObject: obj];
			if ([obj respondsToSelector: @selector(pluginDeactivated)])
			{
				[obj pluginDeactivated];
			}
			
		}
		[activatedOutFilters addObject: obj];
		if ([obj respondsToSelector: @selector(pluginActivated)])
		{
			[obj pluginActivated];
		}
		return self;
	}
	
	obj = activate_bundle(outNames, aFilt);
	if (!obj)
	{
		return self;
	}
	[outObjects setObject: obj forKey: aFilt];
	[activatedOutFilters addObject: obj];
	if ([obj respondsToSelector: @selector(pluginActivated)])
	{
		[obj pluginActivated];
	}
	
	return self;
}	
- deactivateInFilter: (NSString *)aFilt
{
	id obj;
	if (!aFilt) return self;
	
	if ((obj = [inObjects objectForKey: aFilt]))
	{
		if ([activatedInFilters containsObject: obj])
		{
			[activatedInFilters removeObject: obj];
			if ([obj respondsToSelector: @selector(pluginDeactivated)])
			{
				[obj pluginDeactivated];
			}
		}
	}
	
	return self;
}	
- deactivateOutFilter: (NSString *)aFilt
{
	id obj;
	if (!aFilt) return self;
	
	if ((obj = [outObjects objectForKey: aFilt]))
	{
		if ([activatedOutFilters containsObject: obj])
		{
			[activatedOutFilters removeObject: obj];
			if ([obj respondsToSelector: @selector(pluginDeactivated)])
			{
				[obj pluginDeactivated];
			}
		}
	}
	
	return self;
}
- setActivatedInFilters: (NSArray *)filters
{
	NSEnumerator *iter;
	id object;
	
	while ([activatedInFilters count] > 0)
	{
		object = [activatedInFilters objectAtIndex: 0];
		[activatedInFilters removeObjectAtIndex: 0];
		if ([object respondsToSelector: @selector(pluginDeactivated)])
		{
			[object pluginDeactivated];
		}
	}
	
	iter = [filters objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[self activateInFilter: object];
	}
	return self;
}	
- setActivatedOutFilters: (NSArray *)filters
{
	NSEnumerator *iter;
	id object;
	
	while ([activatedOutFilters count] > 0)
	{
		object = [activatedOutFilters objectAtIndex: 0];
		[activatedOutFilters removeObjectAtIndex: 0];
		if ([object respondsToSelector: @selector(pluginDeactivated)])
		{
			[object pluginDeactivated];
		}
	}
	
	iter = [filters objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[self activateOutFilter: object];
	}
	return self;
}
- (id)pluginForOutput
{
	return output;
}
- (id)pluginForOutFilter: (NSString *)aFilt
{
	id obj;
	
	if (!aFilt) return nil;
	
	if ((obj = [outObjects objectForKey: aFilt]))
	{
		return obj;
	}
	
	obj = activate_bundle(outNames, aFilt);
	
	if (obj)
	{
		[outObjects setObject: obj forKey: aFilt];
	}
	
	return obj;
}
- (id)pluginForInFilter: (NSString *)aFilt
{
	id obj;
	
	if (!aFilt) return nil;
	
	if ((obj = [inObjects objectForKey: aFilt]))
	{
		return obj;
	}
	
	obj = activate_bundle(inNames, aFilt);
	
	if (obj)
	{
		[inObjects setObject: obj forKey: aFilt];
	}
	
	return obj;
}
- (id)pluginForInput
{
	return input;
}
@end
