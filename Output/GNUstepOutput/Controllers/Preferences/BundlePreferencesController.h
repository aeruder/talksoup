/***************************************************************************
                     BundlePreferencesController.h
                          -------------------
    begin                : Sat Aug 14 19:19:30 CDT 2004
    copyright            : (C) 2004 by Andrew Ruder
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

@class BundlePreferencesController;

#ifndef BUNDLE_PREFERENCES_CONTROLLER_H
#define BUNDLE_PREFERENCES_CONTROLLER_H

#import <Foundation/NSObject.h>

@class PreferencesController;
@class NSString, NSImage;
@class NSView, NSImage;
@class NSMutableArray, NSTextView, NSTableView, NSPopUpButton;

@interface BundlePreferencesController : NSObject 
	{
		NSView *preferencesView;
		NSImage *preferencesIcon;
		NSPopUpButton *showingPopUp;
		NSTableView *loadedTable;
		NSTableView *availableTable;
		NSTextView *descriptionText;
		NSMutableArray *availData;
		NSMutableArray *loadData;
		int currentShowing;
		int currentlySelected;
		id currentTable;
		id otherTable;
	}
- (NSString *)preferencesName;
- (NSImage *)preferencesIcon;
- (NSView *)preferencesView;
- (void)activate: (PreferencesController *)aPrefs;
- (void)deactivate;
- (void)showingSelected: (id)sender;
@end

#endif
