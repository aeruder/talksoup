/***************************************************************************
                         TabMasterController.m
                          -------------------
    begin                : Mon Jan 19 11:59:32 CST 2004
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

#import "Controllers/TabMasterController.h"
#import "Controllers/InputController.h"

#import <Foundation/NSTextField.h>
#import <Foundation/NSTabView.h>
#import <Foundation/NSTabItem.h>
#import <Foundation/NSWindow.h>
#import <Foundation/NSArray.h>

@implementation TabMasterController
- init
{
	if (!(self = [super init])) return nil;
		
	viewToTab = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 10);
	viewToContent = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 10);
	tabToView = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 10);
	contentControllers = [NSMutableArray new];
}
- (void)dealloc
{
	NSFreeMapTable(viewToTab);
	NSFreeMapTable(viewToContent);
	NSFreeMapTable(tabToView);
	DESTROY(contentControllers);
	
	[typeView setTarget: nil];
	[typeView setDelegate: nil];
	
	[nickView setTarget: nil];
	[nickView setDelegate: nil];
	
	[tabView setTarget: nil];
	[tabView setDelegate: nil];
	
	[window setDelegate: nil];
	[window close];
	DESTROY(window);
	
	[super dealloc];
}
- addView: (id <ContentControllerQueryView>)aView withLabel: (NSAttributedString *)aLabel
   forContentController: (id <ContentController>)aContentController
{
	return [self addView: aView withLabel: aLabel atIndex: numItems 
	  forContentController: aContentController];
}
- addView: (id <ContentControllerQueryView>)aView withLabel: (NSAttributedString *)aLabel
   atIndex: (int)aIndex forContentController: (id <ContentController>)aContentController
{
	NSTabItem *tabItem;
	
	tabItem = AUTORELEAE([AttributedTabItem new]);
	
	NSMapInsert(viewToTab, aView, tabItem);
	NSMapInsert(viewToContent, aView, aContentController);
	NSMapInsert(tabToView, tabItem, aView);
	
	[tabItem setView: [aView contentView]];
	[tabItem setAttributedLabel: aLabel];
	[tabView insertTabViewItem: tabItem atIndex: aIndex];
	
	[tabView setNeedsDisplay: YES];

	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ContentControllerAddedToMasterControllerNotification
	 object: aContentController userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
	  [NSNumber numberWithInt: aIndex], @"Index",
	  self, @"Master",
	  aView, @"View",
	  aContentController, @"Content",
	  nil]];

	return self;
}
- removeView: (id <ContentControllerQueryView>)aView
{
	id tab;
	int index;
	id userInfo;
	id content;

	if (!(NSMapMember(viewToTab, aView, 0, 0)))
	{
		return self;
	}
	
	tab = NSMapGet(viewToTab, aView);
	
	[tab setView: nil];
	[tabView removeTabViewItem: tab];
	
	[tabView setNeedsDisplay: YES];
	
	content = AUTORELEASE(RETAIN(NSMapGet(viewToContent, aView)));
	userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
	  self, @"Master",
	  aView, @"View",
	  NSMapGet(viewToContent, aView), @"Content",
	  nil];

	NSMapRemove(viewToTab, aView);
	NSMapRemove(viewToContent, aView);
	NSMapRemove(tabToView, tab);
	
	[NSNotificationCenter 
	 postNotificationName: ContentControllerRemovedFromMasterControllerNotification
	 object:  userInfo: userInfo];

	return self;
}
- removeViewAtIndex: (int)aIndex
{
	id aView;
	id tab;
	
	tab = [tabView tabViewItemAtIndex: aIndex];
	if (!(NSMapMember(tabToView, tab, 0, 0)))
	{
		return self;
	}
	
	aView = NSMapGet(viewToTab, aView);
	
	return [self removeView: aView];
}
- moveView: (id <ContentControllerQueryView>)aView toIndex: (int)aIndex;
{
	int index;
	id tab;
	int origIndex;
	id content;
	
	if (!(NSMapMember(viewToTab, aView, 0, 0)))
	{
		return self;
	}
	
	tab = NSMapGet(viewToTab, aView);
	
	origIndex = index = [tabView indexOfTabViewItem: tab];
	
	if (aIndex == index)
	{
		return self;
	}
	
	if (aIndex > index)
	{
		index = aIndex - 1;
	}
	else
	{
		index = aIndex;
	}
	
	[tabView removeTabViewItem: tab];
	
	[tabView insertTabViewItem: tab atIndex: index];

	content = NSMapGet(viewToContent, aView);

	[NSNotificationCenter 
	 postNotificationName: ContentControllerMovedInMasterControllerNotification
	 object: content userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
	  [NSNumber numberWithInt: origIndex], @"OldIndex",
	  [NSNumber numberWithInt: index], @"Index",
	  self, @"Master",
	  aView, @"View",
	  content, @"Content",
	  nil]];

	return self;
}
- moveViewAtIndex: (int)aIndex toIndex: (int)aNewIndex
{
	id tab;
	id aView;
	
	tab = [tabView tabViewItemAtIndex: aIndex];
	
	if (!(NSMapMember(tabToView, tab, 0, 0)))
	{
		return self;
	}
	
	aView = NSMapGet(tabToView, tab);
	
	return [self moveView: aView toIndex: aNewIndex];
}	 
- (NSArray *)containedContentControllers
{
	return [NSArray arrayWithArray: contentControllers];
}
- (NSArray *)viewListForContentController: 
    (id <ContentController>)aContentController
{
	id iter;
	id object;
	id vArray;
	id results;
	
	vArray = NSAllMapTableKeys(viewToContent);
	
	iter = [vArray objectEnumerator];
	
	results = AUTORELEASE([NSMutableArray new]);
	
	while ((object = [iter nextObject]))
	{
		if (NSMapGet(viewToContent, object) == aContentController)
		{
			[results addObject: object];
		}
	}
	
	return results;
}	
- (NSArray *)allViews
{
	return NSAllMapTableKeys(viewToContent);
}
- (NSTextField *)typeView
{
	return typeView;
}
- (NSTextField *)nickView
{
	return nickView;
}
- (NSWindow *)window
{
	return window;
}
@end

