/***************************************************************************
                                ConnectionControllerDelegate.m
                          -------------------
    begin                : Tue May 20 18:38:20 CDT 2003
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

#import "Controllers/ConnectionController.h"
#import <TalkSoupBundles/TalkSoup.h>
#import "GNUstepOutput.h"
#import "Controllers/ContentControllers/ContentController.h"
#import "Controllers/ContentControllers/StandardChannelController.h"
#import "Controllers/InputController.h"
#import "Controllers/TopicInspectorController.h"
#import "Models/Channel.h"
#import "Views/KeyTextView.h"

#import <Foundation/NSNotification.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextField.h>

@implementation ConnectionController (ApplicationDelegate)
// FIXME I don't understand why this is here.
//- (void)selectNextTab: (id)sender
//{
//	id tabs = [content tabView];
//	int total = [tabs numberOfTabViewItems];
//	int current = [tabs indexOfTabViewItem: 
//	  [tabs selectedTabViewItem]];
//	
//	current = (current + 1) % total;
//	
//	[tabs selectTabViewItemAtIndex: current];
//}
//- (void)selectPreviousTab: (id)sender
//{
//	id tabs = [content tabView];
//	int total = [tabs numberOfTabViewItems];
//	int current = [tabs indexOfTabViewItem: 
//	  [tabs selectedTabViewItem]];
//	
//	current--;
//	
//	if (current < 0) current = total - 1;
//	
//	[tabs selectTabViewItemAtIndex: current];
//}
//- (void)closeCurrentTab: (id)sender
//{
//	[inputController lineTyped: @"/close"];
//}
- (void)windowWillClose: (NSNotification *)aNotification
{
}
@end


