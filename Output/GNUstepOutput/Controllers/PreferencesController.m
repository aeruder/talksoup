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
#include "Views/ScrollingTextView.h"

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
#include <AppKit/NSFontPanel.h>
#include <AppKit/NSFontManager.h>
#include <AppKit/NSFont.h>

@implementation PreferencesController
- (void)awakeFromNib
{
	[nick setNextKeyView: realName];
	[realName setNextKeyView: password];
	[password setNextKeyView: userName];
	[userName setNextKeyView: nick];
	[window makeKeyAndOrderFront: nil];
	[window makeFirstResponder: nick];
	[window setDelegate: self];
	[_GS_ setPreferencesController: self];
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
	[window setDelegate: nil];
	[setFontButton setTarget: nil];
	[resetButton setTarget: nil];
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
	RELEASE(fontField);
	RELEASE(setFontButton);
	[super dealloc];
}
- (void)loadCurrentDefaults
{	
	id y;
	
	y = [NSColor colorFromEncodedData: 
	  [_GS_ defaultsObjectForKey: GNUstepOutputPersonalBracketColor]];
	[personalBracketColor setColor: y];
	[self personalBracketColorSet: personalBracketColor];
	 
	y = [NSColor colorFromEncodedData: 
	  [_GS_ defaultsObjectForKey: GNUstepOutputOtherBracketColor]];
	[otherBracketColor setColor: y];
	[self otherBracketColorSet: otherBracketColor];

	y = [NSColor colorFromEncodedData: 
	  [_GS_ defaultsObjectForKey: GNUstepOutputBackgroundColor]];
	[backgroundColor setColor: y];
	[self backgroundColorSet: backgroundColor];
	 
	y = [NSColor colorFromEncodedData: 
	  [_GS_ defaultsObjectForKey: GNUstepOutputTextColor]];
	[textColor setColor: y];
	[self textColorSet: textColor];
	 
	y = [_GS_ defaultsObjectForKey: IRCDefaultsNick];
	[nick setStringValue: y];
	[self nickSet: nick];
	[nick setDelegate: self];
	
	y = [_GS_ defaultsObjectForKey: IRCDefaultsRealName];
	[realName setStringValue: y];
	[self realNameSet: realName];
	[realName setDelegate: self];
	
	y = [_GS_ defaultsObjectForKey: IRCDefaultsUserName];
	[userName setStringValue: y];
	[self userNameSet: userName];
	[userName setDelegate: self];
	
	y = [_GS_ defaultsObjectForKey: IRCDefaultsPassword];
	[password setStringValue: y];
	[self passwordSet: password];
	[password setDelegate: self];
	
	[fontField setStringValue: [NSString stringWithFormat: @"%@ %@",
	  [_GS_ defaultsObjectForKey: GNUstepOutputFontName],
	  [_GS_ defaultsObjectForKey: GNUstepOutputFontSize]]];
}
- nickSet: (NSTextField *)sender
{
	id array = [[sender stringValue] separateIntoNumberOfArguments: 2];
	
	if ([array count] != 0)
	{
		[_GS_ setDefaultsObject: [array objectAtIndex: 0] forKey:
		  IRCDefaultsNick];
	}
	else
	{
		[_GS_ setDefaultsObject: nil forKey: IRCDefaultsNick];
	}
	  	
	return self;
}
- passwordSet: (NSTextField *)sender
{
	id array = [[sender stringValue] separateIntoNumberOfArguments: 2];
	
	if ([array count] != 0)
	{
		[_GS_ setDefaultsObject: [array objectAtIndex: 0] forKey:
		  IRCDefaultsPassword];
	}
	else
	{
		[_GS_ setDefaultsObject: nil forKey: IRCDefaultsPassword];
	}
	
	return self;
}
- userNameSet: (NSTextField *)sender
{
	id array = [[sender stringValue] separateIntoNumberOfArguments: 2];
	
	if ([array count] != 0)
	{
		[_GS_ setDefaultsObject: [array objectAtIndex: 0] forKey:
		  IRCDefaultsUserName];
	}
	else
	{
		[_GS_ setDefaultsObject: nil forKey: IRCDefaultsUserName];
	}
	
	return self;
}
- realNameSet: (NSTextField *)sender
{
	id array = [[sender stringValue] separateIntoNumberOfArguments: 1];

	if ([array count] != 0)
	{
		[_GS_ setDefaultsObject: [array objectAtIndex: 0] forKey:
		  IRCDefaultsRealName];
	}
	else
	{
		[_GS_ setDefaultsObject: nil forKey: IRCDefaultsRealName];
	}
	
	return self;
}
- personalBracketColorSet: (NSColorWell *)sender
{
	NSEnumerator *iter;
	id object;
	id old;

	old = [_GS_ defaultsObjectForKey: GNUstepOutputPersonalBracketColor];		
	[_GS_ setDefaultsObject: [[sender color] encodeToData] forKey:
	  GNUstepOutputPersonalBracketColor];
	
	iter = [[_GS_ connectionControllers] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[[object contentController] updatedColor: GNUstepOutputPersonalBracketColor
		  old: old];
	}
	
	return self;
}
- backgroundColorSet: (NSColorWell *)sender
{
	NSEnumerator *iter;
	id object;
	id old;
	
	old = [_GS_ defaultsObjectForKey: GNUstepOutputBackgroundColor]; 		
	[_GS_ setDefaultsObject: [[sender color] encodeToData] forKey:
	  GNUstepOutputBackgroundColor];
	
	iter = [[_GS_ connectionControllers] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[[object contentController] updatedColor: GNUstepOutputBackgroundColor
		 old: old];
	}

	return self;
}
- otherBracketColorSet: (NSColorWell *)sender
{
	NSEnumerator *iter;
	id object;
	id old;

	old = [_GS_ defaultsObjectForKey: GNUstepOutputOtherBracketColor];
	[_GS_ setDefaultsObject: [[sender color] encodeToData] forKey:
	  GNUstepOutputOtherBracketColor];
	
	iter = [[_GS_ connectionControllers] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[[object contentController] updatedColor: GNUstepOutputOtherBracketColor
		  old: old];
	}
	
	return self;
}
- textColorSet: (NSColorWell *)sender
{
	NSEnumerator *iter;
	id object;
	id old;
	
	old = [_GS_ defaultsObjectForKey: GNUstepOutputTextColor];
	[_GS_ setDefaultsObject: [[sender color] encodeToData] 
	  forKey: GNUstepOutputTextColor];
	
	iter = [[_GS_ connectionControllers] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[[object contentController] updatedColor: GNUstepOutputTextColor
		 old: old];
	}

	return self;
}
- resetColors: (NSButton *)sender
{
	id output = _GS_;
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
- fontSet: (NSButton *)aButton
{
	id font = [NSFont fontWithName: [_GS_ defaultsObjectForKey: GNUstepOutputFontName]
	  size: (float)[[_GS_ defaultsObjectForKey: GNUstepOutputFontSize] intValue]];
	id panel;
	
	panel = [NSFontPanel sharedFontPanel];
	
	[[NSFontManager sharedFontManager] setSelectedFont: font
	  isMultiple: NO];
	  
	[panel orderFront: self];
	
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
- (void)changeFont: (id)sender
{
	NSEnumerator *iter;
	id object;
	NSFont *font;

	font = [NSFont fontWithName: [_GS_ defaultsObjectForKey: GNUstepOutputFontName]
	  size: (float)[[_GS_ defaultsObjectForKey: GNUstepOutputFontSize] intValue]];
	  
	font = [sender convertFont: font];
	
	[_GS_ setDefaultsObject: [font fontName] forKey: GNUstepOutputFontName];
	[_GS_ setDefaultsObject: [NSString stringWithFormat: @"%d", (int)[font pointSize]]
	  forKey: GNUstepOutputFontSize];
	  
	iter = [[_GS_ connectionControllers] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[[object contentController] setChatFont: font];
	}

	[fontField setStringValue: [NSString stringWithFormat: @"%@ %@",
	  [_GS_ defaultsObjectForKey: GNUstepOutputFontName],
	  [_GS_ defaultsObjectForKey: GNUstepOutputFontSize]]];
}
@end

@interface PreferencesController (WindowDelegate)
@end

@implementation PreferencesController (WindowDelegate)
- (void)windowWillClose: (NSNotification *)aNotification
{
	[_GS_ setPreferencesController: nil];
}
@end
