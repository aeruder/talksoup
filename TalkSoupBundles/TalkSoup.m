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

#import "TalkSoup.h"

#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSNull.h>

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

@interface TalkSoup (Commands)
- (void)setupCommandList;
@end

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
		  @"/ApplicationSupport/TalkSoup"];
		
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
	[self setupCommandList];
	
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

#ifdef GNUSTEP
		NSDebugLLog(@"TalkSoup", @"Out %@ by %@", selString, sender);
#endif

		if (index == (int)([out count] - 1))
		{
			[aInvocation getArgument: &connection atIndex: args - 1];
			next = connection;
		}
		else
		{
			next = [out objectAtIndex: index + 1];
		}

		if (sel && [next respondsToSelector: sel])
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

#define MARK [NSNull null]
#define NO_CONNECT S2AS(_(@"Connect to a server before using this command"))

@implementation TalkSoup (Commands)
- (NSAttributedString *)commandSaveLoaded: (NSString *)args 
   connection: (id)connection
{
	[self savePluginList];

	return S2AS(_(@"The loaded bundles will now load automagically on TalkSoup startup."));
}
- (NSAttributedString *)commandLoaded: (NSString *)args connection: (id)connection
{
	return BuildAttributedString(_(@"Currently loaded bundles:\n"),
	  MARK, IRCBold, IRCBoldValue, _(@"Output: "), activatedOutput, @"\n",
	  MARK, IRCBold, IRCBoldValue, _(@"Input: "), activatedInput, @"\n",
	  MARK, IRCBold, IRCBoldValue, _(@"Output Filters: "), [[self activatedOutFilters]
	    componentsJoinedByString: @", "], @"\n",
	  MARK, IRCBold, IRCBoldValue, _(@"Input Filters: "), [[self activatedInFilters]
	    componentsJoinedByString: @", "], nil);
}
- (NSAttributedString *)commandLoad: (NSString *)args connection: (id)connection
{
	id x = [args separateIntoNumberOfArguments: 3];
	id first, second;
	id array = nil;
	BOOL isIn = NO;
	
	[self refreshPluginList];
	
	if ([x count] < 1)
	{
		return S2AS(_(@"Usage: /load <in/out>"));
	}
	
	first = [x objectAtIndex: 0];
	
	if ([first isEqualToString: @"in"])
	{
		array = [inNames allKeys];
		isIn = YES;
	}
	else if ([first isEqualToString: @"out"])
	{
		array = [outNames allKeys];
	}
	else
	{
		return S2AS(_(@"Usage: /load <in/out>"));
	}
	
	second = ([x count] > 1) ? [x objectAtIndex: 1] : nil;
	
	if (!second || ![array containsObject: second])
	{
		return BuildAttributedString(
		  _(@"Usage: /load <in/out> <filter>"), @"\n",
		  MARK, IRCBold, IRCBoldValue, _(@"Possible filters: "), 
		  [array componentsJoinedByString: @", "], nil);
	}
	
	if (isIn)
	{
		[self activateInFilter: second];
	}
	else
	{
		[self activateOutFilter: second];
	}
	
	return BuildAttributedString(second, _(@" loaded"), nil);
}
- (NSAttributedString *)commandUnload: (NSString *)args connection: (id)connection
{
	id x = [args separateIntoNumberOfArguments: 3];
	id first, second;
	id array = nil;
	BOOL isIn = NO;
	
	if ([x count] < 1)
	{
		return S2AS(_(@"Usage: /unload <in/out>"));
	}
	
	first = [x objectAtIndex: 0];
	
	if ([first isEqualToString: @"in"])
	{
		array = [self activatedInFilters];
		isIn = YES;
	}
	else if ([first isEqualToString: @"out"])
	{
		array = [self activatedOutFilters];
	}
	else
	{
		return S2AS(_(@"Usage: /unload <in/out>"));
	}
	
	second = ([x count] > 1) ? [x objectAtIndex: 1] : nil;
	
	if (!second || ![array containsObject: second])
	{
		return BuildAttributedString(
		  _(@"Usage: /unload <in/out> <filter>"), @"\n", 
		  MARK, IRCBold, IRCBoldValue, _(@"Possible filters: "), 
		  [array componentsJoinedByString: @", "], nil);
	}
	
	if (isIn)
	{
		[self deactivateInFilter: second];
	}
	else
	{
		[self deactivateOutFilter: second];
	}
	
	return BuildAttributedString(second, _(@" unloaded"), nil);
}
- (NSAttributedString *)commandJoin: (NSString *)aString connection: connection
{
	NSArray *x = [aString separateIntoNumberOfArguments: 3];
	id pass;
	
	if (!connection) return NO_CONNECT;
	
	if ([x count] == 0)
	{
		return S2AS(_(@"Usage: /join <channel1[,channel2...]> [password1[,password2...]]"));
	}
	
	pass = ([x count] == 2) ? [x objectAtIndex: 1] : nil;
	
	[_TS_ joinChannel: S2AS([x objectAtIndex: 0]) withPassword: S2AS(pass) 
	  onConnection: connection
	  withNickname: S2AS([connection nick])
	  sender: output];
	  
	return nil;
}
- (NSAttributedString *)commandMsg: (NSString *)aString connection: connection
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	
	if (!connection) return NO_CONNECT;
	
	if ([x count] < 2)
	{
		return S2AS(_(@"Usage: /msg <person> <message>"));
	}
	
	[_TS_ sendMessage: S2AS([x objectAtIndex: 1]) to: 
	  S2AS([x objectAtIndex: 0])
	  onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: output];

	return nil;
}
- (NSAttributedString *)commandPart: (NSString *)args connection: connection
{
	id x = [args separateIntoNumberOfArguments: 2];
	id name, msg;
	
	if (!connection) return NO_CONNECT;
	
	msg = name = nil;
	
	if ([x count] >= 1)
	{
		name = [x objectAtIndex: 0];
	}
	if ([x count] >= 2)
	{
		msg = [x objectAtIndex: 1];
	}
	
	if (!name)
	{
		return S2AS(_(@"Usage: /part <channel> [message]"));
	}
	
	[_TS_ partChannel: S2AS(name) withMessage: S2AS(msg) 
	  onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandNotice: (NSString *)aString connection: connection
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	
	if (!connection) return NO_CONNECT;
	
	if ([x count] < 2)
	{
		return S2AS(_(@"Usage: /notice <person> <message>"));
	}
	
	[_TS_ sendNotice: S2AS([x objectAtIndex: 1]) to: 
	  S2AS([x objectAtIndex: 0])
	  onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: output];

	return nil;
}
- (NSAttributedString *)commandAway: (NSString *)aString connection: connection
{
	NSArray *x = [aString separateIntoNumberOfArguments: 1];
	id y = nil;
	
	if (!connection) return NO_CONNECT;
	
	if ([x count] > 0)
	{
		y = [x objectAtIndex: 0];
	}
	
	[_TS_ setAwayWithMessage: S2AS(y) onConnection: connection
	  withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- commandNick: (NSString *)aString connection: connection
{
	NSArray *x = [aString separateIntoNumberOfArguments: 2];
	
	if (!connection) return NO_CONNECT;
	
	if ([x count] == 0)
	{
		return S2AS(_(@"Usage: /nick <newnick>"));
	}
	
	[_TS_ changeNick: S2AS([x objectAtIndex: 0]) onConnection: connection
	  withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandQuit: (NSString *)aString connection: connection
{
	if (!connection) return NO_CONNECT;
	
	[_TS_ quitWithMessage: S2AS(aString) onConnection: connection
	  withNickname: S2AS([connection nick]) sender: output];
	
	return nil;
}
- (NSAttributedString *)commandColors: (NSString *)aString connection: connection
{
	return BuildAttributedString(
	 _(@"Valid color names include any color from the following list: "),
	 [PossibleUserColors() componentsJoinedByString: @", "], @"\n",
	 _(@"Also, a string is valid if it is of the form 'custom [red] [green] [blue]' "),
	  _(@"where [red], [green], [blue] are the red, green, and blue "),
	  _(@"components of the color on a scale of 0 to 1000."), nil);
}  		  
- (NSAttributedString *)commandCtcp: (NSString *)command connection: connection
{
	id array;
	id ctcp;
	id args;
	id who;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 3];
	
	if ([array count] < 2)
	{
		return S2AS(_(@"Usage: /ctcp <nick> <ctcp> [arguments]")); 
	}

	args = ([array count] == 3) ? [array objectAtIndex: 2] : nil;
	
	ctcp = [[array objectAtIndex: 1] uppercaseString];
	who = [array objectAtIndex: 0];

	[_TS_ sendCTCPRequest: S2AS(ctcp) withArgument: S2AS(args)
	  to: S2AS(who) onConnection: connection 
	  withNickname: S2AS([connection nick]) sender: output];
	
	return nil;
}	
- (NSAttributedString *)commandVersion: (NSString *)command connection: connection
{
	id array;
	id who;
	
	array = [command separateIntoNumberOfArguments: 2];

	if (!connection) return NO_CONNECT;
	
	if ([array count] == 0)
	{
		return S2AS(_(@"Usage: /version <nick>"));
	}

	who = [array objectAtIndex: 0];
	
	[_TS_ sendCTCPRequest: S2AS(@"VERSION") withArgument: nil
	  to: S2AS(who) onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandClientinfo: (NSString *)command connection: connection
{
	id array;
	id who;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 2];

	if ([array count] == 0)
	{
		return S2AS(_(@"Usage: /clientinfo <nick>"));
	}

	who = [array objectAtIndex: 0];
	
	[_TS_ sendCTCPRequest: S2AS(@"CLIENTINFO") withArgument: nil
	  to: S2AS(who) onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandUserinfo: (NSString *)command connection: connection
{
	id array;
	id who;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 2];

	if ([array count] == 0)
	{
		return S2AS(_(@"Usage: /userinfo <nick>"));
	}

	who = [array objectAtIndex: 0];
	
	[_TS_ sendCTCPRequest: S2AS(@"USERINFO") withArgument: nil
	  to: S2AS(who) onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandPing: (NSString *)command connection: connection
{
	id array;
	id who;
	id arg = nil;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 2];

	if ([array count] <= 1)
	{
		return S2AS(_(@"Usage: /ping <nick> <argument>"));
	}

	who = [array objectAtIndex: 0];
	arg = [array objectAtIndex: 1];
	
	[_TS_ sendCTCPRequest: S2AS(@"PING") withArgument: S2AS(arg)
	  to: S2AS(who) onConnection: connection withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandTopic: (NSString *)command connection: connection
{
	id array;
	id who;
	id arg = nil;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 2];

	if ([array count] < 1)
	{
		return S2AS(_(@"Usage: /topic <channel> [topic]"));
	}

	who = [array objectAtIndex: 0];
	
	if ([array count] > 1)
	{
		arg = [array objectAtIndex: 1];
	}
	
	[_TS_ setTopicForChannel: S2AS(who) to: S2AS(arg)
	  onConnection: connection withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandKick: (NSString *)command connection: connection
{
	id array;
	id who;
	id arg = nil;
	id chan;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 3];

	if ([array count] <= 1)
	{
		return S2AS(_(@"Usage: /kick <channel> <user> [comment]"));
	}

	who = [array objectAtIndex: 1];
	chan = [array objectAtIndex: 0];
	if ([array count] > 2)
	{
		arg = [array objectAtIndex: 2];
	}
	
	[_TS_ kick: S2AS(who) offOf: S2AS(chan) for: S2AS(arg)
	  onConnection: connection withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandRaw: (NSString *)command connection: connection
{
	id array;
	id arg = nil;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 1];

	if ([array count] == 0)
	{
		return S2AS(_(@"Usage: /raw <message>"));
	}

	arg = [array objectAtIndex: 0];
	
	[_TS_ writeRawString: S2AS(arg)
	  onConnection: connection withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandMode: (NSString *)command connection: connection
{
	id array;
	id mode;
	id arg = AUTORELEASE([NSMutableArray new]);
	id obj;
	int ind, max;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: -1];

	max = [array count];
	
	if (max <= 1)
	{
		return S2AS(_(@"Usage: /mode <object> <mode(s)> [arguments]"));
	}

	mode = [array objectAtIndex: 1];
	obj = [array objectAtIndex: 0];
	
	for (ind = 2; ind < max; ind++)
	{
		[arg addObject: S2AS([array objectAtIndex: ind])];
	}
	
	[_TS_ setMode: S2AS(mode) on: S2AS(obj) withParams: arg
	  onConnection: connection withNickname: S2AS([connection nick])
	  sender: output];
	
	return nil;
}
- (NSAttributedString *)commandEncoding: (NSString *)command connection: connection
{
	id array;
	id arg = nil;
	NSStringEncoding enc = 0;
	id temp;
	
	if (!connection) return NO_CONNECT;
	
	array = [command separateIntoNumberOfArguments: 2];
	
	if ([array count] > 0)
	{
		arg = [array objectAtIndex: 0];
		arg = [arg lowercaseString];
	}
	
	if (arg) enc = (NSStringEncoding)NSMapGet(encodings, arg);
	
	if (!enc)
	{
		temp = NSAllMapTableKeys(encodings);
		return BuildAttributedString(_(@"Usage: /encoding <encoding>"), @"\n", 
		  _(@"Available encodings: "), [temp componentsJoinedByString: @", "], @"\n",
		  _(@"Current encoding: "), StringFromEncoding([connection encoding]), nil);
	}
	
	[connection setEncoding: enc];
	
	return S2AS(_(@"Ok."));
}
- (void)setupCommandList
{
#define ADD_COMMAND(_sel, _name) { id invoc; \
	invoc = [NSInvocation invocationWithMethodSignature: \
	  [self methodSignatureForSelector: \
	  (_sel)]]; \
	[invoc retainArguments];\
	[invoc setSelector: (_sel)];\
	[invoc setTarget: self];\
	[self addCommand: (_name) withInvocation: invoc];}

	ADD_COMMAND(@selector(commandLoad:connection:), @"load");
	ADD_COMMAND(@selector(commandUnload:connection:), @"unload");
	ADD_COMMAND(@selector(commandLoaded:connection:), @"loaded");
	ADD_COMMAND(@selector(commandSaveLoaded:connection:), @"saveloaded");
	ADD_COMMAND(@selector(commandJoin:connection:), @"join");
	ADD_COMMAND(@selector(commandMsg:connection:), @"msg");
	ADD_COMMAND(@selector(commandPart:connection:), @"part");
	ADD_COMMAND(@selector(commandNotice:connection:), @"notice");
	ADD_COMMAND(@selector(commandAway:connection:), @"away");
	ADD_COMMAND(@selector(commandQuit:connection:), @"quit");
	ADD_COMMAND(@selector(commandColors:connection:), @"colors");
	ADD_COMMAND(@selector(commandCtcp:connection:), @"ctcp");
	ADD_COMMAND(@selector(commandVersion:connection:), @"version");
	ADD_COMMAND(@selector(commandClientinfo:connection:), @"clientinfo");
	ADD_COMMAND(@selector(commandUserinfo:connection:), @"userinfo");
	ADD_COMMAND(@selector(commandPing:connection:), @"ping");
	ADD_COMMAND(@selector(commandTopic:connection:), @"topic");
	ADD_COMMAND(@selector(commandKick:connection:), @"kick");
	ADD_COMMAND(@selector(commandRaw:connection:), @"raw");
	ADD_COMMAND(@selector(commandMode:connection:), @"mode");
	ADD_COMMAND(@selector(commandEncoding:connection:), @"encoding");
	
#undef ADD_COMMAND
}
@end

#undef MARK
