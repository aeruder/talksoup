/***************************************************************************
                       StandardQueryController.m
                          -------------------
    begin                : Sat Jan 18 01:38:06 CST 2003
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

#import "Controllers/Preferences/PreferencesController.h"
#import "Controllers/Preferences/ColorPreferencesController.h"
#import "Controllers/ContentControllers/StandardQueryController.h"
#import "Views/ScrollingTextView.h"
#import "Misc/NSColorAdditions.h"
#import "GNUstepOutput.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <AppKit/NSNibLoading.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSNotification.h>

@interface StandardQueryController (PreferencesCenter)
- (void)backgroundChanged: (NSNotification *)aNotification;
- (void)foregroundChanged: (NSNotification *)aNotification;
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
	  selector: @selector(backgroundChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputBackgroundColor];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(foregroundChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputTextColor];
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
- (void)backgroundChanged: (NSNotification *)aNotification
{
	id color;

	color = [_PREFS_ preferenceForKey: GNUstepOutputBackgroundColor];
	color = [NSColor colorFromEncodedData: color];

	[chatView setBackgroundColor: color];
}
- (void)foregroundChanged: (NSNotification *)aNotification
{
	id color;

	color = [_PREFS_ preferenceForKey: GNUstepOutputTextColor];
	color = [NSColor colorFromEncodedData: color];
	/* FIXME
	 * This probably needs to be done the way it used to be done.
	 * It will be a lot more complicated than just this one call
	 */
	[chatView setTextColor: color];
}
@end
