/***************************************************************************
                                TalkSoupPrivate.h
                          -------------------
    begin                : Tue Oct 14 18:03:57 CDT 2003
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

#ifndef TALKSOUP_PRIVATE_H
#define TALKSOUP_PRIVATE_H

#import "TalkSoup.h"

#ifdef _l
#undef _l
#endif

#define _l(_X) ([[NSBundle bundleForClass: [TalkSoup class]]  \
  localizedStringForKey: (_X) value: (_X) table: nil])

#endif
