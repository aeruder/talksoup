/***************************************************************************
                        ChannelViewController.h
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

#import <Foundation/NSObject.h>

@class NSString, NSTabViewItem, NSTextView, NSTableView;
@class NSTableColumn, ConsoleView, Channel;

@interface ChannelViewController : NSObject
	{
		id view;
		NSTabViewItem *tab;
		NSString *name;
		Channel *channelModel;
		
		ConsoleView *consoleView;
		NSTableView *userTable;
		NSTableColumn *userColumn;
	}
+ (ChannelViewController *)lookupByTab: (NSTabViewItem *)aTab;

- init;

- (NSTabViewItem *)tabItem;
- setTabItem: (NSTabViewItem *)aTab;
- setTabLabel: (NSString *)aName;

- view;
- setView: aView;

- (NSString *)name;
- setName: (NSString *)aName;

- setChannelModel: (Channel *)aObject;
- (Channel *)channelModel;
- reloadUserList;

- putMessage: aMessage;

- (BOOL)hasUserList;
@end

	
