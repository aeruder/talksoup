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

#include <Foundation/NSObject.h>

@class NSPopUpButton, NSTableView, NSTextView, NSWindow;
@class NSTableColumn;

@interface BundleConfigureController : NSObject
	{
		NSPopUpButton *showingPopUp;
		NSTableView *loadedTable;
		NSTableView *availableTable;
		NSTextView *descriptionText;
		NSWindow *window;
		NSTableColumn *availCol;
		NSTableColumn *loadCol;
		id loadData[2];
		id availData[2];
	}

- (NSWindow *)window;

- (void)upHit: (id)sender;
- (void)refreshHit: (id)sender;
- (void)cancelHit: (id)sender;
- (void)okHit: (id)sender;
- (void)downHit: (id)sender;
- (void)leftHit: (id)sender;
- (void)rightHit: (id)sender;
- (void)showingSelected: (id)sender;

@end

#endif
