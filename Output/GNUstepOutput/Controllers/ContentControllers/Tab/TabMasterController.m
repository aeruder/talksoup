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

#import "Controllers/ContentControllers/Tab/TabMasterController.h"
#import "Views/AttributedTabViewItem.h"

#import <AppKit/NSTextField.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTabViewItem.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSValue.h>
#import <AppKit/NSNibLoading.h>

@interface TabMasterController (DelegateMethods)
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject;
- (void)tabView: (NSTabView *)tabView 
  didSelectTabViewItem: (NSTabViewItem *)tabViewItem;
@end

@implementation TabMasterController
- init
{
	if (!(self = [super init])) return nil;
		
	viewToTab = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 10);
	viewToContent = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 10);
	tabToView = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 10);
	contentControllers = [NSMutableArray new];

	if (!([NSBundle loadNibNamed: @"TabContent" owner: self]))
	{
		NSLog(@"Failed to load TabContent UI");
		[self dealloc];
		return nil;
	}

	NSLog(@"TabMasterController created!");
	return self;
}
- (void)awakeFromNib
{
	id object;
	while ([tabView numberOfTabViewItems] && 
	       (object = [tabView tabViewItemAtIndex: 0])) 
		[tabView removeTabViewItem: object];
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
	
	[tabView setDelegate: nil];
	
	[window setDelegate: nil];
	[window close];
	DESTROY(window);
	
	[super dealloc];
}
- (void)addView: (id <ContentControllerQueryView>)aView withLabel: (NSAttributedString *)aLabel
   forContentController: (id <ContentController>)aContentController
{
	[self addView: aView withLabel: aLabel atIndex: numItems 
	  forContentController: aContentController];
}
- (void)addView: (id <ContentControllerQueryView>)aView withLabel: (NSAttributedString *)aLabel
   atIndex: (unsigned)aIndex forContentController: (id <ContentController>)aContentController
{
	AttributedTabViewItem *tabItem;
	
	tabItem = AUTORELEASE([AttributedTabViewItem new]);
	
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
}
- (void)selectView: (id <ContentControllerQueryView>)aView
{
	id tab, content;

	tab = NSMapGet(viewToTab, aView);
	content = NSMapGet(viewToContent, aView);

	NSLog(@"Selecting view!");
	if (!tab || !content) return;

	selected = aView;

	[tabView selectTabViewItem: tab];

	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ContentControllerSelectedNameNotification
	 object: content userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
	  aView, @"View",
	  content, @"Content",
	  self, @"Master",
	  nil]];
	RELEASE(typingController);
	typingController = RETAIN([content 
	     typingControllerForView: aView]);
}
- (void)selectViewAtIndex: (unsigned)aIndex
{
	id view;

	if (aIndex >= [indexToView count]) return;

	view = [indexToView objectAtIndex: aIndex];

	[self selectView: view];
}
- (id <ContentControllerQueryView>)selectedView
{
	return selected;
}
- (void)removeView: (id <ContentControllerQueryView>)aView
{
	id tab;
	id userInfo;
	id content;

	if (!(NSMapMember(viewToTab, aView, 0, 0)))
	{
		return;
	}
	
	tab = NSMapGet(viewToTab, aView);
	
	[tab setView: nil];
	[tabView removeTabViewItem: tab];
	
	[tabView setNeedsDisplay: YES];
	
	content = NSMapGet(viewToContent, aView);
	AUTORELEASE(RETAIN(content));

	userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
	  self, @"Master",
	  aView, @"View",
	  content, @"Content",
	  nil];

	NSMapRemove(viewToTab, aView);
	NSMapRemove(viewToContent, aView);
	NSMapRemove(tabToView, tab);
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ContentControllerRemovedFromMasterControllerNotification
	 object: content userInfo: userInfo];
}
- (void)removeViewAtIndex: (unsigned)aIndex
{
	id aView;
	id tab;
	
	tab = [tabView tabViewItemAtIndex: aIndex];
	if (!(NSMapMember(tabToView, tab, 0, 0)))
	{
		return;
	}
	
	aView = NSMapGet(viewToTab, aView);

	[self removeView: aView];
}
- (void)moveView: (id <ContentControllerQueryView>)aView toIndex: (unsigned)aIndex;
{
	unsigned index;
	id tab;
	unsigned origIndex;
	id content;
	
	if (!(NSMapMember(viewToTab, aView, 0, 0)))
	{
		return;
	}
	
	tab = NSMapGet(viewToTab, aView);
	
	origIndex = index = [tabView indexOfTabViewItem: tab];
	
	if (aIndex == index)
	{
		return;
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
}
- (void)moveViewAtIndex: (unsigned)aIndex toIndex: (unsigned)aNewIndex
{
	id tab;
	id aView;
	
	tab = [tabView tabViewItemAtIndex: aIndex];
	
	if (!(NSMapMember(tabToView, tab, 0, 0)))
	{
		return;
	}
	
	aView = NSMapGet(tabToView, tab);
	
	[self moveView: aView toIndex: aNewIndex];
}	 
- (unsigned)indexForView: (id <ContentControllerQueryView>)aView
{
	NSTabViewItem *tab;
	unsigned index;

	tab = NSMapGet(viewToTab, aView);
	if (!tab) return NSNotFound;

	index = [tabView indexOfTabViewItem: tab];

	return index;
}
- (unsigned)count
{
	return [indexToView count];
}
- (NSAttributedString *)labelForView: (id <ContentControllerQueryView>)aView
{
	AttributedTabViewItem *tab;

	tab = NSMapGet(viewToTab, aView);
	if (!tab) return nil;

	return [tab attributedLabel];
}
- (void)setLabel: (NSAttributedString *)aLabel 
    forView: (id <ContentControllerQueryView>)aView
{
	AttributedTabViewItem *tab;

	if (!aLabel) {
		aLabel = AUTORELEASE([NSAttributedString new]);
	}

	if (!aView) return;

	tab = NSMapGet(viewToTab, aView);
	if (!tab) return;

	[tab setAttributedLabel: aLabel];
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
- (void)bringToFront
{
	[window makeKeyAndOrderFront: nil];
}
- (NSWindow *)window
{
	return window;
}
@end

@implementation TabMasterController (DelegateMethods)
- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	/* Basically we just need to force the 
	 * notification to happen */
	[self selectView: selected];
}
- (id)windowWillReturnFieldEditor: (NSWindow *)sender toObject: (id)anObject
{
	id content;

	if (anObject != typeView) return nil;

	content = NSMapGet(viewToContent, selected);

	NSLog(@"Requested field editor. content: %@", content);

	return [[content typingControllerForView: selected]
	  fieldEditorForField: typeView];
}
- (void)tabView: (NSTabView *)tabView 
  didSelectTabViewItem: (NSTabViewItem *)tabViewItem
{
	id view;

	view = NSMapGet(tabToView, tabViewItem);

	if (view != selected) {
		[self selectView: view];
	}
}
@end
