/***************************************************************************
                                PreferencesController.h
                          -------------------
    begin                : Thu Apr  3 08:09:15 CST 2003
    copyright            : (C) 2005 by Andrew Ruder
	                       w/ much of the code borrowed from Preferences.app
						   by Jeff Teunissen
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

@class PreferencesController, NSString;

extern NSString *GNUstepOutputServerList;
extern NSString *GNUstepOutputFontSize;
extern NSString *GNUstepOutputScrollBack;

#ifndef PREFERENCES_CONTROLLER_H
#define PREFERENCES_CONTROLLER_H

#import <Foundation/NSObject.h>

@class NSView, NSString, NSImage, NSBox;
@class NSScrollView, NSWindow, NSMatrix, NSMutableArray;
@class NSDictionary, NSMutableDictionary;

/* object: the preferences module */
extern NSString *PreferencesModuleAdditionNotification;

/* object: the preferences module */
extern NSString *PreferencesModuleRemovalNotification;

@protocol GNUstepOutputPrefsModule
- (NSView *)preferencesView;
- (NSImage *)preferencesIcon;
- (NSString *)preferencesName;
- (void)activate: (PreferencesController *)aPrefs;
- (void)deactivate;
@end

@interface PreferencesController : NSObject
	{
		NSScrollView *scrollView;
		NSWindow *window;
		NSMatrix *prefsList;
		NSView *preferencesView;
		NSMutableArray *prefsModules;
		id currentPrefs;
		NSMutableDictionary *defaultPreferences;
		NSBox *labelBox;
	}

- (id)preferenceForKey: (NSString *)aKey;
- setPreference: (id)aPreference forKey: (NSString *)aKey;
- (id)defaultPreferenceForKey: (NSString *)aKey;

- (NSWindow *)window;
@end

#endif
