/***************************************************************************
                                Functions.h
                          -------------------
    begin                : Mon Apr 28 02:10:41 CDT 2003
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

#import <Foundation/NSObject.h>

@class NSAttributedString, NSString;

inline NSAttributedString *NetClasses_AttributedStringFromString(NSString *str);
inline NSString *NetClasses_StringFromAttributedString(NSAttributedString *atr);


