/***************************************************************************
                                Highlighting.h
                          -------------------
    begin                : Fri May  2 16:48:50 CDT 2003
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

@class Highlighting;

#ifndef HIGHLIGHTING_H
#define HIGHLIGHTING_H

#include <Foundation/NSObject.h>

@class NSAttributedString;

@interface Highlighting : NSObject
- sendMessage: (NSAttributedString *)message to: (NSAttributedString *)receiver
   onConnection: aConnection sender: aPlugin;

- sendNotice: (NSAttributedString *)message to: (NSAttributedString *)receiver
   onConnection: aConnection sender: aPlugin;

- sendAction: (NSAttributedString *)anAction to: (NSAttributedString *)receiver
   onConnection: aConnection sender: aPlugin;
@end


#endif
