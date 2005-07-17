/***************************************************************************
                      ColorPreferencesController.m
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

#import "Controllers/Preferences/ColorPreferencesController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "Misc/NSColorAdditions.h"
#import "Misc/NSAttributedStringAdditions.h"
#import "GNUstepOutput.h"

#import <AppKit/NSImage.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSColorWell.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSScrollView.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSColor.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSDictionary.h>

NSString *GNUstepOutputPersonalBracketColor = @"GNUstepOutputPersonalBracketColor";
NSString *GNUstepOutputOtherBracketColor = @"GNUstepOutputOtherBracketColor";
NSString *GNUstepOutputTextColor = @"GNUstepOutputTextColor";
NSString *GNUstepOutputBackgroundColor = @"GNUstepOutputBackgroundColor";

@interface ColorPreferencesController (PrivateMethods)
- (void)saveFromPreferences;
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
		NSLog(@"Couldn't load ColorPreferences nib");
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
	
	lastApplied = [NSMutableDictionary new];
	[self saveFromPreferences];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: DefaultsChangedNotification 
	  object: GNUstepOutputPersonalBracketColor];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: DefaultsChangedNotification 
	  object: GNUstepOutputTextColor];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: DefaultsChangedNotification 
	  object: GNUstepOutputBackgroundColor];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferenceChanged:)
	  name: DefaultsChangedNotification 
	  object: GNUstepOutputOtherBracketColor];

	[[NSNotificationCenter defaultCenter]
	 postNotificationName: PreferencesModuleAdditionNotification 
	 object: self];

	return self;
}
#define MARK [NSNull null]
- (void)awakeFromNib
{
	id pubstring;
	id contain;
	
	NSWindow *tempWindow;

	tempWindow = (NSWindow *)preferencesView;
	preferencesView = RETAIN([tempWindow contentView]);
	RELEASE(tempWindow);

	[textPreview setEditable: NO];
	[textPreview setSelectable: YES];
	[textPreview setRichText: NO];
	[textPreview setDrawsBackground: YES];

	[textPreview setHorizontallyResizable: NO];
	[textPreview setVerticallyResizable: YES];
	[textPreview setMinSize: NSMakeSize(0, 0)];
	[textPreview setMaxSize: NSMakeSize(1e7, 1e7)];

	contain = [textPreview textContainer];
	[textPreview setTextContainerInset: NSMakeSize(2, 2)];
	[contain setWidthTracksTextView: YES];
	[contain setHeightTracksTextView: NO];
	
	[textPreview setString: @""];
	[textPreview setBackgroundColor: [NSColor colorFromEncodedData:
	  [_PREFS_ preferenceForKey: GNUstepOutputBackgroundColor]]];
	[textPreview setTextColor: [NSColor colorFromEncodedData:
	  [_PREFS_ preferenceForKey: GNUstepOutputTextColor]]];

	[textPreview setNeedsDisplay: YES];

	pubstring = BuildAttributedString(
	  MARK, TypeOfColor, GNUstepOutputPersonalBracketColor, @"<", 
	  @"aeruder", 
	  MARK, TypeOfColor, GNUstepOutputPersonalBracketColor, @">",
	  @" ", _l(@"TalkSoup really works so wonderfully!"), @"\n", nil);
	
	[[textPreview textStorage] appendAttributedString:
	  [NSMutableAttributedString 
	  attributedStringWithGNUstepOutputPreferences: pubstring]];

	pubstring = BuildAttributedString(
	  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @"<", 
	  @"ckchan", 
	  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @">",
	  @" ", _l(@"you're so weird"), @"\n", nil);

	[[textPreview textStorage] appendAttributedString:
	  [NSMutableAttributedString 
	  attributedStringWithGNUstepOutputPreferences: pubstring]];

	pubstring = BuildAttributedString(
	  MARK, TypeOfColor, GNUstepOutputPersonalBracketColor, @"<", 
	  @"aeruder", 
	  MARK, TypeOfColor, GNUstepOutputPersonalBracketColor, @">",
	  @" ", _l(@"So... you're saying you like it too?"), nil);

	[[textPreview textStorage] appendAttributedString:
	  [NSMutableAttributedString 
	  attributedStringWithGNUstepOutputPreferences: pubstring]];
}
#undef MARK
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	RELEASE(preferencesView);
	RELEASE(preferencesIcon);
	[super dealloc];
}
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
- (void)applyChanges: (NSButton *)aButton
{
	NSString *x[] = {
	  GNUstepOutputOtherBracketColor,
	  GNUstepOutputPersonalBracketColor, 
	  GNUstepOutputBackgroundColor,
	  GNUstepOutputTextColor,
	  nil
	};
	NSString **iter;
	NSString *curr;

	for (iter = x; *iter != nil; iter++)
	{
		curr = [_PREFS_ preferenceForKey: *iter];
		if ([curr isEqualToString: [lastApplied objectForKey: *iter]])
		{
			continue;
		}

		[[NSNotificationCenter defaultCenter]
		 postNotificationName: DefaultsChangedNotification
		 object: *iter
		 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
		  _GS_, @"Bundle",
		  curr, @"New",
		  self, @"Owner",
		  [lastApplied objectForKey: *iter], @"Old",
		  nil]];
	}

	[self saveFromPreferences];
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
		[textPreview setBackgroundColor: [aWell color]];
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

	[[textPreview textStorage] 
	  updateAttributedStringForGNUstepOutputPreferences: preference];
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
- (void)activate: (PreferencesController *)aPrefs
{
	activated = YES;
	[self refreshFromPreferences];
	[[aPrefs window] makeFirstResponder: personalColorWell];
}
- (void)deactivate
{
	activated = NO;
}
@end

@implementation ColorPreferencesController (PrivateMethods)
- (void)saveFromPreferences
{
	id txColor, otherColor, persColor, bgColor;

	txColor = [_PREFS_ preferenceForKey:
	  GNUstepOutputTextColor];
	[lastApplied setObject: txColor forKey: GNUstepOutputTextColor];

	otherColor = [_PREFS_ preferenceForKey:
	  GNUstepOutputOtherBracketColor];
	[lastApplied setObject: otherColor forKey: GNUstepOutputOtherBracketColor];

	persColor = [_PREFS_ preferenceForKey:
	  GNUstepOutputPersonalBracketColor];
	[lastApplied setObject: persColor forKey: GNUstepOutputPersonalBracketColor];

	bgColor = [_PREFS_ preferenceForKey:
	  GNUstepOutputBackgroundColor];
	[lastApplied setObject: bgColor forKey: GNUstepOutputBackgroundColor];
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
