/***************************************************************************
                             KeepAlive.h
                          -------------------
    begin                : Sat May 10 18:58:30 CDT 2003
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

@class KeepAlive;

#ifndef KEEP_ALIVE_H
#define KEEP_ALIVE_H

#import <Foundation/NSObject.h>

@class NSBundle;

#ifdef _l
	#undef _l
#endif

#define _l(X) [[NSBundle bundleForClass: [KeepAlive class]] \
               localizedStringForKey: (X) value: nil \
               table: @"Localizable"]

@class NSAttributedString, NSTimer;

@interface KeepAlive : NSObject
	{
		NSTimer *timer;
	}
- pluginActivated;

- pluginDeactivated;
@end

#endif
