/***************************************************************************
                                ScrollingTextView.h
                          -------------------
    begin                : Tue Nov  5 22:24:03 CST 2002
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

#import "Views/KeyTextView.h"

@interface ScrollingTextView : KeyTextView
- (void)pageUp;
- (void)pageDown;
@end
