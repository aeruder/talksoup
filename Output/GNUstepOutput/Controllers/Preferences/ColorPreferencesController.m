/***************************************************************************
                      ColorPreferencesController.m
                          -------------------
    begin                : Sat Aug 14 19:19:31 CDT 2004
    copyright            : (C) 2004 by Andrew Ruder
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

#import "Controllers/Preferences/ColorPreferencesController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "Misc/NSColorAdditions.h"
#import "GNUstepOutput.h"

#import <AppKit/NSImage.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSColorWell.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSButton.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNotification.h>

NSString *GNUstepOutputPersonalBracketColor = @"GNUstepOutputPersonalBracketColor";
NSString *GNUstepOutputOtherBracketColor = @"GNUstepOutputOtherBracketColor";
NSString *GNUstepOutputTextColor = @"GNUstepOutputTextColor";
NSString *GNUstepOutputBackgroundColor = @"GNUstepOutputBackgroundColor";

@interface ColorPreferencesController (PrivateMethods)
- (void)setDefaultColors: (NSButton *)aButton;
- (void)refreshFromPreferences;
- (void)preferenceChanged: (NSNotification *)aNotification;
@end

@implementation ColorPreferencesController
- init
{
	id path;
	if (!(self = [super init])) return nil;

	if (!([NSBundle loadNibNamed: @"ColorPreferences" owner: self]))
	{
		[self dealloc];
		return nil;
	}

	path = [[NSBundle bundleForClass: [GNUstepOutput class]] 
	  pathForResource: @"color_prefs" ofType: @"tiff"];
	if (!path) 
	{
		NSLog(@"Could not find color_prefs.tiff");
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
	  name: PreferencesChangedNotification 
	  object: GNUstepOutputPersonalBracketColor];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: PreferencesChangedNotification 
	  object: GNUstepOutputTextColor];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: PreferencesChangedNotification 
	  object: GNUstepOutputBackgroundColor];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: PreferencesChangedNotification 
	  object: GNUstepOutputOtherBracketColor];

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
}
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	RELEASE(preferencesView);
	RELEASE(preferencesIcon);
	[super dealloc];
}
- (void)setColorPreference: (NSColorWell *)aWell
{
	NSString *preference, *newValue, *oldValue;
	
	if (aWell == otherColorWell)
	{
		preference = GNUstepOutputOtherBracketColor;
	} 
	else if (aWell == personalColorWell) 
	{
		preference = GNUstepOutputPersonalBracketColor;
	}
	else if (aWell == backgroundColorWell)
	{
		preference = GNUstepOutputBackgroundColor;
	}
	else if (aWell == textColorWell)
	{
		preference = GNUstepOutputTextColor;
	}
	else
	{
		return;
	}

	oldValue = [_PREFS_ preferenceForKey: preference];
	newValue = [[aWell color] encodeToData];
	
	[_PREFS_ setPreference: newValue forKey: preference];

	[[NSNotificationCenter defaultCenter]
	 postNotificationName: PreferencesChangedNotification
	 object: preference 
	 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
	  _GS_, @"Bundle",
	  newValue, @"New",
	  self, @"Owner",
	  oldValue, @"Old",
	  nil]];
}
- (NSString *)preferencesName
{
	return @"Colors";
}
- (NSImage *)preferencesIcon
{
	return preferencesIcon;
}
- (NSView *)preferencesView
{
	return preferencesView;
}
- (void)activate
{
	activated = YES;
	[self refreshFromPreferences];
}
- (void)deactivate
{
	activated = NO;
}
@end

@implementation ColorPreferencesController (PrivateMethods)
- (void)setDefaultColors: (NSButton *)aButton
{
	id txColor, otherColor, persColor, bgColor;

	txColor = [_PREFS_ defaultPreferenceForKey:
	  GNUstepOutputTextColor];
	otherColor = [_PREFS_ defaultPreferenceForKey:
	  GNUstepOutputOtherBracketColor];
	persColor = [_PREFS_ defaultPreferenceForKey:
	  GNUstepOutputPersonalBracketColor];
	bgColor = [_PREFS_ defaultPreferenceForKey:
	  GNUstepOutputBackgroundColor];

	[_PREFS_ setPreference: txColor forKey:
	  GNUstepOutputTextColor];
	[_PREFS_ setPreference: otherColor forKey:
	  GNUstepOutputOtherBracketColor];
	[_PREFS_ setPreference: persColor forKey:
	  GNUstepOutputPersonalBracketColor];
	[_PREFS_ setPreference: bgColor forKey:
	  GNUstepOutputBackgroundColor];

	[self refreshFromPreferences];
}
- (void)refreshFromPreferences
{
	id txColor, otherColor, persColor, bgColor;

	txColor = [_PREFS_ preferenceForKey:
	  GNUstepOutputTextColor];
	otherColor = [_PREFS_ preferenceForKey:
	  GNUstepOutputOtherBracketColor];
	persColor = [_PREFS_ preferenceForKey:
	  GNUstepOutputPersonalBracketColor];
	bgColor = [_PREFS_ preferenceForKey:
	  GNUstepOutputBackgroundColor];

	txColor = [NSColor colorFromEncodedData: txColor];
	otherColor = [NSColor colorFromEncodedData: otherColor];
	persColor = [NSColor colorFromEncodedData: persColor];
	bgColor = [NSColor colorFromEncodedData: bgColor];

	[textColorWell setColor: txColor];
	[otherColorWell setColor: otherColor];
	[personalColorWell setColor: persColor];
	[backgroundColorWell setColor: bgColor];
}
- (void)preferenceChanged: (NSNotification *)aNotification
{
	id userInfo;
	if (!activated) return;

	userInfo = [aNotification userInfo];

	if ([userInfo objectForKey: @"Owner"] == self) return;
	
	[self refreshFromPreferences];
}
@end
