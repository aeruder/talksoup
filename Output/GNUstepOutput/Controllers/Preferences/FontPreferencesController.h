/***************************************************************************
                        FontPreferencesController.h
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

@class FontPreferencesController;

#ifndef FONT_PREFERENCES_CONTROLLER_H
#define FONT_PREFERENCES_CONTROLLER_H

#import <Foundation/NSObject.h>

@class NSString, NSImage;
@class NSView, NSImage;
@class PreferencesController;

@interface FontPreferencesController : NSObject 
	{
		NSView *preferencesView;
		NSImage *preferencesIcon;
	}
- (NSString *)preferencesName;
- (NSImage *)preferencesIcon;
- (NSView *)preferencesView;
- (void)activate: (PreferencesController *)aPrefs;
- (void)deactivate;
@end

#endif
