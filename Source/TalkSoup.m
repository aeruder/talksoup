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

NSString *IRCDefaultsNick =  @"Nick";
NSString *IRCDefaultsRealName = @"RealName";
NSString *IRCDefaultsUserName = @"UserName";
NSString *IRCDefaultsPassword = @"Password";

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

	outFilters = [NSMutableArray new];
	inFilters = [NSMutableArray new];
	commandList = [NSMutableDictionary new];

	_TS_ = RETAIN(self);
	
	return self;
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

	[in addObjectsFromArray: inFilters];
	[out addObjectsFromArray: outFilters];

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
				[aInvocation setArgument: &next atIndex: args - 1];
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
				[aInvocation setArgument: &next atIndex: args - 1];
				[self forwardInvocation: aInvocation];
			}
		}
	}
}
- (id)input
{
	return input;
}
- (NSMutableArray *)inFilters
{
	return inFilters;
}
- (NSMutableArray *)outFilters
{
	return outFilters;
}
- (id)output
{
	return output;
}
- setInput: (id)aInput
{
	RELEASE(input);
	input = RETAIN(aInput);

	return self;
}
- setOutput: (id)aOutput
{
	RELEASE(output);
	output = RETAIN(aOutput);
	
	return self;
}
@end
