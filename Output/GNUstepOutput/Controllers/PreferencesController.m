/***************************************************************************
                                PreferencesController.m
                          -------------------
    begin                : Thu Apr  3 08:09:15 CST 2003
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


#include "Controllers/PreferencesController.h"
#include "Controllers/ConnectionController.h"
#include "Controllers/ContentController.h"
#include "Controllers/QueryController.h"
#include "Misc/NSColorAdditions.h"
#include "GNUstepOutput.h"
#include "TalkSoupBundles/TalkSoup.h"

#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSColorWell.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSView.h>

@implementation PreferencesController
- (void)awakeFromNib
{
	[nick setNextKeyView: realName];
	[realName setNextKeyView: password];
	[password setNextKeyView: userName];
	[userName setNextKeyView: nick];
}
- (void)dealloc
{
	[nick setTarget: nil];
	[nick setDelegate: nil];
	[realName setTarget: nil];
	[realName setDelegate: nil];
	[password setTarget: nil];
	[password setDelegate: nil];
	[userName setTarget: nil];
	[userName setDelegate: nil];
	RELEASE(personalBracketColor);
	RELEASE(backgroundColor);
	RELEASE(otherBracketColor);
	RELEASE(textColor);
	RELEASE(nick);
	RELEASE(realName);
	RELEASE(userName);
	RELEASE(password);
	RELEASE(resetButton);
	RELEASE(window);
	[super dealloc];
}
- (void)loadCurrentDefaults
{	
	id output = [_TS_ pluginForOutput];
	id y;
	
	y = [NSColor colorFromEncodedData: 
	  [output defaultsObjectForKey: GNUstepOutputPersonalBracketColor]];
	[personalBracketColor setColor: y];
	[self personalBracketColorSet: personalBracketColor];
	 
	y = [NSColor colorFromEncodedData: 
	  [output defaultsObjectForKey: GNUstepOutputOtherBracketColor]];
	[otherBracketColor setColor: y];
	[self otherBracketColorSet: otherBracketColor];

	y = [NSColor colorFromEncodedData: 
	  [output defaultsObjectForKey: GNUstepOutputBackgroundColor]];
	[backgroundColor setColor: y];
	[self backgroundColorSet: backgroundColor];
	 
	y = [NSColor colorFromEncodedData: 
	  [output defaultsObjectForKey: GNUstepOutputTextColor]];
	[textColor setColor: y];
	[self textColorSet: textColor];
	 
	y = [output defaultsObjectForKey: IRCDefaultsNick];
	[nick setStringValue: y];
	[self nickSet: nick];
	[nick setDelegate: self];
	
	y = [output defaultsObjectForKey: IRCDefaultsRealName];
	[realName setStringValue: y];
	[self realNameSet: realName];
	[realName setDelegate: self];
	
	y = [output defaultsObjectForKey: IRCDefaultsUserName];
	[userName setStringValue: y];
	[self userNameSet: userName];
	[userName setDelegate: self];
	
	y = [output defaultsObjectForKey: IRCDefaultsPassword];
	[password setStringValue: y];
	[self passwordSet: password];
	[password setDelegate: self];
}
- nickSet: (NSTextField *)sender
{
	id array = [[sender stringValue] separateIntoNumberOfArguments: 2];
	
	if ([array count] != 0)
	{
		[[_TS_ pluginForOutput] setDefaultsObject: [array objectAtIndex: 0] forKey:
		  IRCDefaultsNick];
	}
	  	
	return self;
}
- passwordSet: (NSTextField *)sender
{
	id array = [[sender stringValue] separateIntoNumberOfArguments: 2];
	
	if ([array count] != 0)
	{
		[[_TS_ pluginForOutput] setDefaultsObject: [array objectAtIndex: 0] forKey:
		  IRCDefaultsPassword];
	}
	
	return self;
}
- userNameSet: (NSTextField *)sender
{
	id array = [[sender stringValue] separateIntoNumberOfArguments: 2];
	
	if ([array count] != 0)
	{
		[[_TS_ pluginForOutput] setDefaultsObject: [array objectAtIndex: 0] forKey:
		  IRCDefaultsUserName];
	}
	
	return self;
}
- realNameSet: (NSTextField *)sender
{
	id array = [[sender stringValue] separateIntoNumberOfArguments: 1];

	if ([array count] != 0)
	{
		[[_TS_ pluginForOutput] setDefaultsObject: [array objectAtIndex: 0] forKey:
		  IRCDefaultsRealName];
	}
	
	return self;
}
- personalBracketColorSet: (NSColorWell *)sender
{
	NSEnumerator *iter;
	id object;
	id color = GNUstepOutputColor([sender color]);

	[[_TS_ pluginForOutput] setDefaultsObject: [color encodeToData] forKey:
	  GNUstepOutputPersonalBracketColor];
		
	iter = [[[_TS_ pluginForOutput] connectionControllers] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[object setPersonalColor: color];
	}
	
	return self;
}
- backgroundColorSet: (NSColorWell *)sender
{
	NSEnumerator *iter;
	id object;
	NSEnumerator *iter2;
	id object2;
	id color = GNUstepOutputColor([sender color]);
	
	[[_TS_ pluginForOutput] setDefaultsObject: [color encodeToData] forKey:
	  GNUstepOutputBackgroundColor];
			
	iter = [[[_TS_ pluginForOutput] connectionControllers] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		iter2 = [[[object contentController] allViews] objectEnumerator];
		
		while ((object2 = [iter2 nextObject]))
		{
			[[object2 chatView] setBackgroundColor: color];
		}
	}

	return self;
}
- otherBracketColorSet: (NSColorWell *)sender
{
	NSEnumerator *iter;
	id object;
	id color = GNUstepOutputColor([sender color]);
	
	[[_TS_ pluginForOutput] setDefaultsObject: [color encodeToData] forKey:
	  GNUstepOutputOtherBracketColor];
		
	iter = [[[_TS_ pluginForOutput] connectionControllers] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[object setOtherColor: color];
	}
	
	return self;
}
- textColorSet: (NSColorWell *)sender
{
	NSEnumerator *iter;
	id object;
	id color = GNUstepOutputColor([sender color]);
	
	[[_TS_ pluginForOutput] setDefaultsObject: [color encodeToData] forKey:
	  GNUstepOutputTextColor];
	
	iter = [[[_TS_ pluginForOutput] connectionControllers] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[[object contentController] setTextColor: color];
	}

	return self;
}
- resetColors: (NSButton *)sender
{
	id output = [_TS_ pluginForOutput];
	id y;
	
	y = [NSColor colorFromEncodedData: 
	  [output defaultDefaultsForKey: GNUstepOutputPersonalBracketColor]];
	[personalBracketColor setColor: y];
	[self personalBracketColorSet: personalBracketColor];
	 
	y = [NSColor colorFromEncodedData: 
	  [output defaultDefaultsForKey: GNUstepOutputOtherBracketColor]];
	[otherBracketColor setColor: y];
	[self otherBracketColorSet: otherBracketColor];

	y = [NSColor colorFromEncodedData: 
	  [output defaultDefaultsForKey: GNUstepOutputBackgroundColor]];
	[backgroundColor setColor: y];
	[self backgroundColorSet: backgroundColor];
	 
	y = [NSColor colorFromEncodedData: 
	  [output defaultDefaultsForKey: GNUstepOutputTextColor]];
	[textColor setColor: y];
	[self textColorSet: textColor];

	return self;
}
- (NSWindow *)window
{
	return window;
}
- (void)controlTextDidChange: (NSNotification *)aNotification
{
	id obj;
	
	obj = [aNotification object];
	
	if (obj == realName)
	{
		[self realNameSet: realName];
	}
	else if (obj == userName)
	{
		[self userNameSet: userName];
	}
	else if (obj == password)
	{
		[self passwordSet: password];
	}
	else if (obj == nick)
	{
		[self nickSet: nick];
	}
}

@end


