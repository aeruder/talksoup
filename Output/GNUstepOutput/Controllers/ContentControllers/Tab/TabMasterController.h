/***************************************************************************
                         TabMasterController.h
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
 
 @class TabMasterController;
 
#ifndef TAB_MASTER_CONTROLLER_H
#define TAB_MASTER_CONTROLLER_H
 
#import "Controllers/ContentControllers/ContentController.h"

#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>
 
@class NSTextField, NSTabView, NSWindow, NSMutableArray;
@class NSAttributedString;

@interface TabMasterController : NSObject < MasterController >
	{
		NSMutableArray *indexToView;
		NSMapTable *viewToIndex;
		NSMapTable *viewToTab;
		NSMapTable *viewToContent;
		NSMapTable *tabToView;
		NSMutableArray *contentControllers;
		
		NSTextField *typeView;
		NSTextField *nickView;
		NSTabView *tabView;
		NSWindow *window;
		
		int numItems;
	}		
		
- (void)addView: (id <ContentControllerQueryView>)aView withLabel: (NSAttributedString *)aLabel
   forContentController: (id <ContentController>)aContentController;
- (void)addView: (id <ContentControllerQueryView>)aView withLabel: (NSAttributedString *)aLabel
   atIndex: (int)aIndex forContentController: (id <ContentController>)aContentController;

- (void)selectView: (id <ContentControllerQueryView)aView;
- (void)selectViewAtIndex: (int)aIndex;

- (void)removeView: (id <ContentControllerQueryView>)aView;
- (void)removeViewAtIndex: (int)aIndex;

- (void)moveView: (id <ContentControllerQueryView>)aView toIndex: (int)aIndex;
- (void)moveViewAtIndex: (int)aIndex toIndex: (int)aNewIndex;

- (int)indexForView: (id <ContentControllerQueryView>)aView;
- (int)count;
	 
- (NSArray *)containedContentControllers;
- (NSArray *)viewListForContentController: 
    (id <ContentController>)aContentController;
- (NSArray *)allViews;

- (NSTextField *)typeView;
- (NSTextField *)nickView;

- (NSWindow *)window;
@end

#endif
