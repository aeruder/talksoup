/***************************************************************************
                        ChannelViewController.m
                          -------------------
    begin                : Thu Oct 24 12:50:49 CDT 2002
    copyright            : (C) 2002 by Andy Ruder
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

#import "Controllers/ChannelViewController.h"
#import "Views/ChannelView.h"
#import "Views/ConsoleView.h"
#import "Models/Channel.h"

#import <Foundation/NSString.h>
#import <Foundation/NSMapTable.h>
#import <AppKit/NSTabViewItem.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSView.h>

static NSMapTable *tab_map = 0;

@implementation ChannelViewController
+ (void)initialize
{
	tab_map	= NSCreateMapTable(NSNonRetainedObjectMapKeyCallBacks,
	                           NSNonRetainedObjectMapValueCallBacks, 15);
}
+ (ChannelViewController *)lookupByTab: (NSTabViewItem *)aTab
{
	return NSMapGet(tab_map, aTab);
}	
- init
{
	if (!(self = [super init])) return nil;

	return self;
}
- (void)dealloc
{
	NSMapRemove(tab_map, tab);
	RELEASE(view);
	RELEASE(tab);

	//[userTable setDataSource: ];

	RELEASE(consoleView);
	RELEASE(userTable);
	RELEASE(userColumn);

	[super dealloc];
}
- (NSTabViewItem *)tabItem
{
	return tab;
}
- setTabItem: (NSTabViewItem *)aTab
{
	id temp;
	if (aTab == tab) return self;

	NSMapRemove(tab_map, tab);
	temp = RETAIN(view);
	[tab setView: nil];
	RELEASE(tab);
	tab = RETAIN(aTab);
	[tab setView: temp];
	RELEASE(temp);
	NSMapInsert(tab_map, tab, self);

	return self;
}
- setTabLabel: (NSString *)aName
{
	if (!aName) aName = @"";

	[tab setLabel: aName];
	[[tab tabView] setNeedsDisplay: YES];

	return self;
}
- setName: (NSString *)aName
{
	if (aName == name) return self;

	RELEASE(name);
	name = RETAIN(aName);

	return self;
}
- (NSString *)name
{
	return name;
}
- view
{
	return view;
}
- setView: aView
{
	if (aView == view) return self;

	RELEASE(view);
	view = RETAIN(aView);

	//[userTable setDataSource: nil];
	[userTable setDataSource: self];
	
	RELEASE(userTable);
	RELEASE(userColumn);
	RELEASE(consoleView);

	if ([view isKindOf: [ChannelView class]])
	{
		userTable = RETAIN([view userTable]);
		userColumn = RETAIN([view userColumn]);
		consoleView = RETAIN([view consoleView]);
		//[userTable setDataSource: channelModel];
		if (channelModel)
		{
			[userTable setDataSource: channelModel];
		}
		else
		{
			[userTable setDataSource: self];
		}
	}
	else
	{
		userTable = nil;
		userColumn = nil;
		consoleView = RETAIN(view);
		[self setChannelModel: nil];
	}

	[tab setView: view];

	return self;
}
- setChannelModel: (Channel *)aObject
{
	if (channelModel == aObject) return self;
	
	RELEASE(channelModel);
	channelModel = RETAIN(aObject);
	if (channelModel)
	{
		[userTable setDataSource: channelModel];
	}
	else
	{
		[userTable setDataSource: self];
	}
	
	return self;
}
- (Channel *)channelModel
{
	return channelModel;
}
- reloadUserList
{
	[userTable reloadData];
	return self;
}
- putMessage: aMessage
{
	[consoleView putMessage: aMessage];
	return self;
}
- (BOOL)hasUserList
{
	return (userTable != nil);
}
- (int)numberOfRowsInTableView: a
{
	return 0;
}
- (id)tableView: a objectValueForTableColumn: b row: (int)c
{
	return nil;
}
@end
