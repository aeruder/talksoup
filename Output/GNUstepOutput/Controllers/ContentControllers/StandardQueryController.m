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
#import <Foundation/NSNotification.h>
#import <Foundation/NSString.h>
#import <AppKit/NSView.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSColor.h>
#import <Foundation/NSNull.h>

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

	timestampEnabled = [GeneralPreferencesController timestampEnabled];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(timestampEnabledChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputTimestampEnabled];

	timestampFormat = RETAIN([_PREFS_ preferenceForKey: GNUstepOutputTimestampFormat]);

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

}
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	DESTROY(window);
	RELEASE(timestampFormat);
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
	NSString *string;
	NSRange allRange, thisRange;
	NSMutableAttributedString *mutString;
	id date;
	NSAttributedString *format = nil;
	unsigned formatlen = 0;
	BOOL handleFirst;

	if ([aString length] == 0)
	{
		return;
	}

	string = [aString string];
	allRange = NSMakeRange(0, [string length]);
	mutString = [[NSMutableAttributedString alloc] 
	  initWithAttributedString: aString];
	date = [NSDate date];
	if (timestampEnabled) 
	{
		NSString *aFmt;
		aFmt = [date descriptionWithCalendarFormat: timestampFormat
		  timeZone: nil locale: nil];
		formatlen = [aFmt length];
		format = AUTORELEASE(([[NSAttributedString alloc] 
		  initWithString: aFmt attributes: 
		  [NSDictionary dictionaryWithObjectsAndKeys:
		    [NSNull null], @"TimestampFormat", nil]]));
	}

	textStorage = [chatView textStorage];
	if ([textStorage length] == 0 || [[textStorage string] hasSuffix: @"\n"])
	{
		handleFirst = YES;
	}
	else
	{
		handleFirst = NO;
	}
	thisRange.location = 0;
	thisRange.length = 1;
	
	while (1)
	{
		string = [mutString string];
		if (!handleFirst)
		{
			thisRange = [string rangeOfString: @"\n" options: 0
			  range: allRange];
			if (thisRange.location == NSNotFound) break;
			thisRange.location += 1;
		}
		else
		{
			handleFirst = NO;
		}
		allRange.location += thisRange.location;
		allRange.length -= thisRange.location;
		if (allRange.length == 0) break;
		
		[mutString addAttribute: @"Timestamp" value: date range: 
		  NSMakeRange(allRange.location, 1)];
		if (format && formatlen) 
		{
			[mutString insertAttributedString: format atIndex:
			  allRange.location];
			allRange.location += formatlen;
		}
		numLines++;
	}
	
	textStorage = [chatView textStorage];
	[textStorage beginEditing];
	[textStorage appendAttributedString: mutString];
	[textStorage endEditing];
	RELEASE(mutString);

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
	timestampEnabled = [GeneralPreferencesController timestampEnabled];

	[self timestampFormatChanged: nil];
}
- (void)timestampFormatChanged: (NSNotification *)aNotification
{
	NSRange curRange;
	NSRange allRange;
	NSTextStorage *textStorage;
	NSString *string = nil;
	unsigned len;
	NSRange lastRange;
	NSDictionary *lastAttributes = nil;
	NSDictionary *thisAttributes;
	NSDate *date;
	NSDate *lastDate = nil;
	NSAttributedString *lastFmt = nil;
	unsigned lastFmtLength;

	RELEASE(timestampFormat);
	timestampFormat = RETAIN([_PREFS_ preferenceForKey: GNUstepOutputTimestampFormat]);
	
	textStorage = [chatView textStorage];
	string = [textStorage string];
	len = [string length];
	if (!len) return;

	allRange = NSMakeRange(0, len);

	thisAttributes = [textStorage attributesAtIndex: 0
	  longestEffectiveRange: &curRange inRange: allRange];
	lastRange = curRange;
	while (1) 
	{
		if ((date = [thisAttributes objectForKey: @"Timestamp"]))
		{
			[textStorage beginEditing];
			if (lastAttributes && [lastAttributes objectForKey: @"TimestampFormat"])
			{
				[textStorage deleteCharactersInRange: lastRange];
				curRange.location -= lastRange.length;
				len -= lastRange.length;
			}

			if (timestampEnabled) 
			{
				if (![lastDate isEqual: date])
				{
					NSString *aFmt;
					aFmt = [date descriptionWithCalendarFormat: timestampFormat
					  timeZone: nil locale: nil];
					lastFmt = AUTORELEASE(([[NSAttributedString alloc] 
					  initWithString: aFmt attributes: 
					  [NSDictionary dictionaryWithObjectsAndKeys:
						[NSNull null], @"TimestampFormat", nil]]));
					lastFmtLength = [[lastFmt string] length];
				}
				lastDate = date;
				[textStorage insertAttributedString: lastFmt
				  atIndex: curRange.location];
				curRange.location += lastFmtLength;
				len += lastFmtLength;
			}
			[textStorage endEditing];
		}
		if ((curRange.location + curRange.length) >= len) break;
		lastAttributes = thisAttributes;
		lastRange = curRange;
		allRange.length = len;
		thisAttributes = [textStorage attributesAtIndex: (curRange.location + curRange.length)
		  longestEffectiveRange: &curRange inRange: allRange];
	}
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
	[[chatView textStorage]
	  updateAttributedStringForGNUstepOutputPreferences: 
	  [aNotification object]];
}
- (void)scrollLinesChanged: (NSNotification *)aNotification
{
	scrollLines = [[_PREFS_ preferenceForKey: GNUstepOutputBufferLines]
	  intValue];
}
@end
