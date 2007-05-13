/***************************************************************************
                      FontPreferencesController.m
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
#import <AppKit/NSStepper.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSDebug.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSFontManager.h>
#import <Foundation/NSDictionary.h>

#include <math.h>

NSString *GNUstepOutputChatFont = @"GNUstepOutputChatFont";
NSString *GNUstepOutputBoldChatFont = @"GNUstepOutputBoldChatFont";
NSString *GNUstepOutputUserListFont = @"GNUstepOutputUserListFont";
NSString *GNUstepOutputWrapIndent = @"GNUstepOutputWrapIndent";

@interface FontPreferencesController (PrivateMethods)
- (void)preferenceChanged: (NSNotification *)aNotification;
- (void)refreshFromPreferences;
- (void)fontView: (FontPreferencesFontView *)aFontView
   changeFont: (id)sender;
@end

@implementation FontPreferencesController
+ (NSFont *)getFontFromPreferences: (NSString *)aPrefName
{
	NSString *fontName;
	id tmpSize;
	float fontSize;
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
		if ([aPrefName isEqualToString: GNUstepOutputBoldChatFont])
		{
			font = [NSFont boldSystemFontOfSize: 0.0];
		}
		else
		{
			font = [NSFont userFontOfSize: 0.0];
		}
	}

	return font;
}
+ (NSFont *)getFontFromPreferences: (NSString *)aPrefName ofSize: (float)aSize
{
	NSFontManager *manager;

	manager = [NSFontManager sharedFontManager];
	
	return [manager convertFont: [self getFontFromPreferences: aPrefName]
	  toSize: aSize];
}
- init
{
	id path;
	if (!(self = [super init])) return nil;

	if (!([NSBundle loadNibNamed: @"FontPreferences" owner: self]))
	{
		NSLog(@"Couldn't load FontPreferences nib");
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
	  object: [GNUstepOutputChatFont 
	   stringByAppendingString: @"Size"]];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: DefaultsChangedNotification 
	  object: [GNUstepOutputUserListFont 
	   stringByAppendingString: @"Size"]];

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

	[fontSetView setDelegate: self];
}
- (void)dealloc
{
	[wrapIndentField setDelegate: nil];
	[fontSetView setDelegate: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	RELEASE(preferencesView);
	RELEASE(preferencesIcon);
	[super dealloc];
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
	else if (aButton == boldFontButton)
	{
		lastView = boldFontField;
	}
	else
	{
		return;
	}

	[[NSFontManager sharedFontManager] setSelectedFont:
	  [lastView font] isMultiple: NO];
	
	[[_PREFS_ window] makeFirstResponder: fontSetView];
	
	panel = [NSFontPanel sharedFontPanel];

	[panel orderFront: self];

	return;
}
- (void)setWrapIndent: (NSTextField *)aField
{
	double amount = [aField doubleValue];
	id string;
	id old;

	[aField setStringValue: 
	 [NSString stringWithFormat: @"%.2f", (float)amount]];

	old  = [_PREFS_ preferenceForKey: 
	  GNUstepOutputWrapIndent];
	
	if (amount != 0.0)
	{
		amount = amount * 28.35;
	}
	
	string = [NSString stringWithFormat: @"%.5f", (float)amount];
	[_PREFS_ setPreference: string
	  forKey: GNUstepOutputWrapIndent];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: DefaultsChangedNotification
	 object: GNUstepOutputWrapIndent
	 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
	  _GS_, @"Bundle",
	  string, @"New",
	  self, @"Owner",
	  old, @"Old",
	  nil]];
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
	return preferencesView;
}
- (void)activate: (PreferencesController *)aPrefs
{
	activated = YES;
	[self refreshFromPreferences];
	[[aPrefs window] makeFirstResponder: chatFontButton];
}
- (void)deactivate
{
	activated = NO;
}
@end

@implementation FontPreferencesController (PrivateMethods)
- (void)preferenceChanged: (NSNotification *)aNotification
{
	id userInfo;
	if (!activated) return;

	userInfo = [aNotification userInfo];

	if (([userInfo objectForKey: @"Owner"] == self) ||
	    ([userInfo objectForKey: @"Owner"] == [self class])) return;

	[self refreshFromPreferences];
}
- (void)refreshFromPreferences
{
	id uFont, bFont, cFont, wIndent;
	float wIndentF;

	uFont = [FontPreferencesController getFontFromPreferences: 
	  GNUstepOutputUserListFont];
	cFont = [FontPreferencesController getFontFromPreferences:
	  GNUstepOutputChatFont];
	bFont = [FontPreferencesController getFontFromPreferences:
	  GNUstepOutputBoldChatFont];

	[userFontField setStringValue:
	  [NSString stringWithFormat: @"%@ %.1f",
	   [uFont displayName], [uFont pointSize]]];
	[userFontField setFont: uFont];
	[chatFontField setStringValue:
	  [NSString stringWithFormat: @"%@ %.1f",
	   [cFont displayName], [cFont pointSize]]];
	[chatFontField setFont: cFont];
	[boldFontField setStringValue:
	  [NSString stringWithFormat: @"%@ %.1f",
	   [bFont displayName], [bFont pointSize]]];
	[boldFontField setFont: bFont];

	wIndent = [_PREFS_ preferenceForKey: GNUstepOutputWrapIndent];
	wIndentF = [wIndent floatValue];
	wIndent = [NSString stringWithFormat: @"%.2f", wIndentF / 28.35];
	[wrapIndentField setStringValue: wIndent];
}
- (void)fontView: (FontPreferencesFontView *)aFontView
   changeFont: (id)sender
{
	NSString *preference;
	NSFont *aFont;
	NSString *name;
	NSString *size;
	NSString *oldName;

	if (lastView == userFontField)
	{
		preference = GNUstepOutputUserListFont;
	}
	else if (lastView == chatFontField)
	{
		preference = GNUstepOutputChatFont;
	}
	else if (lastView == boldFontField)
	{
		preference = GNUstepOutputBoldChatFont;
	}
	else
	{
		return;
	}
	
	oldName = [[lastView font] fontName];

	aFont = [[NSFontManager sharedFontManager] convertFont:
	  [lastView font]];

	if ([lastView font] == aFont) return;

	[lastView setFont: aFont];

	name = [aFont fontName];
	size = [NSString stringWithFormat: @"%.1f", [aFont pointSize]];

	[lastView setStringValue:
	  [NSString stringWithFormat: @"%@ %@", [aFont displayName], size]];

	[_PREFS_ setPreference: name 
	  forKey: preference];
	[_PREFS_ setPreference: size 
	  forKey: [preference stringByAppendingString: @"Size"]];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: DefaultsChangedNotification
	 object: preference 
	 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
	  _GS_, @"Bundle",
	  name, @"New",
	  self, @"Owner",
	  oldName, @"Old",
	  nil]];
}
@end

@implementation FontPreferencesFontView
- (BOOL)acceptsFirstResponder
{
	return YES;
}
- (void)setDelegate: aDelegate
{
	delegate = aDelegate;
}
- (void)changeFont: (id)sender
{
	[delegate fontView: self changeFont: sender];
}
@end
