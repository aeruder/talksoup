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

#import <AppKit/NSTextField.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTabViewItem.h>
#import <AppKit/NSWindow.h>
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

@interface TabMasterController (PrivateMethods)
- (void)setNickname: (NSString *)aNickname;
@end

@interface TabMasterController (DelegateMethods)
- (void)nicknameChanged: (NSNotification *)aNotification;
- (void)titleChanged: (NSNotification *)aNotification;
- (void)typeViewEnterPressed: (NSTextField *)aField;
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject;
- (void)tabView: (NSTabView *)tabView 
  didSelectTabViewItem: (NSTabViewItem *)tabViewItem;
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
	contentControllers = [NSMutableArray new];

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
	[typeView setAction: @selector(typeViewEnterPressed:)];
	[typeView setTarget: self];
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
	
	[typeView setTarget: nil];
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

	if (!tab || !content) return;

	[typingController losingFieldEditorForField: typeView
	  forMasterController: self];

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

	[typeView abortEditing];
	[window makeFirstResponder: typeView]; 
}
- (void)selectViewControllerAtIndex: (unsigned)aIndex
{
	id view;

	if (aIndex >= [indexToViewController count]) return;

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
	int oldIndex;

	if (!(NSMapMember(viewControllerToTab, aController, 0, 0)))
	{
		return;
	}
	
	tab = NSMapGet(viewControllerToTab, aController);
	
	[tab setView: nil];
	oldIndex = [tabView indexOfTabViewItem: tab] + 1;
	if (oldIndex >= [tabView numberOfTabViewItems]) 
	{
		oldIndex = [tabView numberOfTabViewItems] - 2;
	}
	[self selectViewControllerAtIndex: oldIndex];
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
	
	numItems--;

	if (aController == selectedController) 
	{
		[typingController losingFieldEditorForField: typeView
		  forMasterController: self];
		selectedController = nil;
		DESTROY(typingController);
	}
		
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
	
	[tabView insertTabViewItem: tab atIndex: index];

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
	NSTabViewItem *tab;
	unsigned index;

	tab = NSMapGet(viewControllerToTab, aController);
	if (!tab) return NSNotFound;

	index = [tabView indexOfTabViewItem: tab];

	return index;
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
	return [NSArray arrayWithArray: contentControllers];
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

@implementation TabMasterController (PrivateMethods)
- (void)setNickname: (NSString *)aNickname
{
	NSRect nick;
	NSRect type;

	[nickView setStringValue: aNickname];
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
- (void)typeViewEnterPressed: (NSTextField *)aField
{
	id content;

	content = NSMapGet(viewControllerToContent, selectedController);

	[typingController commandTyped: [aField stringValue]];
}
- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	/* Basically we just need to force the 
	 * notification to happen */
	[self selectViewController: selectedController];

	[window makeFirstResponder: typeView]; 
}
- (id)windowWillReturnFieldEditor: (NSWindow *)sender toObject: (id)anObject
{
	id content;

	if (anObject != typeView) return nil;

	content = NSMapGet(viewControllerToContent, selectedController);

	return [typingController
	  fieldEditorForField: typeView forMasterController: self];
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
@end
