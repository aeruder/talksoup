/***************************************************************************
                                MessageInTab.m
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

#include "MessageInTab.h"
#include "TalkSoupBundles/TalkSoup.h"

#include <Foundation/NSAttributedString.h>

@implementation MessageInTab
- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin
{
	id name;
	
	if ([[[to string] lowercaseString] isEqualToString: [[connection nick]
	  lowercaseString]])
	{
		name = [[IRCUserComponents(sender) objectAtIndex: 0] string];
		[_TS_ controlObject: [NSDictionary dictionaryWithObjectsAndKeys:
		  @"OpenTab", @"Process",
	 	  name, @"TabName",
		  S2AS(name), @"TabName", nil] onConnection: connection
		  sender: aPlugin];
	}

	[_TS_ messageReceived: aMessage to: to from: sender onConnection: connection
	  sender: self];
	return self;
}
- actionReceived: (NSAttributedString *)anAction to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin
{
	id name;
	
	if ([[[to string] lowercaseString] isEqualToString: [[connection nick]
	  lowercaseString]])
	{
		name = [[IRCUserComponents(sender) objectAtIndex: 0] string];
		[_TS_ controlObject: [NSDictionary dictionaryWithObjectsAndKeys:
		  @"OpenTab", @"Process",
	 	  name, @"TabName",
		  S2AS(name), @"TabName", nil]
		  onConnection: connection sender: aPlugin];
	}

	[_TS_ actionReceived: anAction to: to from: sender onConnection: connection
	  sender: self];
	return self;
}
@end

