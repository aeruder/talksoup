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
#include "Views/AttributedTabViewItem.h"
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
#include <AppKit/NSTextView.h>
#include <AppKit/NSTableView.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSArray.h>

#include "GNUstepOutput.h"

NSString *ContentConsoleName = @"Content Console Name";

@interface ContentController (WindowTabViewDelegate)
- (void)tabView: (NSTabView *)aTabView
  didSelectTabViewItem: (NSTabViewItem *)tabViewItem;
@end

@implementation ContentController
- init
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
	
	textColor = RETAIN([NSColor colorFromEncodedData: 
	  [[_TS_ output] defaultsObjectForKey: GNUstepOutputTextColor]]);
	
	return self;
}	
- (void)awakeFromNib
{
	while ([tabView numberOfTabViewItems] > 0)
	{
		[tabView removeTabViewItem: [tabView tabViewItemAtIndex: 0]];
	}
	
	[tabView setDelegate: self];
	
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
	RELEASE(textColor);
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
	
	[super dealloc];
}
- setTextColor: (NSColor *)aColor
{
	if (![aColor isEqual: textColor])
	{
		NSEnumerator *iter;
		id object;

		iter = [[nameToBoth allValues] objectEnumerator];
		while ((object = [iter nextObject]))
		{
			object = [[object chatView] textStorage];
			[object replaceAttribute: NSForegroundColorAttributeName 
			  withValue: textColor withValue: aColor withRange:
			  NSMakeRange(0, [object length])];
		}
		
		RELEASE(textColor);
		textColor = RETAIN(aColor);
	
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
	
	if ([aChannel isKindOf: [ChannelController class]]
	    || [aChannel isKindOf: [QueryController class]])
	{
		controller = aChannel;
	}
	else if ([aChannel isKindOf: [NSString class]])
	{
		controller = [nameToBoth objectForKey: GNUstepOutputLowercase(aChannel)];
	}
	else if ([aChannel isKindOf: [NSAttributedString class]])
	{
		controller = [nameToBoth objectForKey: 
		    GNUstepOutputLowercase([aChannel string])];
	}
	else if ([aChannel isKindOf: [NSArray class]])
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
	
	if ([aString isKindOf: [NSString class]])
	{
		NSLog(@"Using %p", textColor);
		[[[controller chatView] textStorage] appendAttributedString: 
		 AUTORELEASE(([[NSAttributedString alloc] initWithString: aString
		  attributes: [NSDictionary dictionaryWithObjectsAndKeys:
		    textColor, NSForegroundColorAttributeName,
		     nil]]))];
	}
	else if ([aString isKindOf: [NSAttributedString class]])
	{
		aString = [aString substituteColorCodesIntoAttributedString];
	   
		[aString addAttributeIfNotPresent: NSForegroundColorAttributeName value: textColor
		  withRange: NSMakeRange(0, [aString length])];
		[[[controller chatView] textStorage] appendAttributedString: aString];
	}
	
	if (aBool)
	{
		[[[controller chatView] textStorage] appendAttributedString: S2AS(@"\n")];
	}

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

	[tabItem setAttributedLabel: aLabel];

	[tabItem setView: [query contentView]];

	[tabView addTabViewItem: tabItem];
	
	[tabView selectTabViewItem: tabItem];
	[tabView setNeedsDisplay: YES];

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

	[tabItem setAttributedLabel: aLabel];
	
	[tabItem setView: [chan contentView]];
	
	[tabView addTabViewItem: tabItem];
	
	[tabView selectTabViewItem: tabItem];
	[tabView setNeedsDisplay: YES];
	
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
		which = ([object isKindOf: [QueryController class]]) ? 
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

	RELEASE(current);	
	current = RETAIN(name);
	[window makeFirstResponder: typeView];
}
@end
