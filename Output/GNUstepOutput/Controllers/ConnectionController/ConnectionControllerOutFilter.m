/***************************************************************************
                                ConnectionControllerOutFilter.m
                          -------------------
    begin                : Tue May 20 18:38:20 CDT 2003
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

#include "Controllers/ConnectionController.h"
#include "Controllers/ContentController.h"
#include "TalkSoupBundles/TalkSoup.h"

#include <AppKit/NSAttributedString.h>
#include <Foundation/NSNull.h>

#define FCAN NSForegroundColorAttributeName
#define MARK [NSNull null]

@implementation ConnectionController (OutFilter)
- sendMessage: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection sender: aPlugin
{
	id who = [connection nick];
	id where = [receiver string];
	
	if (![content controllerForViewWithName: where])
	{
		[content putMessage: BuildAttributedString(
		  MARK, FCAN, personalColor, @">", 
		  receiver, MARK, FCAN, personalColor, @"<", 
		  @" ", message, nil) in: nil];
	}
	else
	{
		[content putMessage: BuildAttributedString(
		  MARK, FCAN, personalColor, @"<", 
		  who, MARK, FCAN, personalColor, @">", 
		  @" ", message, nil) in: where];
	}
	
	return self;
}
- sendNotice: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection sender: aPlugin
{
	[self sendMessage: message to: receiver onConnection: aConnection sender: aPlugin];
	return self;
}
- sendAction: (NSAttributedString *)anAction to: (NSAttributedString *)receiver 
   onConnection: aConnection sender: aPlugin
{
	id who = [aConnection nick];
	id where = [receiver string];
	
	if (![content controllerForViewWithName: where])
	{
		[content putMessage: BuildAttributedString(
		  MARK, FCAN, personalColor, @">", 
		  receiver, MARK, FCAN, personalColor, @"<", 
		  MARK, FCAN, personalColor, @" * ", who, @" ", anAction, nil) in: nil];
	}
	else
	{
		[content putMessage: BuildAttributedString(
		  MARK, FCAN, personalColor, @"* ", 
		  who, @" ", anAction, nil) in: where];
	}
	
	return self;
}
@end

#undef MARK
#undef FCAN
