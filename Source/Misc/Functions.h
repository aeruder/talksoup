/***************************************************************************
                                Functions.h
                          -------------------
    begin                : Sun Oct 13 20:13:10 CDT 2002
    copyright            : (C) 2002 by Andy Ruder
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

#import <Foundation/NSString.h>

@class NSAttributedString;

@interface NSString (ColorCodes)
- (NSAttributedString *)attributedStringFromColorCodedString;
@end

@interface NSString (ContainsSpace)
- (BOOL)containsSpace;
@end
