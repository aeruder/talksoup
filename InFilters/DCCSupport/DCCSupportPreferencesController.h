/***************************************************************************
                                DCCSupportPreferencesController.h
                          -------------------
    begin                : Wed Jan  7 20:54:25 CST 2004
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

@class DCCSupportPreferencesController;

#ifndef DCC_SUPPORT_PREFERENCES_CONTROLLER
#define DCC_SUPPORT_PREFERENCES_CONTROLLER

#import <Foundation/NSObject.h>

@class NSWindow, NSTextField, NSButton, NSImage;
@class NSView;

@interface DCCSupportPreferencesController : NSObject
	{
		NSTextField *blockSizeField;
		NSTextField *portRangeField;
		NSTextField *changeCompletedField;
		NSTextField *changeDownloadField;
		NSTextField *changeCompletedButton;
		NSTextField *changeDownloadButton;
		NSView *window;
		NSImage *preferencesIcon;
		BOOL isActive;
	}

- (void)reloadData;

- (void)changeCompletedHit: (NSButton *)sender;
- (void)changeDownloadHit: (NSButton *)sender;
- (void)blockSizeHit: (NSTextField *)sender;
- (void)portRangeHit: (NSTextField *)sender;

@end

#endif
