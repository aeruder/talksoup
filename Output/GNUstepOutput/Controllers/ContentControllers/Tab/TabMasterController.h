/***************************************************************************
                         TabMasterController.h
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
		NSMutableArray *indexToViewController;
		NSMapTable *viewControllerToIndex;
		NSMapTable *viewControllerToTab;
		NSMapTable *viewControllerToContent;
		NSMapTable *tabToViewController;
		NSMutableArray *contentControllers;
		
		id <ContentControllerQueryController> selectedController;
		id <TypingController> typingController;
		NSTextField *typeView;
		NSTextField *nickView;
		NSTabView *tabView;
		NSWindow *window;
		
		unsigned numItems;
	}		
		
- (void)addViewController: (id <ContentControllerQueryController>)aController
   withLabel: (NSAttributedString *)aLabel
   forContentController: (id <ContentController>)aContentController;
- (void)addViewController: (id <ContentControllerQueryController>)aController
   withLabel: (NSAttributedString *)aLabel
   atIndex: (unsigned)aIndex 
   forContentController: (id <ContentController>)aContentController;

- (void)selectViewController: (id <ContentControllerQueryController>)aController;
- (void)selectViewControllerAtIndex: (unsigned)aIndex;

- (void)removeViewController: (id <ContentControllerQueryController>)aController;
- (void)removeViewControllerAtIndex: (unsigned)aIndex;

- (void)moveViewController: (id <ContentControllerQueryController>)aController 
   toIndex: (unsigned)aIndex;
- (void)moveViewControllerAtIndex: (unsigned)aIndex 
   toIndex: (unsigned)aNewIndex;

- (unsigned)indexForViewController: (id <ContentControllerQueryController>)aController;
- (unsigned)count;

- (NSAttributedString *)labelForViewController: (id <ContentControllerQueryController>)aController;
- (void)setLabel: (NSAttributedString *)aLabel 
    forViewController: (id <ContentControllerQueryController>)aController;
	 
- (NSArray *)containedContentControllers;
- (NSArray *)viewControllerListForContentController: 
    (id <ContentController>)aContentController;
- (NSArray *)allViewControllers;

- (NSTextField *)typeView;
- (NSTextField *)nickView;

- (void)bringToFront;
- (NSWindow *)window;
@end

#endif
