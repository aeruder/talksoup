/***************************************************************************
                             PrivateBeep.h
                          -------------------
    begin                : Tue Aug  9 00:54:55 CDT 2005
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

@class PrivateBeep;

#ifndef PRIVATE_BEEP_H
#define PRIVATE_BEEP_H

#import <Foundation/NSObject.h>

@class NSBundle;

#ifdef _l
	#undef _l
#endif

#define _l(X) [[NSBundle bundleForClass: [PrivateBeep class]] \
               localizedStringForKey: (X) value: nil \
               table: @"Localizable"]

@class NSAttributedString;

@interface PrivateBeep : NSObject
@end

#endif
