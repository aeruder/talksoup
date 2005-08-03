/***************************************************************************
                            MessageOutTab.h
                          -------------------
    begin                : Tue Aug  2 23:21:01 CDT 2005
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

@class MessageOutTab;

#ifndef MESSAGE_OUT_TAB_H
#define MESSAGE_OUT_TAB_H

#import <Foundation/NSObject.h>

@class NSBundle;

#ifdef _l
	#undef _l
#endif

#define _l(X) [[NSBundle bundleForClass: [MessageOutTab class]] \
               localizedStringForKey: (X) value: nil \
               table: @"Localizable"]

@class NSAttributedString;

@interface MessageOutTab : NSObject
@end

#endif
