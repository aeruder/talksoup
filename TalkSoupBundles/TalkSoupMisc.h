/***************************************************************************
                                TalkSoupMisc.h
                          -------------------
    begin                : Mon Apr  7 21:45:49 CDT 2003
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
 
#ifndef TALKSOUP_MISC_H
#define TALKSOUP_MISC_H

@class NSMutableAttributedString;

#include <Foundation/NSString.h>

@interface NSString (Separation)
- separateIntoNumberOfArguments: (int)num;
@end

NSMutableAttributedString *BuildAttributedString(id aObject, ...);

NSArray *IRCUserComponents(NSAttributedString *from);

#endif
