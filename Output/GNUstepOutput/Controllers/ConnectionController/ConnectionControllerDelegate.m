/***************************************************************************
                                ConnectionControllerDelegate.m
                          -------------------
    begin                : Tue May 20 18:38:20 CDT 2003
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

@implementation ConnectionController (TableViewTarget)
// FIXME this needs to be replaced by a  notification
//- (void)doubleClickedUser: (NSTableView *)sender
//{
//	id name = [content currentViewName];
//	id channel;
//	id user;
//	
//	if ([[content controllerForViewWithName: name] tableView]
//	    == sender)
//	{
//		if ((channel = [nameToChannelData objectForKey: 
//		  GNUstepOutputLowercase(name)]))
//		{
//			user = [[[channel userList] objectAtIndex: [sender clickedRow]]
//			  userName];
//			[content addQueryWithName: user 
//			  withLabel: S2AS(user)];
//		}
//	}
//}
@end

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
@end

@implementation ConnectionController (WindowDelegate)
	// FIXME -- need to be replaced by the notification system.
/*
- (void)windowWillClose: (NSNotification *)aNotification
{	
	id controller;
	
	if (connection)
	{
		[[_TS_ pluginForInput] closeConnection: connection];
	}
	
	[[content window] setDelegate: nil];
	[[content typeView] setTarget: nil];
	[fieldEditor setKeyTarget: nil];
	
	AUTORELEASE(RETAIN(self));

	[_GS_ removeConnectionController: self];
	
	controller = [_GS_ topicInspectorController];
	
	if (self == [controller connectionController])
	{
		[controller setTopic: nil inChannel: nil
		  setBy: nil onDate: nil
		  forConnectionController: nil];
	}	
}
- (void)windowDidBecomeKey: (NSNotification *)aNotification
{
	id win = [aNotification object];
	
	[self updateTopicInspector];
	[win makeFirstResponder: [content typeView]];
}
- (id)windowWillReturnFieldEditor: (NSWindow *)sender toObject: (id)anObject
{
	if (anObject == [content typeView])
	{
		return fieldEditor;
	}
	return nil;
}
- (void)tabView: (NSTabView *)aTabView
  didSelectTabViewItem: (NSTabViewItem *)tabViewItem
{
	[self updateTopicInspector];
}
*/
@end

