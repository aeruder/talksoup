/***************************************************************************
                     ColorPreferencesController.h
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

@class ColorPreferencesController, NSString;

extern NSString *GNUstepOutputPersonalBracketColor;
extern NSString *GNUstepOutputOtherBracketColor;
extern NSString *GNUstepOutputTextColor;
extern NSString *GNUstepOutputBackgroundColor;

#ifndef COLOR_PREFERENCES_CONTROLLER_H
#define COLOR_PREFERENCES_CONTROLLER_H

#import <Foundation/NSObject.h>

@class NSString, NSImage, PreferencesController;
@class NSColorWell, NSView, NSImage;

@interface ColorPreferencesController : NSObject 
	{
		NSColorWell *otherColorWell;
		NSColorWell *personalColorWell;
		NSColorWell *backgroundColorWell;
		NSColorWell *textColorWell;
		NSView *preferencesView;
		NSImage *preferencesIcon;
		BOOL activated;
	}
- (void)setColorPreference: (NSColorWell *)aWell;
- (NSString *)preferencesName;
- (NSImage *)preferencesIcon;
- (NSView *)preferencesView;
- (void)activate: (PreferencesController *)aPrefs;
- (void)deactivate;
@end

#endif
