/***************************************************************************
                      FontPreferencesController.m
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

#import "Controllers/Preferences/FontPreferencesController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "GNUstepOutput.h"

#import <AppKit/NSImage.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSFontPanel.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNotification.h>

#include <math.h>

NSString *GNUstepOutputChatFont = @"GNUstepOutputChatFont";
NSString *GNUstepOutputUserListFont = @"GNUstepOutputUserListFont";

@interface FontPreferencesController (PrivateMethods)
- (void)preferenceChanged: (NSNotification *)aNotification;
- (void)refreshFromPreferences;
- (void)changeFont: (id)sender;
@end

@implementation FontPreferencesController
- init
{
	id path;
	if (!(self = [super init])) return nil;

	if (!([NSBundle loadNibNamed: @"FontPreferences" owner: self]))
	{
		[self dealloc];
		return nil;
	}

	path = [[NSBundle bundleForClass: [GNUstepOutput class]] 
	  pathForResource: @"font_prefs" ofType: @"tiff"];
	if (!path) 
	{
		NSLog(@"Could not find font_prefs.tiff");
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
	  object: GNUstepOutputChatFont];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: DefaultsChangedNotification 
	  object: GNUstepOutputUserListFont];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: DefaultsChangedNotification 
	  object: [NSString stringWithFormat: @"%@Size",
	   GNUstepOutputChatFont]];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: DefaultsChangedNotification 
	  object: [NSString stringWithFormat: @"%@Size",
	   GNUstepOutputUserListFont]];

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
	[[NSFontManager sharedFontManager] setDelegate: nil];
	RELEASE(preferencesView);
	RELEASE(preferencesIcon);
	[super dealloc];
}
- (NSFont *)getFontFromPreferences: (NSString *)aPrefName
{
	NSString *fontName;
	id tmpSize;
	float fontSize;
	BOOL changed = NO;
	NSFont *userFont = [NSFont userFontOfSize: 0.0];
	NSFont *font;
	NSString *aPrefSize;

	aPrefSize = [aPrefName stringByAppendingString: @"Size"];
	
	fontName = [_PREFS_ preferenceForKey: aPrefName];
	tmpSize = [_PREFS_ preferenceForKey: aPrefSize];
	fontSize = (tmpSize) ? [tmpSize floatValue] : 0.0;

	if ((!fontName) || ([fontName length] == 0)
	 || (fontSize <= 0.001) ||
	 !(font = [NSFont fontWithName: fontName size: fontSize]))
	{
		font = userFont;
	}

	if (![[font fontName] isEqualToString: fontName])
	{
		[_PREFS_ setPreference: [font fontName]
		 forKey: aPrefName];
		changed = YES;
	}

	if (fabs([font pointSize] - fontSize) >= .1)
	{
		id pref = [NSString stringWithFormat: @"%0.1f", 
		  [font pointSize]];
		[_PREFS_ setPreference: pref
		  forKey: aPrefSize];
		changed = YES;
	}

	if (changed)
	{
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: DefaultsChangedNotification
		 object: aPrefName 
		 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
		  _GS_, @"Bundle",
		  [font fontName], @"New",
		  self, @"Owner",
		  fontName, @"Old",
		  nil]];
	}

	return font;
}

- (void)hitFontButton: (NSButton *)aButton
{
	id panel;

	if (aButton == userFontButton)
	{
		lastView = userFontField;
	}
	else if (aButton == chatFontButton)
	{
		lastView = chatFontField;
	}
	else
	{
		return;
	}
	
	[[_PREFS_ window] makeFirstResponder: lastView];
	
	panel = [NSFontPanel sharedFontPanel];

	[[NSFontManager sharedFontManager] setSelectedFont: 
	  [lastView font] isMultiple: NO];

	[[NSFontManager sharedFontManager] setDelegate: self];
	
	[panel orderFront: self];

	return;
}
- (NSString *)preferencesName
{
	return @"Fonts";
}
- (NSImage *)preferencesIcon
{
	return preferencesIcon;
}
- (NSView *)preferencesView
{
	NSLog(@"preferencesView: %@", preferencesView);
	return preferencesView;
}
- (void)activate: (PreferencesController *)aPrefs
{
	activated = YES;
	[self refreshFromPreferences];
}
- (void)deactivate
{
	activated = NO;
}
@end

@implementation FontPreferencesController (PrivateMethods)
- (void)preferenceChanged: (NSNotification *)aNotification
{
}
- (void)refreshFromPreferences
{
	id uFont;
	id cFont;

	uFont = [self getFontFromPreferences: 
	  GNUstepOutputUserListFont];
	cFont = [self getFontFromPreferences:
	  GNUstepOutputChatFont];

	[userFontField setStringValue:
	  [NSString stringWithFormat: @"%@ %.1f",
	   [uFont displayName], [uFont pointSize]]];
	[userFontField setFont: uFont];
	[chatFontField setStringValue:
	  [NSString stringWithFormat: @"%@ %.1f",
	   [cFont displayName], [cFont pointSize]]];
	[chatFontField setFont: cFont];
}
- (void)changeFont: (id)sender
{
	NSLog(@"Font changed!");
	NSLog(@"%@ %@ %@ %.1f", sender, lastView, [[lastView font] fontName], [[lastView font] pointSize]);
}
@end
