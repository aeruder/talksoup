/***************************************************************************
                                DCCSender.h
                          -------------------
    begin                : Wed Jan  7 21:13:07 CST 2004
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

@class DCCSender;

#ifndef DCC_SENDER_H
#define DCC_SENDER_H

#import <Foundation/NSObject.h>
#include <stdint.h>

@class DCCSendObject, NSFileHandle, NSString, NSString;
@class NSTimer, NSDictionary, NSHost;

@interface DCCSender : NSObject
	{
		NSFileHandle *file;
		NSString *path;
		DCCSendObject *sender;
		NSString *status;
		NSString *receiver;
		id connection;
		id delegate;
		NSTimer *cpsTimer;
		int cps;
		uint32_t oldTransferredBytes;
	}
- initWithFilename: (NSString *)path 
    withConnection: aConnection to: (NSString *)receiver withDelegate: aDel;

- (NSString *)status;

- (NSDictionary *)info;

- (id)localHost;
- (id)remoteHost;

- (NSString *)percentDone;

- (int)cps;
- cpsTimer: (NSTimer *)aTimer;

- (NSString *)path;
- (NSString *)receiver;

- (void)abortConnection;
@end
#endif
