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

#import "MessageInTab.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSNull.h>

@implementation MessageInTab
- (NSAttributedString *)pluginDescription
{
	return BuildAttributedString([NSNull null], IRCBold, IRCBoldValue,
	 @"Author: ", @"Andrew Ruder\n\n",
	 [NSNull null], IRCBold, IRCBoldValue,
	 @"Description: ", @"This bundle will open a new tab for "
	 @"any incoming private messages."
	 @"\n\n",
	 @"Copyright (C) 2003 by Andrew Ruder",
	 nil);
}
- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick
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
		  S2AS(name), @"TabLabel", nil] onConnection: connection
		  withNickname: aNick
		  sender: aPlugin];
	}

	[_TS_ messageReceived: aMessage to: to from: sender onConnection: connection
	  withNickname: aNick
	  sender: self];
	return self;
}
- actionReceived: (NSAttributedString *)anAction to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick
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
		  onConnection: connection withNickname: aNick sender: aPlugin];
	}

	[_TS_ actionReceived: anAction to: to from: sender onConnection: connection
	  withNickname: aNick
	  sender: self];
	return self;
}
@end

