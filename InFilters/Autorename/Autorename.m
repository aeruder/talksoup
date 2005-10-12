/***************************************************************************
                              Autorename.m
                          -------------------
    begin                : Wed Oct 12 02:53:26 CDT 2005
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

#import "Autorename.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSBundle.h>

@implementation Autorename 
- (NSAttributedString *)pluginDescription
{
	return BuildAttributedString([NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Author: "), @"Andrew Ruder",
	 [NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Description: "), _l(@"When a nick is already taken on connect, "
	 @"this plugin will tell TalkSoup to repeatedly try adding a '_' "
	 @"until we get a nick."),
	 nil);
}
@end

