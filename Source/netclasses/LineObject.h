/***************************************************************************
                                LineObject.h
                          -------------------
    begin                : Thu May 30 02:19:30 UTC 2002
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

#import "NetBase.h"
#import <Foundation/NSObject.h>

@class NSMutableData, NSData;

/* This is used for line-buffered connections (end in \r\n or just \n).
 * To use, simply override lineReceived:  By default, LineObject does 
 * absolutely nothing with lineRecieved except throw the line away.
 * Use line object if you simply want line-buffered input.  This can be used
 * on IRC, telnet, etc.
 */

@interface LineObject : NSObject < NetObject >
	{
		id transport;
		NSMutableData *_readData;
	}
- (void)connectionLost;
- connectionEstablished: aTransport;
- dataReceived: (NSData *)newData;
- transport;

- lineReceived: (NSData *)line;
@end
