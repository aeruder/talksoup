/***************************************************************************
                                ContentController.m
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

#include "Controllers/ContentController.h"

#include "Controllers/QueryController.h"
#include "Controllers/ChannelController.h"
#include "Controllers/InputController.h"
#include "Controllers/ConnectionController.h"
#include "Views/AttributedTabViewItem.h"
#include "Views/ScrollingTextView.h"
#include "Misc/NSColorAdditions.h"
#include "Misc/NSAttributedStringAdditions.h"
#include <AppKit/NSColor.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSTabView.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSTabViewItem.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSTableView.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSNull.h>
#include <Foundation/NSEnumerator.h>

#include "GNUstepOutput.h"

NSString *ContentConsoleName = @"Content Console Name";

static void clear_scrollback(NSMutableAttributedString *back)
{
	int length = [[_GS_ defaultsObjectForKey: GNUstepOutputScrollBack] intValue];
	int max = [back length];
	int beginning;
	NSRange aRange;
	
	if ((beginning = max - length) < 0) return;
	
	aRange = [[back string] rangeOfString: @"\n" options: 0 range: 
	  NSMakeRange(beginning, max - beginning)];
	
	if (aRange.location == NSNotFound) return;
	
	[[back mutableString] deleteCharactersInRange: 
	  NSMakeRange(0, (aRange.location + aRange.length))];	
}

@interface ContentController (TextViewDelegate)
- (BOOL)tabsTextViewPressedKey: (NSEvent *)aEvent sender: textView;
@end

@interface ContentController (WindowTabViewDelegate)
- (void)tabView: (NSTabView *)aTabView
  didSelectTabViewItem: (NSTabViewItem *)tabViewItem;
@end

@implementation ContentController
- initWithConnectionController: (ConnectionController *)aConnection
{
	if (!(self = [super init])) return nil;

	nameToChannel = [NSMutableDictionary new];
	nameToQuery = [NSMutableDictionary new];
	nameToBoth = [NSMutableDictionary new];
	nameToPresentation = [NSMutableDictionary new];
	nameToLabel = [NSMutableDictionary new];
	nameToTabItem = [NSMutableDictionary new];
	
	bothToName = NSCreateMapTable(NSObjectMapKeyCallBacks,
	  NSObjectMapValueCallBacks, 10);
	tabItemToName = NSCreateMapTable(NSObjectMapKeyCallBacks,
	  NSObjectMapValueCallBacks, 10);
	
	highlightedTabs = [NSMutableArray new];
	
	connection = aConnection;
	
	return self;
}	
- (void)awakeFromNib
{
	id font;

	while ([tabView numberOfTabViewItems] > 0)
	{
		[tabView removeTabViewItem: [tabView tabViewItemAtIndex: 0]];
	}
	
	[nickView setFont: [NSFont userFontOfSize: 12.0]];
	[tabView setFont: [NSFont systemFontOfSize: 12.0]];
	[tabView setDelegate: self];
	
	font = [NSFont fontWithName: [_GS_ defaultsObjectForKey: GNUstepOutputFontName]
	  size: (float)[[_GS_ defaultsObjectForKey: GNUstepOutputFontSize] intValue]];
	
	if (!font) 
		font = [NSFont userFontOfSize: (float)[[_GS_ 
		  defaultsObjectForKey: GNUstepOutputFontSize] intValue]];
		
	[self setChatFont: font];
	
	[self addQueryWithName: ContentConsoleName withLabel: AUTORELEASE([[NSAttributedString alloc] initWithString: 
	  _l(@"Unconnected")])];
	
	[tabView selectTabViewItemAtIndex: 0];
	
	[window makeKeyAndOrderFront: nil];
}
- (void)dealloc
{
	NSFreeMapTable(bothToName);
	NSFreeMapTable(tabItemToName);

	[tabView setDelegate: nil];
	[typeView setTarget: nil];
	RELEASE(highlightedTabs);
	RELEASE(typeView);
	RELEASE(nickView);
	RELEASE(tabView);
	RELEASE(window);
	RELEASE(nameToChannel);
	RELEASE(nameToQuery);
	RELEASE(nameToBoth);
	RELEASE(nameToPresentation);
	RELEASE(nameToLabel);
	RELEASE(nameToTabItem);
	RELEASE(current);
	RELEASE(chatFont);
	
	[super dealloc];
}
- updatedColor: (NSString *)aKey old: (NSString *)old
{
	NSEnumerator *iter;
	id object;
	id color;
	
	if ([[self colorForKey: aKey] isEqual: 
	  [NSColor colorFromEncodedData: old]]) return self;
  
	iter = [[nameToBoth allValues] objectEnumerator];

	color = [self colorForKey: aKey];
	
	while ((object = [iter nextObject]))
	{
		object = [object chatView];
		[[object textStorage] 
		 setAttribute: NSForegroundColorAttributeName
		  toValue: color
		 inRangesWithAttribute: TypeOfColor
		  matchingValue: aKey
		 withRange: NSMakeRange(0, [[object textStorage] length])];
		if ([aKey isEqualToString: GNUstepOutputBackgroundColor])
		{
			[object setBackgroundColor: color];
			[[object textStorage] fixInverseWithBackgroundColor: color withOldBackgroundColor: 
			  [NSColor colorFromEncodedData: old] withForegroundColor: 
			  [self colorForKey: GNUstepOutputTextColor] withOldForegroundColor: 
			  [self colorForKey: GNUstepOutputTextColor]];
		}
		else if ([aKey isEqualToString: GNUstepOutputTextColor])
		{
			[[object textStorage] fixInverseWithBackgroundColor: 
			  [self colorForKey: GNUstepOutputBackgroundColor] 
			  withOldBackgroundColor: [self colorForKey: GNUstepOutputBackgroundColor]			  
			  withForegroundColor: color withOldForegroundColor:
			  [NSColor colorFromEncodedData: old]];
		}
	}

	return self;
}
- (NSColor *)colorForKey: (NSString *)aKey
{
	return [NSColor colorFromEncodedData: [_GS_ defaultsObjectForKey:
	  aKey]];
}
- highlightTabWithName: (NSString *)aName withColor: (NSString *)aColorName
   withPriority: (BOOL)prior
{
	NSString *lo = GNUstepOutputLowercase(aName);
	id tab = [nameToTabItem objectForKey: lo];
	id aColor;
		
	if ([lo isEqualToString: current]) return self;
	if ([highlightedTabs containsObject: lo] && !prior) return self;
	
	aColor = [NSColor colorFromIRCString: aColorName];
	
	if (aColor)
	{
		[tab setLabelColor: aColor];
		if (![highlightedTabs containsObject: lo])
		{
			[highlightedTabs addObject: lo];
		}
	}
	else
	{
		[tab setLabelColor: nil];
		[highlightedTabs removeObject: lo];
	}

	return self;
}
- (NSArray *)allViews
{
	return [nameToBoth allValues];
}
- (NSArray *)allChannelNames
{
	NSMutableArray *x = AUTORELEASE([NSMutableArray new]);
	NSEnumerator *iter;
	id object;
	
	iter = [nameToChannel keyEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[x addObject: [nameToPresentation objectForKey: object]];
	}
	
	return x;
}
- (NSArray *)allQueryNames;
{
	NSMutableArray *x = AUTORELEASE([NSMutableArray new]);
	NSEnumerator *iter;
	id object;
	
	iter = [nameToQuery keyEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[x addObject: [nameToPresentation objectForKey: object]];
	}
	
	return x;
}
- (BOOL)isQueryName: (NSString *)aName
{
	if ([nameToQuery objectForKey: GNUstepOutputLowercase(aName)])
	{
		return YES;
	}

	return NO;
}		
- (BOOL)isChannelName: (NSString *)aName
{
	if ([nameToChannel objectForKey: GNUstepOutputLowercase(aName)])
	{
		return YES;
	}
	
	return NO;
}
- (NSTextField *)typeView
{
	return typeView;
}
- (NSTextField *)nickView
{
	return nickView;
}
- (NSTabView *)tabView
{
	return tabView;
}
- (NSWindow *)window
{
	return window;
}
- (NSAttributedString *)labelForViewWithName: (NSString *)aChannel
{
	return [nameToLabel objectForKey: GNUstepOutputLowercase(aChannel)];
}
- (NSString *)presentationNameForViewWithName: (NSString *)aChannel
{
	return [nameToPresentation objectForKey: GNUstepOutputLowercase(aChannel)];
}
- (id)controllerForViewWithName: (NSString *)aChannel
{
	return [nameToBoth objectForKey: GNUstepOutputLowercase(aChannel)];
}
- (NSTabViewItem *)tabViewItemForViewWithName: (NSString *)aChannel
{
	return [nameToTabItem objectForKey: GNUstepOutputLowercase(aChannel)];
}
- (NSString *)viewNameForController: controller
{
	id a = NSMapGet(bothToName, controller);
	if (a)
	{
		return [nameToPresentation objectForKey: a];
	}
	
	return nil;
}
- (NSString *)viewNameForTabViewItem: (NSTabViewItem *)aItem
{
	id a = NSMapGet(tabItemToName, aItem);
	if (a)
	{
		return [nameToPresentation objectForKey: a];
	}
	
	return nil;
}
- putMessage: (id)aString in: (id)aChannel withEndLine: (BOOL)aBool
{
	id controller = nil;
	id string;
	NSRange aRange;
	
	if (!aString) return self;
	
	if ([aChannel isKindOfClass: [ChannelController class]]
	    || [aChannel isKindOfClass: [QueryController class]])
	{
		controller = aChannel;
	}
	else if ([aChannel isKindOfClass: [NSString class]])
	{
		controller = [nameToBoth objectForKey: GNUstepOutputLowercase(aChannel)];
	}
	else if ([aChannel isKindOfClass: [NSAttributedString class]])
	{
		controller = [nameToBoth objectForKey: 
		    GNUstepOutputLowercase([aChannel string])];
	}
	else if ([aChannel isKindOfClass: [NSArray class]])
	{
		NSEnumerator *iter;
		id object;
		
		iter = [aChannel objectEnumerator];
		while ((object = [iter nextObject]))
		{
			[self putMessage: aString in: object withEndLine: aBool];
		}
		return self;
	}
	
	if (controller == nil)
	{
		controller = [nameToBoth objectForKey: current];
	}

	controller = [[controller chatView] textStorage];	
	
	if ([aString isKindOfClass: [NSAttributedString class]])
	{
		aRange = NSMakeRange(0, [aString length]);
		string = [aString substituteColorCodesIntoAttributedStringWithFont: chatFont];
		[string setAttribute: NSForegroundColorAttributeName toValue:
		  [self colorForKey: GNUstepOutputBackgroundColor]
		  inRangesWithAttributes: [NSArray arrayWithObjects: NSForegroundColorAttributeName,
		    IRCReverse, nil] matchingValues: [NSArray arrayWithObjects: [NSNull null], 
		    IRCReverseValue, nil] withRange: aRange];
		[string setAttribute: NSBackgroundColorAttributeName toValue:
		  [self colorForKey: GNUstepOutputTextColor]
		  inRangesWithAttributes: [NSArray arrayWithObjects: NSBackgroundColorAttributeName,
		    IRCReverse, nil] matchingValues: [NSArray arrayWithObjects: [NSNull null], 
		    IRCReverseValue, nil] withRange: aRange];		
		[string setAttribute: TypeOfColor toValue: GNUstepOutputTextColor
		  inRangesWithAttributes: 
		    [NSArray arrayWithObjects: NSForegroundColorAttributeName,
		      TypeOfColor, nil]
		  matchingValues: 
		    [NSArray arrayWithObjects: [NSNull null], [NSNull null], nil]
		  withRange: aRange];
		[string setAttribute: NSForegroundColorAttributeName
		  toValue: [self colorForKey: GNUstepOutputTextColor]
		 inRangesWithAttribute: TypeOfColor
		  matchingValue: GNUstepOutputTextColor
		 withRange: aRange];
		[string setAttribute: NSForegroundColorAttributeName
		  toValue: [self colorForKey: GNUstepOutputOtherBracketColor]
		 inRangesWithAttribute: TypeOfColor
		  matchingValue: GNUstepOutputOtherBracketColor
		 withRange: aRange];
		[string setAttribute: NSForegroundColorAttributeName
		  toValue: [self colorForKey: GNUstepOutputPersonalBracketColor]
		 inRangesWithAttribute: TypeOfColor
		  matchingValue: GNUstepOutputPersonalBracketColor
		 withRange: aRange];
	}
	else
	{
		aRange = NSMakeRange(0, [[aString description] length]);
		string = AUTORELEASE(([[NSMutableAttributedString alloc] 
		  initWithString: [aString description]
		  attributes: [NSDictionary dictionaryWithObjectsAndKeys:
			 chatFont, NSFontAttributeName,
			 TypeOfColor, GNUstepOutputTextColor,
			 [self colorForKey: GNUstepOutputTextColor], NSForegroundColorAttributeName,
		     nil]]));
	}
	
	[controller appendAttributedString: string];
	
	if (aBool)
	{
		[controller appendAttributedString: AUTORELEASE(([[NSAttributedString alloc]
		  initWithString: @"\n" attributes: [NSDictionary dictionaryWithObjectsAndKeys:
		  chatFont, NSFontAttributeName, nil]]))];
	}
	
	clear_scrollback(controller);

	return self;
}
- putMessage: (id)aString in: (id)aChannel
{
	return [self putMessage: aString in: aChannel withEndLine: YES];
}
- putMessageInAll: (id)aString withEndLine: (BOOL)aBool
{
	[self putMessage: aString in: [nameToBoth allKeys] withEndLine: aBool];
	return self;
}
- putMessageInAll: (id)aString
{
	[self putMessage: aString in: [nameToBoth allKeys] withEndLine: YES];
	return self;
}
- addQueryWithName: (NSString *)aName withLabel: (NSAttributedString *)aLabel
{
	id query;
	id name;
	id tabItem;

	name = GNUstepOutputLowercase(aName);

	if ([nameToBoth objectForKey: name])
	{
		[self setLabel: aLabel forViewWithName: name];
		[tabView selectTabViewItem: [nameToTabItem objectForKey: name]];
		return nil;
	}

	query = AUTORELEASE([QueryController new]);
	
	if (![NSBundle loadNibNamed: @"Query" owner: query])
	{
		return nil;
	}

	[nameToQuery setObject: query forKey: name];
	[nameToBoth setObject: query forKey: name];
	[nameToPresentation setObject: aName forKey: name];
	[nameToLabel setObject: aLabel forKey: name];

	NSMapInsert(bothToName, query, name);

	tabItem = AUTORELEASE([AttributedTabViewItem new]);

	[nameToTabItem setObject: tabItem forKey: name];
	
	NSMapInsert(tabItemToName, tabItem, name);

	[tabItem setView: [query contentView]];

	[tabView addTabViewItem: tabItem];

	[tabItem setAttributedLabel: aLabel];
	
	name = [tabView selectedTabViewItem];
	
	[tabView selectTabViewItem: tabItem];
	[tabView selectTabViewItem: name];

	[tabView setNeedsDisplay: YES];

	[[query chatView] setFont: chatFont];
	[[query chatView] setKeyAction: @selector(tabsTextViewPressedKey:sender:)];
	[[query chatView] setKeyTarget: self];

	return self;
}
- addChannelWithName: (NSString *)aName withLabel: (NSAttributedString *)aLabel
{
	id chan;
	id name;
	id tabItem;

	name = GNUstepOutputLowercase(aName);
	
	if ([nameToBoth objectForKey: name])
	{
		[self setLabel: aLabel forViewWithName: name];
		[tabView selectTabViewItem: [nameToTabItem objectForKey: name]];
		return nil;
	}
	
	chan = AUTORELEASE([ChannelController new]);

	if (![NSBundle loadNibNamed: @"Channel" owner: chan])
	{
		return nil;
	}

	[nameToChannel setObject: chan forKey: name];
	[nameToBoth setObject: chan forKey: name];
	[nameToPresentation setObject: aName forKey: name];
	[nameToLabel setObject: aLabel forKey: name];

	NSMapInsert(bothToName, chan, name);

	tabItem = AUTORELEASE([AttributedTabViewItem new]);

	[nameToTabItem setObject: tabItem forKey: name];

	NSMapInsert(tabItemToName, tabItem, name);
	
	[tabItem setView: [chan contentView]];
	
	name = [tabView selectedTabViewItem];
	
	[tabView addTabViewItem: tabItem];

	[tabItem setAttributedLabel: aLabel];
	
	name = [tabView selectedTabViewItem];
	
	[tabView selectTabViewItem: tabItem];
	[tabView selectTabViewItem: name];
	
	[tabView setNeedsDisplay: YES];
	
	[[chan chatView] setFont: chatFont];
	[[chan chatView] setKeyAction: @selector(tabsTextViewPressedKey:sender:)];
	[[chan chatView] setKeyTarget: self];
	
	return self;
}
- setLabel: (NSAttributedString *)aString forViewWithName: (NSString *)aName
{
	id tab;
	
	tab = [nameToTabItem objectForKey: GNUstepOutputLowercase(aName)];
	
	if (!(tab))
	{
		return nil;
	}
	
	[tab setAttributedLabel: aString];
	
	return self;
}
- closeViewWithName: (NSString *)aName
{
	id lo = GNUstepOutputLowercase(aName);
	id view;
	id tab;
	
	view = [nameToBoth objectForKey: lo];
	if (!view)
	{
		return self;
	}
	
	if ([view respondsToSelector: @selector(tableView)])
	{
		[[view tableView] setDataSource: nil];
		[[view tableView] setTarget: nil];
	}

	tab = [nameToTabItem objectForKey: lo];

	if ([tabView selectedTabViewItem] == tab)
	{
		[tabView selectPreviousTabViewItem: nil];
	}
	
	[tabView removeTabViewItem: tab];
		
	[nameToChannel removeObjectForKey: lo];
	[nameToQuery removeObjectForKey: lo];
	[nameToBoth removeObjectForKey: lo];
	[nameToPresentation removeObjectForKey: lo];
	[nameToLabel removeObjectForKey: lo];
	[nameToTabItem removeObjectForKey: lo];
	
	NSMapRemove(tabItemToName, tab);
	NSMapRemove(bothToName, view);
	
	[tabView setNeedsDisplay: YES];

	return self;
}
- renameViewWithName: (NSString *)aName to: (NSString *)newName
{
	id lowName = GNUstepOutputLowercase(aName);
	id lowNewName = GNUstepOutputLowercase(newName);
	
	if (![nameToBoth objectForKey: lowName]) return self;
	
	if (GNUstepOutputCompare(lowName, lowNewName))
	{
		if (![[nameToPresentation objectForKey: lowName] 
		  isEqualToString: newName])
		{
			[nameToPresentation setObject: newName forKey: lowNewName];
		}
		return self;
	}
	else
	{
		id object;
		id which;
		
		[nameToPresentation setObject: newName forKey: lowNewName];
		[nameToPresentation removeObjectForKey: lowName];
		
		object = [nameToBoth objectForKey: lowName];
		which = ([object isKindOfClass: [QueryController class]]) ? 
		  nameToQuery : nameToChannel;
		
		[nameToBoth setObject: object forKey: lowNewName];
		[which setObject: object forKey: lowNewName];
		
		[nameToBoth removeObjectForKey: lowName];
		[which removeObjectForKey: lowName];
		NSMapInsert(bothToName, object, lowNewName);
		
		[nameToLabel setObject: [nameToLabel objectForKey:
		  lowName] forKey: lowNewName];
		[nameToLabel removeObjectForKey: lowName];
		
		object = [nameToTabItem objectForKey: lowName];
		[nameToTabItem setObject: object forKey: lowNewName];
		[nameToTabItem removeObjectForKey: lowName];
		NSMapInsert(tabItemToName, object, lowNewName);
		
		if (GNUstepOutputCompare(current, lowName))
		{
			RELEASE(current);
			current = RETAIN(lowNewName);
		}
		
		return self;
	}
	return self;	
}
- focusViewWithName: (NSString *)aName
{
	id tabItem = [nameToTabItem
	 objectForKey: GNUstepOutputLowercase(aName)];

	if (tabItem)
	{
		[tabView selectTabViewItem: tabItem];
	}

	return self;
}
- (NSString *)currentViewName
{
	return [nameToPresentation objectForKey: current];
}
- setNickViewString: (NSString *)aString
{
	NSRect nick;
	NSRect type;

	[nickView setStringValue: aString];
	[nickView sizeToFit];
	
	nick = [nickView frame];
	nick.origin.y = 8;

	type = [typeView frame];
	type.origin.y = 4;
	type.origin.x = NSMaxX(nick) + 4;
	type.size.width = [[window contentView] frame].size.width - 4 - type.origin.x;
	
	[nickView setFrame: nick];
	[typeView setFrame: type];
	
	[[window contentView] setNeedsDisplay: YES];

	return self;
}
- setChatFont: (NSFont *)aFont
{	
	NSEnumerator *iter;
	id object;
	
	if (!aFont) return self;
	if ([aFont isEqual: chatFont]) return self;
	
	iter = [[nameToBoth allValues] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		object = [[object chatView] textStorage];
		[object replaceAttribute: NSFontAttributeName 
		  withValue: chatFont withValue: aFont withRange:
		  NSMakeRange(0, [object length])];
	}

	RELEASE(chatFont);
	chatFont = RETAIN(aFont);	
	
	aFont = [NSFont fontWithName: [chatFont fontName] size: 12.0];
	
	if (!aFont)
	{
		aFont = [NSFont userFontOfSize: 12.0];
	}
	
	[typeView setFont: aFont];
	
	return self;
}	
- (NSFont *)chatFont
{
	return chatFont;
}
@end

@implementation ContentController (WindowTabViewDelegate)
- (void)tabView: (NSTabView *)aTabView
  didSelectTabViewItem: (NSTabViewItem *)tabViewItem
{
	id name;
	
	name = NSMapGet(tabItemToName, tabViewItem);
	
	if (name == nil || tabView != aTabView)
	{
		NSLog(@"Got a message from the wrong tab view or tab view item isn't there...");
		return;
	}

	if ([highlightedTabs containsObject: name])
	{
		[(AttributedTabViewItem *)tabViewItem setLabelColor: nil];
		[highlightedTabs removeObject: name];
	}
	
	RELEASE(current);	
	current = RETAIN(name);
	[window makeFirstResponder: typeView];
	
	if ([connection respondsToSelector: _cmd])
	{
		[connection performSelector: _cmd withObject: aTabView
		  withObject: tabViewItem];
	}	
}
@end

@implementation ContentController (TextViewDelegate)
- (BOOL)tabsTextViewPressedKey: (NSEvent *)aEvent sender: textView
{
	id fe;
	[window makeFirstResponder: typeView];
	
	fe = [window fieldEditor: NO forObject: typeView];
	[fe setSelectedRange: NSMakeRange([[fe textStorage] length], 0)]; 
	[fe keyDown: aEvent];
	
	return NO;
}
@end
