/***************************************************************************
                                NetTCP.h
                          -------------------
    begin                : Fri Nov  2 01:19:16 UTC 2001
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

@class TCPSystem, TCPConnecting, TCPPort, TCPTransport;

#ifndef NET_TCP_H
#define NET_TCP_H

#include "NetBase.h"
#include <Foundation/NSObject.h>

#include <netinet/in.h>
#include <stdint.h>

@class NSString, NSNumber, NSString, NSData, NSMutableData, TCPConnecting;
@class TCPTransport, TCPSystem, NSHost;

@interface TCPSystem : NSObject
	{
		NSString *errorString;
		int errorNumber;
	}
+ sharedInstance;

- (NSString *)errorString;
- (int)errorNumber;

- (id)connectNetObject: (id)netObject toHost: (NSHost *)host 
                onPort: (uint16_t)aPort withTimeout: (int)timeout;

- (TCPConnecting *)connectNetObjectInBackground: (id)netObject
    toHost: (NSHost *)host onPort: (uint16_t)aPort withTimeout: (int)timeout;

- (NSHost *)hostFromHostOrderInteger: (uint32_t)ip;
- (NSHost *)hostFromNetworkOrderInteger: (uint32_t)ip;
@end

@protocol TCPConnecting
- connectingFailed: (NSString *)error;
- connectingStarted: (TCPConnecting *)aConnection;
@end

@interface TCPConnecting : NSObject < NetObject >
	{
		id transport;
		id netObject;
		NSTimer *timeout;
	}
- (id)netObject;
- (void)abortConnection;

- (void)connectionLost;
- connectionEstablished: aTransport;
- dataReceived: (NSData *)data;
- (id)transport;
@end

@interface TCPPort : NSObject < NetPort >
    {
		int desc;
		Class netObjectClass;
		uint16_t port;
	}
- initOnPort: (uint16_t)aPort;
- initOnHost: (NSHost *)aHost onPort: (uint16_t)aPort;

- (uint16_t)port;
- setNetObject: (Class)aClass;
- (int)desc;
- (void)connectionLost;
- newConnection;
@end

@interface TCPTransport : NSObject < NetTransport >
    {
		int desc;
		BOOL connected;
		NSMutableData *writeBuffer;
		NSHost *remoteHost;
		NSHost *localHost;
	}
- initWithDesc: (int)aDesc withRemoteHost: (NSHost *)theAddress;
- (NSData *)readData: (int)maxDataSize;
- (BOOL)isDoneWriting;
- writeData: (NSData *)data;
- (NSHost *)localHost;
- (NSHost *)remoteHost;
- (int)desc;
- (void)close;
@end

#endif
