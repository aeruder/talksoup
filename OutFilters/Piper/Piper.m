/***************************************************************************
                              Piper.m
                          -------------------
    begin                : Sat May 10 18:58:30 CDT 2003
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

#include "Piper.h"
#include "TalkSoupBundles/TalkSoup.h"

#include <Foundation/NSAttributedString.h>
#include <Foundation/NSNull.h>
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSScanner.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSFileHandle.h>
#include <Foundation/NSTask.h>
#include <Foundation/NSString.h>
#include <Foundation/NSInvocation.h>

static NSAttributedString *pipeit(NSAttributedString *a)
{
	id piper = [[NSUserDefaults standardUserDefaults] objectForKey: @"Piper"];
	NSEnumerator *iter;
	id object;
	id task;
	id pipein;
	id pipeout;
	id fdin;
	id fdout;
	id newData;
	id str;
	
	if (!piper || ![piper isKindOf: [NSArray class]]) return a;
	
	str = [a string];
	iter = [piper objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		if ([object length] == 0) continue;

		object = [object separateIntoNumberOfArguments: -1];
			
		if ([object count] == 0) continue;
		
		task = AUTORELEASE([NSTask new]);
		pipein = [NSPipe pipe];
		pipeout = [NSPipe pipe];
		
		[task setStandardInput: pipein];
		[task setStandardOutput: pipeout];
		
		fdin = [pipein fileHandleForWriting];
		fdout = [pipeout fileHandleForReading];
				
		[task setLaunchPath: [object objectAtIndex: 0]];
		if ([object count] > 0)
		{
			[task setArguments: 
			  [object subarrayWithRange: NSMakeRange(1, [object count] - 1)]];
		}
		[task launch];
		[fdin writeData: [str dataUsingEncoding: NSUTF8StringEncoding]];
		
		[fdin closeFile];
		newData = [fdout readDataToEndOfFile];
		
		str = AUTORELEASE([[NSMutableString alloc] initWithData: newData 
		  encoding: NSUTF8StringEncoding]);
		
		[task terminate];
		
		if (!str) return a;

		[str replaceOccurrencesOfString: @"\r\n" withString: @" " options: 0
		  range: NSMakeRange(0, [str length])];
		[str replaceOccurrencesOfString: @"\r" withString: @" " options: 0
		  range: NSMakeRange(0, [str length])];
		[str replaceOccurrencesOfString: @"\n" withString: @" " options: 0
		  range: NSMakeRange(0, [str length])];
	}
	
	return AUTORELEASE([[NSAttributedString alloc] initWithString: str]);
}

NSInvocation *invoc = nil;

@implementation Piper
+ (void)initialize
{
	invoc = RETAIN([NSInvocation invocationWithMethodSignature: 
	  [self methodSignatureForSelector: @selector(commandPiper:connection:)]]);
	[invoc retainArguments];
	[invoc setTarget: self];
	[invoc setSelector: @selector(commandPiper:connection:)];
}
+ (NSAttributedString *)commandPiper: (NSString *)command connection: aConnection
{
	id x = [command separateIntoNumberOfArguments: 1];
	
	if ([x count] == 0)
	{
		return BuildAttributedString(@"Usage: /piper <commands>", @"\n",
		  @"<commands> is a list of commands separated by the '^' character", 
		  @" to pipe outgoing messages through.", nil);
	}
	
	x = [NSMutableArray arrayWithArray: 
	  [[x objectAtIndex: 0] componentsSeparatedByString: @"^"]];
	[x removeObject: @""];
	
	[[NSUserDefaults standardUserDefaults] setObject: x forKey: @"Piper"];
	
	return S2AS(@"Ok.");
}
- pluginActivated
{
	[_TS_ addCommand: @"piper" withInvocation: invoc];
	return self;
}
- pluginDeactivated
{
	[_TS_ removeCommand: @"piper"];
	return self;
}
- quitWithMessage: (NSAttributedString *)aMessage onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ quitWithMessage: pipeit(aMessage) onConnection: aConnection
	  withNickname: aNick sender: self];
	return self;
}
- partChannel: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
	sender: aPlugin
{
	[_TS_ partChannel: channel withMessage: pipeit(aMessage)
	  onConnection: aConnection withNickname: aNick
	  sender: self];
	return self;
}
- sendCTCPReply: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)args
   to: (NSAttributedString *)aPerson 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendCTCPReply: aCTCP withArgument: pipeit(args)
	 to: aPerson onConnection: aConnection withNickname: aNick
	 sender: self];
	return self;
}
- sendCTCPRequest: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)args
   to: (NSAttributedString *)aPerson onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
	sender: aPlugin
{
	[_TS_ sendCTCPRequest: aCTCP
	  withArgument: pipeit(args) to: aPerson
	  onConnection: aConnection
	  withNickname: aNick
	  sender: self];
	return self;
} 
- sendMessage: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick    
	sender: aPlugin
{
	[_TS_ sendMessage: pipeit(message) to: receiver
	  onConnection: aConnection withNickname: aNick
	  sender: self];
	return self;
}
- sendNotice: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
	sender: aPlugin
{
	[_TS_ sendNotice: pipeit(message) to: receiver
	 onConnection: aConnection withNickname: aNick
	 sender: self];
	return self;
}
- sendAction: (NSAttributedString *)anAction to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
	sender: aPlugin
{
	[_TS_ sendAction: pipeit(anAction) to: receiver
	 onConnection: aConnection
	 withNickname: aNick
	 sender: self];
	return self;
}
- sendWallops: (NSAttributedString *)message onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendWallops: pipeit(message) onConnection: aConnection
	  withNickname: aNick sender: self];
	return self;
}
- setTopicForChannel: (NSAttributedString *)aChannel 
   to: (NSAttributedString *)aTopic 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ setTopicForChannel: aChannel to: pipeit(aTopic) onConnection: aConnection
	  withNickname: aNick sender: self];
	return self;
}
- kick: (NSAttributedString *)aPerson offOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ kick: aPerson offOf: aChannel for: pipeit(reason) onConnection: aConnection
	  withNickname: aNick sender: self];
	return self;
}
- setAwayWithMessage: (NSAttributedString *)message onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ setAwayWithMessage: pipeit(message) onConnection: aConnection
	  withNickname: aNick sender: self];
	return self;
}
@end


