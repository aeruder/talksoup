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
#import "Controllers/Preferences/GeneralPreferencesController.h"
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
#import <AppKit/NSClipView.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSString.h>
#import <AppKit/NSView.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSColor.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSCalendarDate.h>

@interface StandardQueryController (PreferencesCenter)
- (void)timestampEnabledChanged: (NSNotification *)aNotification;
- (void)timestampFormatChanged: (NSNotification *)aNotification;
- (void)colorChanged: (NSNotification *)aNotification;
- (void)chatFontChanged: (NSNotification *)aNotification;
- (void)wrapIndentChanged: (NSNotification *)aNotification;
- (void)scrollLinesChanged: (NSNotification *)aNotification;
@end

@implementation StandardQueryController
+ (NSString *)standardNib
{
	return @"StandardQuery";
}
- init
{
	if (!(self = [super init])) return self;

	if ([self isMemberOfClass: [StandardQueryController class]] && 
	   !([NSBundle loadNibNamed: [StandardQueryController standardNib] owner: self]))
	{
		NSLog(@"Failed to load StandardQueryController UI");
		[self dealloc];
		return nil;
	}

	return self;
}
- initFromChannel
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
	id contain;
	
	[chatView setEditable: NO];
	[chatView setSelectable: YES];
	[chatView setRichText: NO];
	[chatView setDrawsBackground: YES];

	[chatView setHorizontallyResizable: NO];
	[chatView setVerticallyResizable: YES];
	[chatView setMinSize: NSMakeSize(0, 0)];
	[chatView setMaxSize: NSMakeSize(1e7, 1e7)];

	contain = [chatView textContainer];
	[chatView setTextContainerInset: NSMakeSize(2, 2)];
	[contain setWidthTracksTextView: YES];
	[contain setHeightTracksTextView: NO];
	
	[chatView setBackgroundColor: [NSColor colorFromEncodedData:
	  [_PREFS_ preferenceForKey: GNUstepOutputBackgroundColor]]];
	[chatView setTextColor: [NSColor colorFromEncodedData:
	  [_PREFS_ preferenceForKey: GNUstepOutputTextColor]]];

	[chatView setFrame: [[[chatView enclosingScrollView] contentView] bounds]];
	[chatView setNeedsDisplay: YES];
		  
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

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(wrapIndentChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputWrapIndent];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(timestampEnabledChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputTimestampEnabled];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(timestampFormatChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputTimestampFormat];

	scrollLines = [[_PREFS_ preferenceForKey: GNUstepOutputBufferLines]
	  intValue];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(scrollLinesChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputBufferLines];

	[self wrapIndentChanged: nil];
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
- (void)appendAttributedString: (NSAttributedString *)aString
{
	id textStorage;
	NSMutableAttributedString *mutString;
	NSString *string;

	if ([aString length] == 0)
	{
		return;
	}

	textStorage = [chatView textStorage];
	string = [textStorage string];

	mutString = [NSMutableAttributedString 
	  attributedStringWithGNUstepOutputPreferences: aString];
	[mutString addTimestampsAndHandleFirst: ![string length] || [string hasSuffix: @"\n"]];
	
	[textStorage beginEditing];
	[textStorage appendAttributedString: mutString];
	[textStorage endEditing];

	numLines += [[[mutString string]
      componentsSeparatedByString: @"\n"] count] - 1;

	if (numLines > scrollLines)
	{
		[textStorage chopNumberOfLines: numLines - scrollLines];
		numLines = scrollLines;
	}
}
@end

@implementation StandardQueryController (PreferencesCenter)
- (void)timestampEnabledChanged: (NSNotification *)aNotification
{
	[[chatView textStorage]
	  updateAttributedStringForGNUstepOutputPreferences: 
	  GNUstepOutputTimestampFormat];
}
- (void)timestampFormatChanged: (NSNotification *)aNotification
{
	[[chatView textStorage]
	  updateAttributedStringForGNUstepOutputPreferences: 
	  [aNotification object]];
}
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
- (void)wrapIndentChanged: (NSNotification *)aNotification
{
#ifndef GNUSTEP
	float wIndentF = [[_PREFS_ preferenceForKey: GNUstepOutputWrapIndent]
	  floatValue];
	NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paraStyle setHeadIndent: wIndentF];
	[chatView setDefaultParagraphStyle: paraStyle];
#else
	[[chatView textStorage]
	  updateAttributedStringForGNUstepOutputPreferences: 
	  GNUstepOutputWrapIndent];
#endif
}
- (void)scrollLinesChanged: (NSNotification *)aNotification
{
	scrollLines = [[_PREFS_ preferenceForKey: GNUstepOutputBufferLines]
	  intValue];
}
@end
