/***************************************************************************
                                DCCObject.h
                          -------------------
    begin                : Wed Jul  2 15:23:24 CDT 2003
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
 
@class DCCObject, DCCSendObject, DCCReceiveObject, NSString, NSDictionary, NSData;

NSString *BuildDCCSendRequest(NSDictionary *info);

extern NSString *DCCStatusTransferring;
extern NSString *DCCStatusError;
extern NSString *DCCStatusTimeout;
extern NSString *DCCStatusDone;
extern NSString *DCCStatusConnecting;
extern NSString *DCCStatusAborted;

extern NSString *DCCInfoFileName; //NSString
extern NSString *DCCInfoFileSize; //NSNumber 
extern NSString *DCCInfoPort;     //NSNumber
extern NSString *DCCInfoHost;     //NSHost
extern NSString *DCCInfoNick;     //NSString

#ifndef DCCOBJECT_H
#define DCCOBJECT_H
/* The DCC support's ideas(and much of the code) came mostly from
 * Juan Pablo Mendoza <jpablo@gnome.org>
 */

@protocol DCCObjectDelegateProtocol
- DCCInitiated: aConnection;
- DCCStatusChanged: (NSString *)aStatus forObject: aConnection;
- DCCReceivedData: (NSData *)data forObject: aConnection;
- DCCDone: aConnection;
- DCCNeedsMoreData: aConnection;
@end

#import <Foundation/NSObject.h>
#import <netclasses/NetBase.h>
#import <netclasses/NetTCP.h>

#include <stdint.h>

@interface DCCObject : NSObject < NetObject >
	{
		uint32_t transferredBytes;
		id delegate;
		NSString *status;
		NSDictionary *info;
		NSDictionary *userInfo;
		id transport;
	}
- initWithDelegate: aDelegate withInfo: (NSDictionary *)info
   withUserInfo: (NSDictionary *)userInfo;

- (uint32_t)transferredBytes;
- (void)abortConnection;

- (void)connectionLost;
- connectionEstablished: aTransport;
- dataReceived: (NSData *)data;
- transport;

- (NSString *)status;
- (NSDictionary *)info;
- (NSDictionary *)userInfo;
@end

@interface DCCReceiveObject : DCCObject < TCPConnecting >
	{
		id connection;
	}
- initWithReceiveOfFile: (NSDictionary *)info 
   withDelegate: aDelegate
	withTimeout: (int)seconds
	withUserInfo: (NSDictionary *)userInfo;
- connectingFailed: (NSString *)error;
- connectingStarted: (TCPConnecting *)aConnection;	
@end

@interface DCCSendObject : DCCObject
	{
		TCPPort *port;
		NSTimer *timeout;
		uint32_t blockSize;
		uint32_t confirmedBytes;
		NSMutableData *receivedData;
		NSMutableData *dataToWrite;
		BOOL noMoreData;
	}
- initWithSendOfFile: (NSString *)name
    withSize: (NSNumber *)size
	 withDelegate: aDelegate
    withTimeout: (int)seconds
    withBlockSize: (uint32_t)numBytes
    withUserInfo: (NSDictionary *)userInfo;

- writeData: (NSData *)someData;

- (uint32_t)blockSize;
@end

#endif
