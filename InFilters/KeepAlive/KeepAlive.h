/***************************************************************************
                             KeepAlive.h
                          -------------------
    begin                : Sat May 10 18:58:30 CDT 2003
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

@class KeepAlive;

#ifndef KEEP_ALIVE_H
#define KEEP_ALIVE_H

#import <Foundation/NSObject.h>

@class NSAttributedString, NSTimer;

@interface KeepAlive : NSObject
	{
		NSTimer *timer;
	}
- pluginActivated;

- pluginDeactivated;
@end

#endif
