/***************************************************************************
                        BundleConfigureController.h
                          -------------------
    begin                : Mon Sep  8 00:16:46 CDT 2003
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

@class BundleConfigureController;

#ifndef BUNDLE_CONFIGURE_CONTROLLER_H
#define BUNDLE_CONFIGURE_CONTROLLER_H

#import <Foundation/NSObject.h>

@class NSPopUpButton, NSTableView, NSTextView, NSWindow;
@class NSTableColumn, NSButton, NSImage;

@interface BundleConfigureController : NSObject
	{
		NSButton *middleButton;
		NSButton *upButton;
		NSButton *downButton;
		NSPopUpButton *showingPopUp;
		NSTableView *loadedTable;
		NSTableView *availableTable;
		NSTextView *descriptionText;
		NSWindow *window;
		NSTableColumn *availCol;
		NSTableColumn *loadCol;
		id loadData[2];
		id availData[2];
		id defaults[2];
		int currentShowing;
		id currentTable;
		id otherTable;
		NSImage *upImage;
		NSImage *downImage;
		NSImage *leftImage;
		NSImage *rightImage;
	}

- (NSWindow *)window;

- (void)upHit: (id)sender;
- (void)refreshHit: (id)sender;
- (void)downHit: (id)sender;
- (void)middleHit: (id)sender;
- (void)showingSelected: (id)sender;

@end

#endif
