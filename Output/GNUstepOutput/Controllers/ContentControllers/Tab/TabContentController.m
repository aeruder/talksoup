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

#include "ContentController.h"

#include "Controllers/QueryController.h"
#include "Controllers/ChannelController.h"
#include "Controllers/InputController.h"
#include "Views/AttributedTabViewItem.h"
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSTabView.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSTabViewItem.h>
#include <Foundation/NSString.h>

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

	return self;
}	
- (void)awakeFromNib
{
	while ([tabView numberOfTabViewItems] > 0)
	{
		[tabView removeTabViewItem: [tabView tabViewItemAtIndex: 0]];
	}
	
	inputController = [[InputController alloc] initWithContentController: self];
	
	[typeView setTarget: inputController];
	[typeView setAction: @selector(enterPressed:)];
	
	[tabView setDelegate: self];
	
	[self addQueryWithName: ContentConsoleName withLabel: AUTORELEASE([[NSAttributedString alloc] initWithString: 
	  _l(@"Unconnected")])];
	
	[window makeKeyAndOrderFront: nil];
}
- (void)dealloc
{
	NSFreeMapTable(bothToName);
	NSFreeMapTable(tabItemToName);

	[tabView setDelegate: nil];
	[typeView setTarget: nil];
	RELEASE(inputController);
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
	RELEASE(inputController);
	
	[super dealloc];
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
- putMessage: (id)aString in: (id)aChannel
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
	
	if (controller == nil)
	{
		controller = [nameToBoth objectForKey: current];
	}
	
	if ([aString isKindOf: [NSString class]])
	{
		
		[[[controller chatView] textStorage] appendAttributedString:
		  AUTORELEASE([[NSAttributedString alloc] initWithString: aString])];
	}
	else if ([aString isKindOf: [NSAttributedString class]])
	{
		[[[controller chatView] textStorage] appendAttributedString: aString];
	}

	return self;
}
- putMessageInAll: (id)aString
{
	NSEnumerator *iter;
	id object;

	iter = [nameToBoth keyEnumerator];

	while ((object = [iter nextObject]))
	{
		[self putMessage: aString in: object];
	}

	return self;
}
- addQueryWithName: (NSString *)aName withLabel: (NSAttributedString *)aLabel
{
	id query;
	id name;
	id tabItem;

	name = GNUstepOutputLowercase(aName);
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

	return self;
}
- addChannelWithName: (NSString *)aName withLabel: (NSAttributedString *)aLabel
{
	id chan;
	id name;
	id tabItem;

	name = GNUstepOutputLowercase(aName);
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
	
	[tabItem setView: [[chan window] contentView]];
	
	[tabView addTabViewItem: tabItem];
	
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
	return self;
}
- (NSString *)currentViewName
{
	return [nameToPresentation objectForKey: current];
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
