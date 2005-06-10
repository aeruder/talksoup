/***************************************************************************
                                HighlightingPreferencesController.h
                          -------------------
    begin                : Mon Dec 29 12:11:34 CST 2003
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

#import <Foundation/NSObject.h>

@class NSButton, NSTableView, NSWindow, NSColorWell;
@class NSMutableArray, NSView, NSImage;

@interface HighlightingPreferencesController : NSObject
	{
		NSButton *highlightButton;
		NSButton *removeButton;
		NSTableView *extraTable;
		NSView *window;
		NSColorWell *highlightInChannelColor;
		NSColorWell *highlightInTabColor;
		NSColorWell *messageInTabColor;
		NSMutableArray *extraNames;
		NSImage *preferencesIcon;
		int currentlySelected;
		BOOL isActive;
	}
- (void)reloadData;
- (NSView *)preferencesView;
- (NSImage *)preferencesIcon;
- (NSString *)preferencesName;
- (void)activate: aPrefs;
- (void)deactivate;

- (void)highlightingHit: (id)sender;
- (void)removeHit: (id)sender;
- (void)highlightInChannelHit: (id)sender;
- (void)highlightInTabHit: (id)sender;
- (void)messageInTabHit: (id)sender;
@end

