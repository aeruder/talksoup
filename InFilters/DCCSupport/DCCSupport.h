/***************************************************************************
                             DCCSupport.h
                          -------------------
    begin                : Wed Jul 2 18:58:30 CDT 2003
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

@class DCCSupport;

@class NSBundle;

#ifdef _l
	#undef _l
#endif

#define _l(X) [[NSBundle bundleForClass: [DCCSupport class]] \
               localizedStringForKey: (X) value: nil \
               table: @"Localizable"]

#ifndef DCCSUPPORT_H
#define DCCSUPPORT_H

#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>

@class NSAttributedString, NSMutableArray;

@interface DCCSupport : NSObject
	{
		NSMapTable *connectionMap;
	}
- CTCPRequestReceived: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)argument 
   to: (NSAttributedString *)receiver
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;
@end

#endif
