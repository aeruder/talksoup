/***************************************************************************
                                ServerListConnectionController.m
                          -------------------
    begin                : Wed May  7 03:31:51 CDT 2003
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

#include "Controllers/ServerListConnectionController.h"
#include "Controllers/ServerListController.h"
#include "Controllers/InputController.h"
#include "Controllers/ContentController.h"
#include "TalkSoupBundles/TalkSoup.h"
#include "GNUstepOutput.h"

#include <Foundation/NSEnumerator.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSInvocation.h>

#include <AppKit/NSWindow.h>
#include <AppKit/NSView.h>

@implementation ServerListConnectionController
- initWithServerListDictionary: (NSDictionary *)aInfo
 inGroup: (int)group atRow: (int)row
{
	id tmp;
	id output = _GS_;
	
	tmp = [NSMutableDictionary dictionaryWithDictionary: aInfo];
	if ([[tmp objectForKey: IRCDefaultsNick] length] == 0)
	{
		[tmp setObject: [output defaultsObjectForKey: IRCDefaultsNick]
		  forKey: IRCDefaultsNick];
	}
	if ([[tmp objectForKey: IRCDefaultsUserName] length] == 0)
	{
		[tmp setObject: [output defaultsObjectForKey: IRCDefaultsUserName]
		  forKey: IRCDefaultsUserName];
	}
	if ([[tmp objectForKey: IRCDefaultsRealName] length] == 0)
	{
		[tmp setObject: [output defaultsObjectForKey: IRCDefaultsRealName]
		  forKey: IRCDefaultsRealName];
	}
	if ([[tmp objectForKey: IRCDefaultsPassword] length] == 0)
	{
		[tmp setObject: [output defaultsObjectForKey: IRCDefaultsPassword]
		  forKey: IRCDefaultsPassword];
	}
	
	if (!(self = [super initWithIRCInfoDictionary: tmp])) return nil;
	
	oldInfo = RETAIN(aInfo);
	newInfo = [[NSMutableDictionary alloc] initWithDictionary: aInfo];
	
	serverRow = row;
	serverGroup = group;

	if ((tmp = [aInfo objectForKey: ServerListInfoWindowFrame]))
	{
		NSRect a = NSRectFromString(tmp);
		
		[[[self contentController] window] setFrame: a display: YES];
	}
	
	if ((tmp = [aInfo objectForKey: ServerListInfoServer]))
	{
		int port = [[aInfo objectForKey: ServerListInfoPort] intValue];
		
		[self connectToServer: tmp onPort: port];
	}
	
	return self;
}	
- newConnection: (id)aConnection withNickname: (NSAttributedString *)aNick
   sender: aPlugin
{
	id tmp, invoc;
	
	if ((tmp = [newInfo objectForKey: ServerListInfoEncoding]))
	{
		invoc = [_TS_ invocationForCommand: @"encoding"];
		[invoc setArgument: &tmp atIndex: 2];
		[invoc setArgument: &aConnection atIndex: 3]; 
		[invoc invoke];
		tmp = nil;
		[invoc setArgument: &tmp atIndex: 2];
		[invoc setArgument: &tmp atIndex: 3];
	}		
	
	[super newConnection: aConnection withNickname: aNick sender: aPlugin];
	
	return self;
}
- lostConnection: (id)aConnection withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id tmp = StringFromEncoding([aConnection encoding]);
	
	[newInfo setObject: tmp forKey: ServerListInfoEncoding];
	
	[super lostConnection: aConnection withNickname: aNick
	  sender: aPlugin];
	
	return self;
}
- (void)dealloc
{	
	RELEASE(newInfo);
	RELEASE(oldInfo);

	[super dealloc];
}
- registeredWithServerOnConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick
	sender: aPlugin
{
	id tmp;
	
	if ([tmp = [newInfo objectForKey: ServerListInfoCommands] length] > 0)
	{
		[[self inputController] lineTyped: tmp];
	}

	return [super registeredWithServerOnConnection: aConnection 
	  withNickname: aNick sender: aPlugin];
}
- (void)windowWillClose: (NSNotification *)aNotification
{	
	id window = [content window];
	
	[newInfo setObject: NSStringFromRect([window frame]) 
	  forKey: ServerListInfoWindowFrame];
	
	if (connection)
	{
		[newInfo setObject: StringFromEncoding([connection encoding]) 
		  forKey: ServerListInfoEncoding];
	}
	
	if ([[ServerListController serverInGroup: serverGroup row: serverRow] 
	  isEqual: oldInfo])
	{
		[ServerListController setServer: newInfo inGroup: serverGroup
		  row: serverRow];
	}

	[super windowWillClose: aNotification];	  
}
@end

