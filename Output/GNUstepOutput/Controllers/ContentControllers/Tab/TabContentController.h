/***************************************************************************
                                ContentController.h
                          -------------------
    begin                : Sat Jan 18 01:38:06 CST 2003
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

@class ContentController, NSString;

extern NSString *ContentConsoleName;

#ifndef CONTENT_CONTROLLER_H
#define CONTENT_CONTROLLER_H

#include <Foundation/NSObject.h>
#include <Foundation/NSMapTable.h>

@class NSTextField, NSTabView, NSWindow;
@class NSMutableDictionary, NSString, NSAttributedString;
@class NSTabViewItem, NSArray;
@class NSColor;
@class ConnectionController, NSFont;

NSAttributedString *SubstituteColorCodesIntoAttributedString(NSAttributedString *str);

@interface ContentController : NSObject
{
	NSTextField *typeView;
	NSTextField *nickView;
	NSTabView *tabView;
	NSWindow *window;
	NSMutableDictionary *nameToChannel;
	NSMutableDictionary *nameToQuery;
	NSMutableDictionary *nameToBoth;
	NSMutableDictionary *nameToPresentation;
	NSMutableDictionary *nameToLabel;
	NSMutableDictionary *nameToTabItem;
	NSMutableArray *highlightedTabs;
	NSMapTable *tabItemToName;
	NSMapTable *bothToName;
	NSString *current;
	ConnectionController *connection;
	NSFont *chatFont;
}
- initWithConnectionController: (ConnectionController *)connect;

- updatedColor: (NSString *)aKey old: (NSString *)oldValue;
- (NSColor *)colorForKey: (NSString *)aKey;

- highlightTabWithName: (NSString *)aName withColor: (NSString *)aColor
   withPriority: (BOOL)prio;

- (NSArray *)allViews;
- (NSArray *)allChannelNames;
- (NSArray *)allQueryNames;

- (BOOL)isQueryName: (NSString *)aName;
- (BOOL)isChannelName: (NSString *)aName;

- (NSTextField *)typeView;

- (NSTextField *)nickView;

- (NSTabView *)tabView;

- (NSWindow *)window;

- (NSAttributedString *)labelForViewWithName: (NSString *)aChannel;

- (NSString *)presentationNameForViewWithName: (NSString *)aChannel;

- (id)controllerForViewWithName: (NSString *)aChannel;

- (NSTabViewItem *)tabViewItemForViewWithName: (NSString *)aChannel;

- (NSString *)viewNameForTabViewItem: (NSTabViewItem *)aItem;

- (NSString *)viewNameForController: controller;

- putMessage: (id)aString in: (id)aChannel withEndLine: (BOOL)end;

- putMessage: (id)aString in: (id)aChannel;

- putMessageInAll: (id)aString withEndLine: (BOOL)end;

- putMessageInAll: (id)aString;

- addQueryWithName: (NSString *)aName withLabel: (NSAttributedString *)aLabel;

- addChannelWithName: (NSString *)aName withLabel: (NSAttributedString *)aLabel;

- setLabel: (NSAttributedString *)aLabel forViewWithName: (NSString *)aName;

- closeViewWithName: (NSString *)aName;

- renameViewWithName: (NSString *)aName to: (NSString *)newName;

- focusViewWithName: (NSString *)aName;

- (NSString *)currentViewName;

- setNickViewString: (NSString *)aNick;

- setChatFont: (NSFont *)aFont;

- (NSFont *)chatFont;
@end

#endif
