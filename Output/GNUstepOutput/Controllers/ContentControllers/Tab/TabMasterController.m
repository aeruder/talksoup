/***************************************************************************
                         TabMasterController.m
                          -------------------
    begin                : Mon Jan 19 11:59:32 CST 2004
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

#import "Controllers/ContentControllers/Tab/TabMasterController.h"
#import "Views/AttributedTabViewItem.h"
#import "Views/FocusNotificationTextView.h"

#import <AppKit/NSTextField.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTabViewItem.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSTextContainer.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSValue.h>
#import <AppKit/NSNibLoading.h>
#import <Foundation/NSString.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSSet.h>

@interface TabMasterController (PrivateMethods)
- (void)setNickname: (NSString *)aNickname;
@end

@interface TabMasterController (DelegateMethods)
- (void)nicknameChanged: (NSNotification *)aNotification;
- (void)titleChanged: (NSNotification *)aNotification;
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (void)windowDidResignKey:(NSNotification *)aNotification;
- (void)tabView: (NSTabView *)tabView 
  didSelectTabViewItem: (NSTabViewItem *)tabViewItem;
- (void)selectNextTab: (id)aSender;
- (void)selectPreviousTab: (id)aSender;
- (void)closeCurrentTab: (id)aSender;
- (void)textViewTookFocus: (FocusNotificationTextView *)aTextView;
- (void)textViewResignedFocus: (FocusNotificationTextView *)aTextView;
@end

@implementation TabMasterController
- init
{
	if (!(self = [super init])) return nil;
		
	viewControllerToTab = 
	  NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 10);
	viewControllerToContent = 
	  NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 10);
	tabToViewController = 
	  NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 10);
	contentControllers = [NSCountedSet new];
	indexToViewController = [NSMutableArray new];

	if (!([NSBundle loadNibNamed: @"TabContent" owner: self]))
	{
		NSLog(@"Failed to load TabContent UI");
		[self dealloc];
		return nil;
	}
	return self;
}
- (void)awakeFromNib
{
	id object;
	while ([tabView numberOfTabViewItems] && 
	       (object = [tabView tabViewItemAtIndex: 0])) 
		[tabView removeTabViewItem: object];
	[typeView setDelegate: self];
	[typeView setRichText: NO];
	[typeView setUsesFontPanel: NO];
	[typeView setHorizontallyResizable: NO];
	[typeView setVerticallyResizable: YES];
	[typeView setMinSize: NSMakeSize(0, 0)];
	[typeView setMaxSize: NSMakeSize(1e7, 1e7)];
	[typeView setEditable: YES];
	[typeView setAutoresizingMask: NSViewWidthSizable];
	[[typeView textContainer] setContainerSize:
	  NSMakeSize([typeView frame].size.width, 1e7)];
	[[typeView textContainer] setWidthTracksTextView: YES];
	[typeView setTextContainerInset: NSMakeSize(2, 0)];
	[[typeView enclosingScrollView] setHasVerticalScroller: NO];
	[[typeView enclosingScrollView] setHasHorizontalScroller: NO];
}
- (void)dealloc
{
	[window setDelegate: nil];
	[window close];
	DESTROY(window);
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
	  name: ContentControllerChangedNicknameNotification
	  object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
	  name: ContentControllerChangedTitleNotification
	  object: nil];
	NSFreeMapTable(viewControllerToTab);
	NSFreeMapTable(viewControllerToContent);
	NSFreeMapTable(tabToViewController);
	DESTROY(contentControllers);
	DESTROY(indexToViewController);
	
	[typeView setKeyTarget: nil];
	[typeView setDelegate: nil];
	
	[nickView setTarget: nil];
	[nickView setDelegate: nil];
	
	[tabView setDelegate: nil];
	
	[super dealloc];
}
- (void)addViewController: (id <ContentControllerQueryController>)aController
   withLabel: (NSAttributedString *)aLabel
   forContentController: (id <ContentController>)aContentController
{
	[self addViewController: aController withLabel: aLabel atIndex: numItems 
	  forContentController: aContentController];
}
- (void)addViewController: (id <ContentControllerQueryController>)aController
   withLabel: (NSAttributedString *)aLabel
   atIndex: (unsigned)aIndex forContentController: (id <ContentController>)aContentController
{
	AttributedTabViewItem *tabItem;
	int selected;
	
	tabItem = AUTORELEASE([AttributedTabViewItem new]);
	
	NSMapInsert(viewControllerToTab, aController, tabItem);
	NSMapInsert(viewControllerToContent, aController, aContentController);
	NSMapInsert(tabToViewController, tabItem, aController);
	[indexToViewController insertObject: aController atIndex: aIndex]; 
	[contentControllers addObject: aContentController];

	[tabView insertTabViewItem: tabItem atIndex: aIndex];
	numItems++;
	[tabItem setView: [aController contentView]];
	[tabItem setAttributedLabel: aLabel];
	
	selected = [tabView indexOfTabViewItem: [tabView selectedTabViewItem]];
	[tabView selectTabViewItemAtIndex: aIndex];
	[tabView selectTabViewItemAtIndex: selected];
	[tabView setNeedsDisplay: YES];

	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ContentControllerAddedToMasterControllerNotification
	 object: aContentController userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
	  [NSNumber numberWithInt: aIndex], @"Index",
	  self, @"Master",
	  aController, @"View",
	  aContentController, @"Content",
	  nil]];

	/* If its the first one, we need to force the selection 
	 */
	if (numItems == 1) 
	{
		[self selectViewController: aController];
	}
}
- (void)selectViewController: (id <ContentControllerQueryController>)aController
{
	id tab, content;

	tab = NSMapGet(viewControllerToTab, aController);
	content = NSMapGet(viewControllerToContent, aController);

	[window makeFirstResponder: window];
	if (!tab || !content) return;

	[[NSNotificationCenter defaultCenter] removeObserver: self
	  name: ContentControllerChangedNicknameNotification
	  object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
	  name: ContentControllerChangedTitleNotification
	  object: nil];

	selectedController = aController;

	[tabView selectTabViewItem: tab];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(titleChanged:)
	  name: ContentControllerChangedTitleNotification
	  object: selectedController];
	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(nicknameChanged:)
	  name: ContentControllerChangedNicknameNotification
	  object: content];
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ContentControllerSelectedNameNotification
	 object: content userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
	  aController, @"View",
	  content, @"Content",
	  self, @"Master",
	  nil]];

	RELEASE(typingController);
	typingController = RETAIN([content 
	     typingControllerForViewController: aController]);

	[self setNickname: [content nickname]];
	[window setTitle: [content titleForViewController: aController]];

	[window makeFirstResponder: typeView]; 
}
- (void)selectViewControllerAtIndex: (unsigned)aIndex
{
	id view;

	if (aIndex >= numItems) return;

	view = [indexToViewController objectAtIndex: aIndex];

	[self selectViewController: view];
}
- (id <ContentControllerQueryController>)selectedViewController
{
	return selectedController;
}
- (void)removeViewController: (id <ContentControllerQueryController>)aController
{
	id tab;
	id userInfo;
	id content;
	int index;

	if (!(NSMapMember(viewControllerToTab, aController, 0, 0)))
	{
		return;
	}
	
	tab = NSMapGet(viewControllerToTab, aController);
	
	index = [tabView indexOfTabViewItem: tab];
	if (selectedController == aController)
	{
		int oldIndex = index + 1;
		if (oldIndex >= [tabView numberOfTabViewItems]) 
		{
			oldIndex = [tabView numberOfTabViewItems] - 2;
		}

		[self selectViewControllerAtIndex: oldIndex];
	}

	[tab setView: nil];

	[tabView removeTabViewItem: tab];
	
	[tabView setNeedsDisplay: YES];
	
	content = NSMapGet(viewControllerToContent, aController);
	AUTORELEASE(RETAIN(content));

	userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
	  self, @"Master",
	  aController, @"View",
	  content, @"Content",
	  nil];

	NSMapRemove(viewControllerToTab, aController);
	NSMapRemove(viewControllerToContent, aController);
	NSMapRemove(tabToViewController, tab);
	[indexToViewController removeObjectAtIndex: index];
	[contentControllers removeObject: content];
	
	numItems--;
		
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ContentControllerRemovedFromMasterControllerNotification
	 object: content userInfo: userInfo];
}
- (void)removeViewControllerAtIndex: (unsigned)aIndex
{
	id aController;
	id tab;
	
	tab = [tabView tabViewItemAtIndex: aIndex];
	if (!(NSMapMember(tabToViewController, tab, 0, 0)))
	{
		return;
	}
	
	aController = NSMapGet(tabToViewController, tab);

	[self removeViewController: aController];
}
- (void)moveViewController: (id <ContentControllerQueryController>)aController 
   toIndex: (unsigned)aIndex;
{
	unsigned index;
	id tab;
	unsigned origIndex;
	id content;
	
	if (!(NSMapMember(viewControllerToTab, aController, 0, 0)))
	{
		return;
	}
	
	tab = NSMapGet(viewControllerToTab, aController);
	
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
	[indexToViewController removeObjectAtIndex: origIndex];
	
	[tabView insertTabViewItem: tab atIndex: index];
	[indexToViewController insertObject: aController atIndex: aIndex];

	content = NSMapGet(viewControllerToContent, aController);

	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ContentControllerMovedInMasterControllerNotification
	 object: content userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
	  [NSNumber numberWithInt: origIndex], @"OldIndex",
	  [NSNumber numberWithInt: index], @"Index",
	  self, @"Master",
	  aController, @"View",
	  content, @"Content",
	  nil]];
}
- (void)moveViewControllerAtIndex: (unsigned)aIndex toIndex: (unsigned)aNewIndex
{
	id tab;
	id aController;
	
	tab = [tabView tabViewItemAtIndex: aIndex];
	
	if (!(NSMapMember(tabToViewController, tab, 0, 0)))
	{
		return;
	}
	
	aController = NSMapGet(tabToViewController, tab);
	
	[self moveViewController: aController toIndex: aNewIndex];
}	 
- (unsigned)indexForViewController: (id <ContentControllerQueryController>)aController
{
	return [indexToViewController indexOfObject: aController];
}
- (unsigned)count
{
	return [indexToViewController count];
}
- (NSAttributedString *)labelForViewController: (id <ContentControllerQueryController>)aController
{
	AttributedTabViewItem *tab;

	tab = NSMapGet(viewControllerToTab, aController);
	if (!tab) return nil;

	return [tab attributedLabel];
}
- (void)setLabel: (NSAttributedString *)aLabel 
    forViewController: (id <ContentControllerQueryController>)aController
{
	AttributedTabViewItem *tab;

	if (!aLabel) {
		aLabel = AUTORELEASE([NSAttributedString new]);
	}

	if (!aController) return;

	tab = NSMapGet(viewControllerToTab, aController);
	if (!tab) return;

	[tab setAttributedLabel: aLabel];
}
- (NSArray *)containedContentControllers
{
	return [contentControllers allObjects];
}
- (NSArray *)viewControllerListForContentController: 
    (id <ContentController>)aContentController
{
	id iter;
	id object;
	id vArray;
	id results;
	
	vArray = NSAllMapTableKeys(viewControllerToContent);
	
	iter = [vArray objectEnumerator];
	
	results = AUTORELEASE([NSMutableArray new]);
	
	while ((object = [iter nextObject]))
	{
		if (NSMapGet(viewControllerToContent, object) == aContentController)
		{
			[results addObject: object];
		}
	}
	
	return results;
}	
- (NSArray *)allViewControllers
{
	return NSAllMapTableKeys(viewControllerToContent);
}
- (KeyTextView *)typeView
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

@implementation TabMasterController (PrivateMethods)
- (void)setNickname: (NSString *)aNickname
{
	NSRect nick;
	NSRect type;

	if (!aNickname)
	{
		aNickname = @"";
	}

	[nickView setStringValue: aNickname];
	[nickView sizeToFit];
	
	nick = [nickView frame];
	nick.origin.y = 8;

	type = [[typeView enclosingScrollView] frame];
	type.origin.y = 4;
	type.origin.x = NSMaxX(nick) + 4;
	type.size.width = [[window contentView] frame].size.width - 4 - type.origin.x;
	
	[nickView setFrame: nick];
	[[typeView enclosingScrollView] setFrame: type];
	
	[[window contentView] setNeedsDisplay: YES];
}
@end

@implementation TabMasterController (DelegateMethods)
- (void)nicknameChanged: (NSNotification *)aNotification
{
	id content;

	content = NSMapGet(viewControllerToContent, selectedController);
	/* Somehow we got a notification for the non-current content controller */
	if (content != [aNotification object])
	{
		return;
	}

	[self setNickname: [content nickname]];
}
- (void)titleChanged: (NSNotification *)aNotification
{
	if (selectedController != [aNotification object])
	{
		return;
	}

	[window setTitle: [[aNotification userInfo] objectForKey: @"Title"]];
}
- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	/* Basically we just need to force the 
	 * notification to happen */
	[self selectViewController: selectedController];

	[window makeFirstResponder: typeView]; 
}
- (void)windowDidResignKey:(NSNotification *)aNotification
{
	[window makeFirstResponder: window];
}
- (void)tabView: (NSTabView *)tabView 
  didSelectTabViewItem: (NSTabViewItem *)tabViewItem
{
	id view;

	view = NSMapGet(tabToViewController, tabViewItem);

	if (view != selectedController) {
		[self selectViewController: view];
	}
}
- (void)selectNextTab: (id)aSender
{
	unsigned index;

	index = [self indexForViewController: selectedController];

	if (index >= (numItems - 1))
		index = 0;
	else
		index++;

	[self selectViewControllerAtIndex: index];
}
- (void)selectPreviousTab: (id)aSender
{
	unsigned index;

	index = [self indexForViewController: selectedController];

	if (index == 0)
		index = numItems - 1;
	else
		index--;

	[self selectViewControllerAtIndex: index];
}
- (void)closeCurrentTab: (id)aSender
{
	[typingController processSingleCommand: @"/close"];
}
- (void)textViewTookFocus: (FocusNotificationTextView *)aTextView
{
	[typingController
	  handleTextField: typeView forMasterController: self];
}
- (void)textViewResignedFocus: (FocusNotificationTextView *)aTextView
{
	[typingController
	  loseTextField: typeView forMasterController: self];
}
@end
