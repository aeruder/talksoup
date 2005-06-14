/***************************************************************************
                      StandardChannelController.m
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

#import "Controllers/Preferences/ColorPreferencesController.h"
#import "Controllers/Preferences/FontPreferencesController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "Controllers/Preferences/GeneralPreferencesController.h"
#import "Controllers/ContentControllers/StandardChannelController.h"
#import "Views/ScrollingTextView.h"
#import "Misc/NSColorAdditions.h"
#import "Misc/NSAttributedStringAdditions.h"
#import "Models/Channel.h"
#import "GNUstepOutput.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <AppKit/NSFont.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSSplitView.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDebug.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSColor.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>

@interface StandardChannelController (PreferencesCenter)
- (void)colorChanged: (NSNotification *)aNotification;
- (void)userListFontChanged: (NSNotification *)aNotification;
- (void)chatFontChanged: (NSNotification *)aNotification;
- (void)wrapIndentChanged: (NSNotification *)aNotification;
- (void)scrollLinesChanged: (NSNotification *)aNotification;
@end

@interface StandardChannelController (DelegateMethods)
- (void)splitView: (NSSplitView *)sender
    resizeSubviewsWithOldSize: (NSSize)oldSize;
- (void)doubleClickedTableView: (NSTableView *)sender;
@end

@implementation StandardChannelController
+ (NSString *)standardNib
{
	return @"StandardChannel";
}
- init
{
	if (!(self = [super init])) return self;

	if (!([NSBundle loadNibNamed: [StandardChannelController standardNib] owner: self]))
	{
		NSLog(@"Failed to load StandardChannelController UI");
		[self dealloc];
		return nil;
	}

	return self;
}
- (void)awakeFromNib
{
	id x;
	id userColumn;
	id userScroll;
	id font;
	NSRect frame;
	
	[splitView setVertical: YES];

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

	userColumn = AUTORELEASE([[NSTableColumn alloc] 
	  initWithIdentifier: @"User List"]);
	
	[userColumn setEditable: NO];
	
	frame = [tableView frame];
	AUTORELEASE(RETAIN(tableView));
	[tableView removeFromSuperview];
	
	userScroll = AUTORELEASE([[NSScrollView alloc] initWithFrame: frame]); 
	tableView = AUTORELEASE([[NSTableView alloc] initWithFrame: 
	  NSMakeRect(0, 0, frame.size.width, frame.size.height)]);

	[tableView setCornerView: nil];
	[tableView setHeaderView: nil];
	[tableView setTarget: self];
	[tableView setDoubleAction: @selector(doubleClickedTableView:)];

	[tableView addTableColumn: userColumn];
	[tableView setDrawsGrid: NO];
	
	[userScroll setDocumentView: tableView];
	[userScroll setHasHorizontalScroller: NO];
	[userScroll setHasVerticalScroller: YES];
	[userScroll setBorderType: NSBezelBorder];
	
	x = AUTORELEASE([[NSCell alloc] initTextCell: @""]);
	[x setFormatter: AUTORELEASE([ChannelFormatter new])];
	
	font = [FontPreferencesController getFontFromPreferences:
	  GNUstepOutputUserListFont];
	[x setFont: font];
	[tableView setRowHeight: [font pointSize] * 1.5];
	
	[userColumn setDataCell: x];
	
	[chatView setBackgroundColor: [NSColor colorFromEncodedData:
	  [_PREFS_ preferenceForKey: GNUstepOutputBackgroundColor]]];
	[chatView setTextColor: [NSColor colorFromEncodedData:
	  [_PREFS_ preferenceForKey: GNUstepOutputTextColor]]];
	 
	[splitView addSubview: userScroll];
	[splitView setDelegate: self];
	
	frame = [userScroll frame];
	frame.size.width = 120;
	[userScroll setFrame: frame];
	[self splitView: splitView resizeSubviewsWithOldSize:
	  [splitView frame].size];

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
	  selector: @selector(userListFontChanged:)
	  name: DefaultsChangedNotification
	  object: GNUstepOutputUserListFont];

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
	[tableView setTarget: nil];
	[splitView setDelegate: nil];
	[tableView setDoubleAction: NULL];
	DESTROY(channelSource);
	RELEASE(window);
	[super dealloc];
}
- (Channel *)channelSource
{
	return channelSource;
}
- (void)attachChannelSource: (Channel *)aChannel
{
	[tableView setDataSource: nil];
	ASSIGN(channelSource, aChannel);
	[tableView setDataSource: channelSource];
}
- (void)detachChannelSource
{
	[tableView setDataSource: nil];
	DESTROY(channelSource);
}
- (void)refreshFromChannelSource
{
	[tableView reloadData];
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

	textStorage = [chatView textStorage];
	[textStorage appendAttributedString: aString];
	numLines += [[[aString string] 
	  componentsSeparatedByString: @"\n"] count] - 1;

	if (numLines > scrollLines)
	{
		[textStorage chopNumberOfLines: numLines - scrollLines];
		numLines = scrollLines;
	}
}
@end

@implementation StandardChannelController (PreferencesCenter)
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
- (void)userListFontChanged: (NSNotification *)aNotification
{
	NSTableColumn *column;
	NSFont *aFont;
	NSCell *aCell;
	
	aFont = 
	  [FontPreferencesController getFontFromPreferences: 
	  GNUstepOutputUserListFont];
	column = [[tableView tableColumns] objectAtIndex: 0];
	aCell = [column dataCell];
	if (aFont)
	{
		[aCell setFont: aFont];
	}

	[tableView setRowHeight: [aFont pointSize] * 1.5];
	[tableView setNeedsDisplay: YES];
	[tableView reloadData];
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

@implementation StandardChannelController (DelegateMethods)
- (void)splitView: (NSSplitView *)sender
    resizeSubviewsWithOldSize: (NSSize)oldSize
{
	id tableScroll = [tableView enclosingScrollView];
	id chatScroll = [chatView enclosingScrollView];
	NSRect frame1;  // talkScroll
	NSRect frame2 = [tableScroll frame];
	NSRect frame3 = [splitView frame];

	if ((frame3.size.width - [sender dividerThickness]) > frame2.size.width)
	{
		// Width of this view is constant(assuming it fits)
		frame2.origin.x = frame3.size.width - frame2.size.width;
		frame2.origin.y = 0;
		frame2.size.height = frame3.size.height;

		frame1.origin.x = 0;
		frame1.origin.y = 0;
		frame1.size.width = frame2.origin.x - [sender dividerThickness];
		frame1.size.height = frame3.size.height;
	}
	else
	{
		frame1.origin.x = 0;
		frame1.origin.y = 0;
		frame1.size.width = 0;
		frame1.size.height = frame3.size.height;

		frame2.origin.x = 0;
		frame2.origin.y = 0;
		frame2.size.width = frame3.size.width;
		frame2.size.height = frame3.size.height;
	}
	[tableScroll setFrame: frame2];
	[chatScroll setFrame: frame1];
}
- (void)doubleClickedTableView: (NSTableView *)sender
{
	NSArray *userList;
	ChannelUser *chanUser;
	
	userList = [channelSource userList];
	if ([sender clickedRow] >= [userList count]) return;
	chanUser = [userList objectAtIndex: [sender clickedRow]];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ChannelControllerUserOpenedNotification
	 object: self userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
	  channelSource, @"Channel",
	  chanUser, @"User",
	  self, @"View",
	  nil]];
}
@end

