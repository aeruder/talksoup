/***************************************************************************
                      GeneralPreferencesController.m
                          -------------------
    begin                : Sat Aug 14 19:19:31 CDT 2004
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

#import "Controllers/Preferences/GeneralPreferencesController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "GNUstepOutput.h"

#import <TalkSoupBundles/TalkSoup.h>

#import <AppKit/NSImage.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSButton.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDictionary.h>

NSString *GNUstepOutputBufferLines = @"GNUstepOutputBufferLines";
NSString *GNUstepOutputDefaultQuitMessage = @"GNUstepOutputDefaultQuitMessage";
NSString *GNUstepOutputAliases = @"GNUstepOutputAliases";
NSString *GNUstepOutputTimestampFormat = @"GNUstepOutputTimestampFormat";
NSString *GNUstepOutputTimestampEnabled = @"GNUstepOutputTimestampEnabled";

@interface GeneralPreferencesController (PrivateMethods)
- (void)preferenceChanged: (NSNotification *)aNotification;
- (void)refreshFromPreferences;
@end

@implementation GeneralPreferencesController
+ (BOOL)timestampEnabled
{
	id val;

	val = [_PREFS_ preferenceForKey: GNUstepOutputTimestampEnabled];

	if ([val isEqualToString: @"YES"])
	{
		return YES;
	}

	return NO;
}
- init
{
	id path;
	if (!(self = [super init])) return nil;

	if (!([NSBundle loadNibNamed: @"GeneralPreferences" owner: self]))
	{
		NSLog(@"Couldn't load GeneralPreferences nib");
		[self dealloc];
		return nil;
	}

	path = [[NSBundle bundleForClass: [GNUstepOutput class]] 
	  pathForResource: @"general_prefs" ofType: @"tiff"];
	if (!path) 
	{
		NSLog(@"Could not find general_prefs.tiff");
		[self dealloc];
		return nil;
	}

	preferencesIcon = [[NSImage alloc] initWithContentsOfFile:
	  path];
	if (!preferencesIcon)
	{
		NSLog(@"Could not load image %@", path);
		[self dealloc];
		return nil;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: DefaultsChangedNotification 
	  object: IRCDefaultsNick];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: DefaultsChangedNotification 
	  object: IRCDefaultsRealName];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: DefaultsChangedNotification 
	  object: IRCDefaultsUserName];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: DefaultsChangedNotification 
	  object: IRCDefaultsPassword];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputDefaultQuitMessage];

	[[NSNotificationCenter defaultCenter]
	 postNotificationName: PreferencesModuleAdditionNotification 
	 object: self];

	return self;
}
- (void)awakeFromNib
{
	NSWindow *tempWindow;

	tempWindow = (NSWindow *)preferencesView;
	preferencesView = RETAIN([tempWindow contentView]);
	RELEASE(tempWindow);
	[preferencesView setAutoresizingMask:
	  NSViewWidthSizable | NSViewHeightSizable];
}
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	RELEASE(preferencesView);
	RELEASE(preferencesIcon);
	[super dealloc];
}
- (void)setTimestampEnabled: (NSButton *)aSender
{
	NSString *newState, *oldValue;

	oldValue = [_PREFS_ preferenceForKey: 
	  GNUstepOutputTimestampEnabled];

	if ([timestampButton state] == NSOnState) 
	{
		newState = @"YES";
	} 
	else 
	{
		newState = @"NO";
	}

	if (![oldValue isEqualToString: newState])
	{
		[_PREFS_ setPreference: newState 
		  forKey: GNUstepOutputTimestampEnabled];

		[[NSNotificationCenter defaultCenter]
		 postNotificationName: DefaultsChangedNotification
		 object: GNUstepOutputTimestampEnabled 
		 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
		  _TS_, @"Bundle",
		  newState, @"New",
		  self, @"Owner",
		  oldValue, @"Old",
		  nil]];
	}
}
- (void)setText: (NSTextField *)aField
{
	NSString *preference, *newValue, *oldValue;

	if (aField == userView)
	{
		preference = IRCDefaultsUserName;
	}
	else if (aField == nameView)
	{
		preference = IRCDefaultsRealName;
	}
	else if (aField == passwordView)
	{
		preference = IRCDefaultsPassword;
	}
	else if (aField == nickView)
	{
		preference = IRCDefaultsNick;
	}
	else if (aField == quitView)
	{
		preference = GNUstepOutputDefaultQuitMessage;
	}
	else if (aField == timestampFormatField)
	{
		preference = GNUstepOutputTimestampFormat;
	}
	else
	{
		return;
	}

	oldValue = [_PREFS_ preferenceForKey: preference];
	newValue = [aField stringValue];
	
	[_PREFS_ setPreference: newValue forKey: preference];

	[[NSNotificationCenter defaultCenter]
	 postNotificationName: DefaultsChangedNotification
	 object: preference 
	 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
	  _TS_, @"Bundle",
	  newValue, @"New",
	  self, @"Owner",
	  oldValue, @"Old",
	  nil]];
}
- (NSString *)preferencesName
{
	return @"General";
}
- (NSImage *)preferencesIcon
{
	return preferencesIcon;
}
- (NSView *)preferencesView
{
	return preferencesView;
}
- (void)activate: (PreferencesController *)aPrefs
{
	activated = YES;
	[self refreshFromPreferences];
	[[aPrefs window] makeFirstResponder: nickView];
}
- (void)deactivate
{
	activated = NO;
}
@end

@implementation GeneralPreferencesController (PrivateMethods)
- (void)preferenceChanged: (NSNotification *)aNotification
{
	id userInfo;
	if (!activated) return;

	userInfo = [aNotification userInfo];

	if ([userInfo objectForKey: @"Owner"] == self) return;

	[self refreshFromPreferences];
}
- (void)refreshFromPreferences
{
	id nick, user, pass, rn, qt, fmt, fmtE;

	nick = [_PREFS_ preferenceForKey:
	  IRCDefaultsNick];
	user = [_PREFS_ preferenceForKey:
	  IRCDefaultsUserName];
	pass = [_PREFS_ preferenceForKey:
	  IRCDefaultsPassword];
	rn = [_PREFS_ preferenceForKey:
	  IRCDefaultsRealName];
	qt = [_PREFS_ preferenceForKey:
	  GNUstepOutputDefaultQuitMessage];
	fmt = [_PREFS_ preferenceForKey:
	  GNUstepOutputTimestampFormat];
	fmtE = [_PREFS_ preferenceForKey:
	  GNUstepOutputTimestampEnabled];

	if (!nick) nick = @"";
	if (!user) user = @"";
	if (!pass) pass = @"";
	if (!rn) rn = @"";
	if (!qt) qt = @"";
	if (!fmt) fmt = @"";

	[nickView setStringValue: nick];
	[userView setStringValue: user];
	[passwordView setStringValue: pass];
	[nameView setStringValue: rn];
	[quitView setStringValue: qt];
	[timestampFormatField setStringValue: fmt];

	if ([fmtE isEqualToString: @"YES"]) 
	{
		[timestampButton setState: NSOnState];
	} 
	else if ([fmtE isEqualToString: @"NO"])
	{
		[timestampButton setState: NSOffState];
	}
	else
	{
		[timestampButton setState: NSOffState];
		[self setTimestampEnabled: timestampButton];
	}
}
@end
