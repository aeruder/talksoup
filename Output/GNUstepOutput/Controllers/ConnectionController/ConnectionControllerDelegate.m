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

#include "Controllers/ConnectionController.h"
#include "TalkSoupBundles/TalkSoup.h"
#include "GNUstepOutput.h"
#include "Controllers/ContentController.h"
#include "Controllers/ChannelController.h"
#include "Controllers/InputController.h"
#include "Controllers/TopicInspectorController.h"
#include "Models/Channel.h"
#include "Views/KeyTextView.h"

#include <Foundation/NSNotification.h>
#include <AppKit/NSTabView.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSTextField.h>

@implementation ConnectionController (TableViewTarget)
- (void)doubleClickedUser: (NSTableView *)sender
{
	id name = [content currentViewName];
	id channel;
	id user;
	
	if ([[content controllerForViewWithName: name] tableView]
	    == sender)
	{
		if ((channel = [nameToChannelData objectForKey: 
		  GNUstepOutputLowercase(name)]))
		{
			user = [[[channel userList] objectAtIndex: [sender clickedRow]]
			  userName];
			[content addQueryWithName: user 
			  withLabel: S2AS(user)];
		}
	}
}
@end

@implementation ConnectionController (ApplicationDelegate)
- (void)selectNextTab: (id)sender
{
	id tabs = [content tabView];
	int total = [tabs numberOfTabViewItems];
	int current = [tabs indexOfTabViewItem: 
	  [tabs selectedTabViewItem]];
	
	current = (current + 1) % total;
	
	[tabs selectTabViewItemAtIndex: current];
}
- (void)selectPreviousTab: (id)sender
{
	id tabs = [content tabView];
	int total = [tabs numberOfTabViewItems];
	int current = [tabs indexOfTabViewItem: 
	  [tabs selectedTabViewItem]];
	
	current--;
	
	if (current < 0) current = total - 1;
	
	[tabs selectTabViewItemAtIndex: current];
}
- (void)closeCurrentTab: (id)sender
{
	[inputController lineTyped: @"/close"];
}
@end

@implementation ConnectionController (WindowDelegate)
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
@end

