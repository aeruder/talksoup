/***************************************************************************
                                NetBase.h
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

@class NetApplication;

#ifndef NET_BASE_H
#define NET_BASE_H

#include <Foundation/NSObject.h>
#include <Foundation/NSRunLoop.h>

#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

@class NSData, NSNumber, NSMutableDictionary, NSDictionary, NSArray;
@class NSMutableArray, NSString;

@protocol NetObject
- (void)connectionLost;
- connectionEstablished: aTransport;
- dataReceived: (NSData *)data;
- transport;
@end

@protocol NetPort
- setNetObject: (Class)aClass;
- (void)connectionLost;
- newConnection;
- (int)desc;
@end

@protocol NetTransport
- (id)address;
- writeData: (NSData *)data;
- (BOOL)isDoneWriting;
- (NSData *)readData: (int)maxReadSize;
- (int)desc;
- (void)close;
@end

extern NSString *NetException;
extern NSString *FatalNetException;

@interface NetApplication : NSObject < RunLoopEvents >
	{
		NSMutableArray *portArray;
		NSMutableArray *netObjectArray;
		NSMutableArray *badDescs;
		fd_set readSet;
		fd_set writeSet;
		fd_set exceptionSet;
		NSMapTable *descTable;
	}
+ sharedInstance;
- (NSDate *)timedOutEvent: (void *)data 
                     type: (RunLoopEventType)type
                  forMode: (NSString *)mode;
- (void)receivedEvent: (void *)data
                  type: (RunLoopEventType)type
                 extra: (void *)extra
               forMode: (NSString *)mode;
													 
- transportNeedsToWrite: aTransport;

- connectObject: anObject;
- disconnectObject: anObject;
- closeEverything;
@end

#endif
