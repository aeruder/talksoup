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

#import "Controllers/ConnectionController.h"
#import "Controllers/ContentControllers/ContentController.h"
#import "Controllers/Preferences/ColorPreferencesController.h"
#import <TalkSoupBundles/TalkSoup.h>
#import "Misc/NSAttributedStringAdditions.h"
#import "GNUstepOutput.h"

#import <AppKit/NSAttributedString.h>
#import <Foundation/NSNull.h>

#define MARK [NSNull null]

@implementation ConnectionController (OutFilter)
- sendMessage: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick
   sender: aPlugin
{
	id where = [receiver string];
	
	if (![content controllerForName: where])
	{
		[content putMessage: BuildAttributedString(
		  MARK, TypeOfColor, GNUstepOutputPersonalBracketColor, @">", 
		  receiver, 
		  MARK, TypeOfColor, GNUstepOutputPersonalBracketColor, @"<", 
		  @" ", message, nil) in: nil];
	}
	else
	{
		[content putMessage: BuildAttributedString(
		  MARK, TypeOfColor, GNUstepOutputPersonalBracketColor, @"<", 
		  aNick, MARK, TypeOfColor, GNUstepOutputPersonalBracketColor, @">", 
		  @" ", message, nil) in: where];
	}
	
	return self;
}
- sendNotice: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick
   sender: aPlugin
{
	[self sendMessage: message to: receiver onConnection: aConnection 
	  withNickname: aNick sender: aPlugin];
	return self;
}
- sendAction: (NSAttributedString *)anAction to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick
   sender: aPlugin
{
	id where = [receiver string];
	
	if (![content controllerForName: where])
	{
		[content putMessage: BuildAttributedString(
		  MARK, TypeOfColor, GNUstepOutputPersonalBracketColor, @">", 
		  receiver, MARK, TypeOfColor, GNUstepOutputPersonalBracketColor, @"<", 
		  MARK, TypeOfColor, GNUstepOutputPersonalBracketColor, 
		  @" * ", aNick, @" ", anAction, nil) in: nil];
	}
	else
	{
		[content putMessage: BuildAttributedString(
		  MARK, TypeOfColor, GNUstepOutputPersonalBracketColor, @"* ", 
		  aNick, @" ", anAction, nil) in: where];
	}
	
	return self;
}
@end

#undef MARK
#undef FCAN
