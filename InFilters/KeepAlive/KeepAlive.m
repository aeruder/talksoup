/***************************************************************************
                              KeepAlive.m
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

#include "KeepAlive.h"
#include "TalkSoupBundles/TalkSoup.h"

#include <Foundation/NSAttributedString.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSTimer.h>
#include <Foundation/NSNull.h>

@implementation KeepAlive
- fireTimer: (NSTimer *)aTimer
{
	NSEnumerator *iter;
	id object;

	iter = [[[_TS_ pluginForInput] connections] objectEnumerator];

	while ((object = [iter nextObject]))
	{
		[_TS_ sendPingWithArgument: S2AS(@"KeepAlive") onConnection:
		  object withNickname: S2AS([object nick]) 
		  sender: [_TS_ pluginForOutput]];
	}

	return self;
}
- (NSAttributedString *)pluginDescription
{
	return BuildAttributedString([NSNull null], IRCBold, IRCBoldValue,
	 @"Author: ", @"Andrew Ruder\n\n",
	 [NSNull null], IRCBold, IRCBoldValue,
	 @"Description:", @"A simple bundle that will send a ping to "
	 @"all connected servers every 3 minutes.  This can be used "
	 @"to stay connected on flaky connections."
	 @"\n\n",
	 @"Copyright (C) 2003 by Andrew Ruder",
	 nil);
}
- pluginActivated
{
	timer = [NSTimer scheduledTimerWithTimeInterval: 180.0
	  target: self selector: @selector(fireTimer:) userInfo: nil
	  repeats: YES];
	return self;
}
- pluginDeactivated
{
	[timer invalidate];
	DESTROY(timer);
	return self;
}
@end

