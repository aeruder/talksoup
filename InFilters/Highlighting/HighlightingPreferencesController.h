/***************************************************************************
                                HighlightingPreferencesController.h
                          -------------------
    begin                : Mon Dec 29 12:11:34 CST 2003
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

#import <Foundation/NSObject.h>

@class NSButton, NSTableView, NSWindow, NSColorWell;
@class NSMutableArray;

@interface HighlightingPreferencesController : NSObject
	{
		NSButton *highlightButton;
		NSButton *removeButton;
		NSTableView *extraTable;
		NSWindow *window;
		NSColorWell *highlightInChannelColor;
		NSColorWell *highlightInTabColor;
		NSColorWell *messageInTabColor;
		NSMutableArray *extraNames;
		int currentlySelected;
	}
- (void)reloadData;
#ifdef USE_APPKIT
- (void)shouldDisplay;
- (void)shouldHide;

- (void)highlightingHit: (id)sender;
- (void)removeHit: (id)sender;
- (void)highlightInChannelHit: (id)sender;
- (void)highlightInTabHit: (id)sender;
- (void)messageInTabHit: (id)sender;
#endif
@end

