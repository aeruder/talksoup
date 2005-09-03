/***************************************************************************
                                Encodings.h
                          -------------------
    begin                : Sat Sep  3 15:18:19 CDT 2005
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

#ifndef TALKSOUP_BUNDLES_ENCODINGS_H
#define TALKSOUP_BUNDLES_ENCODINGS_H

#import "TalkSoup.h"
#import <Foundation/NSString.h>

@class NSArray;

@interface TalkSoup (Encodings)
- (NSStringEncoding)encodingForName: (NSString *)aName;
- (NSString *)nameForEncoding: (NSStringEncoding)aEncoding;

- (NSArray *)allEncodingNames;
- (NSArray *)allEncodingIdentifiers;
- (const NSStringEncoding *)allEncodings;

- (NSString *)identifierForEncoding: (NSStringEncoding)aEncoding;
- (NSStringEncoding)encodingForIdentifier: (NSString *)aIdentifier;
@end

#endif
