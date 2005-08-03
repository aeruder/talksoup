/***************************************************************************
                            MessageOutTab.m
                          -------------------
    begin                : Tue Aug  2 23:21:01 CDT 2005
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

#import "MessageOutTab.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDictionary.h>

@implementation MessageOutTab
- (NSAttributedString *)pluginDescription
{
	return BuildAttributedString([NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Author: "), @"Andrew Ruder\n\n",
	 [NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Description: "), _l(@"This bundle will open a new tab for "
	 @"any outgoing private messages."),
	 @"\n\n",
	 _l(@"Copyright (C) 2005 by Andrew Ruder"),
	 nil);
}
- sendMessage: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick    
   sender: aPlugin
{
	[_TS_ controlObject: 
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  @"OpenTab", @"Process",
	  [receiver string], @"TabName", 
	  receiver, @"TabLabel",
	  nil]
	 onConnection: aConnection withNickname: aNick sender: self];
	[_TS_ sendMessage: message to: receiver onConnection: aConnection
	  withNickname: aNick sender: self];
	return self;
}
- sendAction: (NSAttributedString *)anAction to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ controlObject: 
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  @"OpenTab", @"Process",
	  [receiver string], @"TabName", 
	  receiver, @"TabLabel",
	  nil]
	 onConnection: aConnection withNickname: aNick sender: self];
	[_TS_ sendAction: anAction to: receiver onConnection: aConnection
	  withNickname: aNick sender: self];
	return self;
}
@end

