/***************************************************************************
                                TalkSoup.m
                          -------------------
    begin                : Fri Jan 17 11:04:36 CST 2003
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

#import "TalkSoup.h"
#import "TalkSoupPrivate.h"

#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSAutoreleasePool.h>

NSString *DefaultsChangedNotification = @"DefaultsChangedNotification";

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
NSString *IRCBoldValue = @"IRCBoldValue";
NSString *IRCUnderline = @"IRCUnderline";
NSString *IRCUnderlineValue = @"IRCUnderlineValue";
NSString *IRCReverse = @"IRCReverse";
NSString *IRCReverseValue = @"IRCReverseValue";

id _TS_;
id _TSDummy_;

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

	x = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, 
	  NSAllDomainsMask, YES);

	fm = [NSFileManager defaultManager];

	iter = [x objectEnumerator];
	y = [NSMutableArray new];

	while ((object = [iter nextObject]))
	{
		object = [object stringByAppendingString: 
#ifdef GNUSTEP 
		  @"/ApplicationSupport/TalkSoup"
#else
		  @"/Application Support/TalkSoup"
#endif
		  ];
		
		if ([fm fileExistsAtPath: object isDirectory: &isDir] && isDir)
		{
			[y addObject: object];
		}
	}

	[y addObject: [[NSBundle mainBundle] resourcePath]];

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
			[y addObject: object];
		}
	}

	x = [NSArray arrayWithArray: y];
	RELEASE(y);

	return x;
}

static void add_old_entries(NSMutableDictionary *new, NSMutableDictionary *names,
  NSMutableDictionary *objects)
{
	NSEnumerator *iter;
	id object;
	
	if (!names) return;
	
	iter = [objects keyEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[new setObject: [names objectForKey: object] forKey: object];
	}
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

	[self buildEncodingsList];
	
	return self;
}
- (void)buildEncodingsList
{
	const NSStringEncoding *curr;

	encodings = NSCreateMapTable(NSObjectMapKeyCallBacks, NSIntMapValueCallBacks, 20);
	
	for (curr = [NSString availableStringEncodings]; *curr != 0; curr++)
	{
		NSMapInsert(encodings, StringFromEncoding(*curr), 
		  (const void *)*curr);
	}
}
- (void)refreshPluginList
{
	NSArray *dirList;
	id object;
	NSEnumerator *iter;
	id arr;
	id inputNames2, outputNames2, inNames2, outNames2;
	
	dirList = get_directories_with_talksoup();

	iter = [dirList objectEnumerator];

	inputNames2 = [NSMutableDictionary new];
	outputNames2 = [NSMutableDictionary new];
	inNames2 = [NSMutableDictionary new];
	outNames2 = [NSMutableDictionary new];
	
	while ((object = [iter nextObject]))
	{
		arr = get_bundles_in_directory(
		 [object stringByAppendingString: @"/Input"]);
		carefully_add_bundles(inputNames2, arr);
		
		arr = get_bundles_in_directory(
		 [object stringByAppendingString: @"/InFilters"]);
		carefully_add_bundles(inNames2, arr);

		arr = get_bundles_in_directory(
		 [object stringByAppendingString: @"/OutFilters"]);
		carefully_add_bundles(outNames2, arr);
		
		arr = get_bundles_in_directory(
		 [object stringByAppendingString: @"/Output"]);
		carefully_add_bundles(outputNames2, arr);
	}
	
	if (activatedInput)
	{
		[inputNames2 setObject: [inputNames objectForKey: activatedInput] forKey: 
		  activatedInput];
	}
	
	if (activatedOutput)
	{
		[outputNames2 setObject: [outputNames objectForKey: activatedOutput] forKey:
		  activatedOutput];
	}
	
	add_old_entries(inNames2, inNames, inObjects);
	add_old_entries(outNames2, outNames, outObjects);
	
	RELEASE(inputNames);
	RELEASE(outputNames);
	RELEASE(inNames);
	RELEASE(outNames);

	inputNames = inputNames2;
	outputNames = outputNames2;
	inNames = inNames2;
	outNames = outNames2;
}
- (void)savePluginList
{	
	id dict = [NSDictionary dictionaryWithObjectsAndKeys:
	  activatedInput, @"Input",
	  activatedOutput, @"Output",
	  [self activatedOutFilters], @"OutFilters",
	  [self activatedInFilters], @"InFilters",
	  nil];
	
	[[NSUserDefaults standardUserDefaults] setObject: dict forKey: @"Plugins"];
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
	if (!aSel) return NO;
	
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
	CREATE_AUTORELEASE_POOL(apr);

	sel = [aInvocation selector];
	selString = NSStringFromSelector(sel);
	args = [[selString componentsSeparatedByString: @":"] count] - 1;
	
	if (![selString hasSuffix: @"sender:"])
	{
		[super forwardInvocation: aInvocation];
		goto out1;
	}

	[aInvocation retainArguments];

	in = [[NSMutableArray alloc] initWithObjects: input, nil];
	out = [[NSMutableArray alloc] initWithObjects: output, nil];

	[in addObjectsFromArray: activatedInFilters];
	[out addObjectsFromArray: activatedOutFilters];

	[aInvocation getArgument: &sender atIndex: args + 1];

	if ((index = [in indexOfObjectIdenticalTo: sender]) != NSNotFound)
	{

#ifdef GNUSTEP
		NSDebugLLog(@"TalkSoup", @"In %@ by %@", selString, sender);
#endif

		if (index == (int)([in count] - 1))
		{
			next = output;
		}
		else
		{
			next = [in objectAtIndex: index + 1];
		}
		
		if (sel && [next respondsToSelector: sel])
		{
			[aInvocation invokeWithTarget: next];
			goto out2;
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

		[aInvocation getArgument: &connection atIndex: args - 1];
		
#ifdef GNUSTEP
		NSDebugLLog(@"TalkSoup", @"Out %@ by %@", selString, sender);
#endif

		if (index == (int)([out count] - 1))
		{
			next = connection;
		}
		else
		{
			next = [out objectAtIndex: index + 1];
		}

		if (sel && [next respondsToSelector: sel])
		{
			[aInvocation invokeWithTarget: next];
			goto out2;
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
out2:
	RELEASE(in);
	RELEASE(out);
out1:
	RELEASE(apr);
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
	NSEnumerator *iter;
	id object;
	NSMutableArray *x = AUTORELEASE([[NSMutableArray alloc] init]);
	
	iter = [activatedInFilters objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[x addObject: [[inObjects allKeysForObject: object] objectAtIndex: 0]];
	}
	
	return x;
}
- (NSArray *)activatedOutFilters
{
	NSEnumerator *iter;
	id object;
	NSMutableArray *x = AUTORELEASE([[NSMutableArray alloc] init]);
	
	iter = [activatedOutFilters objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[x addObject: [[outObjects allKeysForObject: object] objectAtIndex: 0]];
	}
	
	return x;
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

