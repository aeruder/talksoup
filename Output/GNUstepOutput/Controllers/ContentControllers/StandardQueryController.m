/***************************************************************************
                       StandardQueryController.m
                          -------------------
    begin                : Sat Jan 18 01:38:06 CST 2003
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

#import "Controllers/ContentControllers/StandardQueryController.h"
#import "Controllers/Preferences/ColorPreferencesController.h"
#import "Controllers/Preferences/FontPreferencesController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "GNUstepOutput.h"
#import "Misc/NSAttributedStringAdditions.h"
#import "Misc/NSColorAdditions.h"
#import "Views/ScrollingTextView.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <AppKit/NSNibLoading.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSNotification.h>

@interface StandardQueryController (PreferencesCenter)
- (void)colorChanged: (NSNotification *)aNotification;
- (void)chatFontChanged: (NSNotification *)aNotification;
@end

@implementation StandardQueryController
+ (NSString *)standardNib
{
	return @"StandardQuery";
}
- init
{
	if (!(self = [super init])) return self;

	if (!([NSBundle loadNibNamed: [StandardQueryController standardNib] owner: self]))
	{
		NSLog(@"Failed to load StandardQueryController UI");
		[self dealloc];
		return nil;
	}

	return self;
}
- (void)awakeFromNib
{	
	id x;
	
	[chatView setHorizontallyResizable: NO];
	[chatView setVerticallyResizable: YES];
	[chatView setMinSize: NSMakeSize(0, 0)];
	[chatView setMaxSize: NSMakeSize(1e7, 1e7)];
	[[chatView textContainer] setContainerSize:
	  NSMakeSize([chatView frame].size.width, 1e7)];
	[[chatView textContainer] setWidthTracksTextView: YES];
	[chatView setTextContainerInset: NSMakeSize(2, 2)];
	[chatView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[chatView setFrameSize: [[chatView enclosingScrollView] contentSize]];
	[chatView setEditable: NO];
	[chatView setSelectable: YES];
	[chatView setRichText: NO];
	
	[chatView setBackgroundColor: [NSColor colorFromEncodedData:
	  [_PREFS_ preferenceForKey: GNUstepOutputBackgroundColor]]];
	[chatView setTextColor: [NSColor colorFromEncodedData:
	  [_PREFS_ preferenceForKey: GNUstepOutputTextColor]]];
		  
	x = RETAIN([(NSWindow *)window contentView]);
	[window close];
	AUTORELEASE(window);
	window = x;
	[window setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(colorChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputBackgroundColor];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(colorChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputTextColor];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(colorChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputOtherBracketColor];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(colorChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputPersonalBracketColor];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(chatFontChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputChatFont];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(chatFontChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputBoldChatFont];
}
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	DESTROY(window);
	[super dealloc];
}
- (NSTextView *)chatView
{
	return chatView;
}
- (NSView *)contentView
{
	return window;
}
@end

@implementation StandardQueryController (PreferencesCenter)
- (void)colorChanged: (NSNotification *)aNotification
{
	id object;

	object = [aNotification object];
	if ([object isEqualToString: GNUstepOutputBackgroundColor])
	{
		[chatView setBackgroundColor: [NSColor colorFromEncodedData:
		  [_PREFS_ preferenceForKey: object]]];
	}

	[[chatView textStorage]
	  updateAttributedStringForGNUstepOutputPreferences: object];
}
- (void)chatFontChanged: (NSNotification *)aNotification
{
	[[chatView textStorage]
	  updateAttributedStringForGNUstepOutputPreferences: 
	  [aNotification object]];
}	
@end
