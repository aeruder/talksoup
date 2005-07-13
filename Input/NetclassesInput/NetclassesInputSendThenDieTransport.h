/***************************************************************************
                      NetclassesInputSendThenDieTransport.h       
                          -------------------
    begin                : Wed Jul 13 02:25:28 CDT 2005
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

@class NetclassesInputSendThenDieTransport;

#import <netclasses/NetBase.h>

@class NSData;

@interface NetclassesInputSendThenDieTransport : NSObject <NetTransport>
	{
		id <NetTransport>realTransport;
		id <NetObject>dieObject;
	}
- initWithTransport: (id <NetTransport>)aTransport;

- (void)writeThenCloseForObject: (id <NetObject>)aObject;

- (id)localHost;
- (id)remoteHost;
- writeData: (NSData *)data;
- (BOOL)isDoneWriting;
- (NSData *)readData: (int)maxReadSize;
- (int)desc;
- (void)close;
@end
