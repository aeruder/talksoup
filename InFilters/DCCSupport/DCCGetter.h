/***************************************************************************
                                DCCGetter.h
                          -------------------
    begin                : Wed Jan  7 21:08:21 CST 2004
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

@class DCCGetter;

#ifndef DCC_GETTER_H
#define DCC_GETTER_H

#import <Foundation/NSObject.h>

@class DCCObject, NSFileHandle, NSString, NSTimer;
@class NSDictionary, NSHost;

@interface DCCGetter : NSObject
	{
		NSFileHandle *file;
		NSString *path;
		DCCObject *getter;
		NSString *status;
		id connection;
		id delegate;
		NSTimer *cpsTimer;
		int cps;
		uint32_t oldTransferredBytes;
	}
- initWithInfo: (NSDictionary *)aDict withFileName: (NSString *)aPath 
    withConnection: aConnection withDelegate: aDel;

- (NSString *)status;

- (NSDictionary *)info;

- (NSHost *)localHost;
- (NSHost *)remoteHost;

- (NSString *)percentDone;

- (int)cps;
- cpsTimer: (NSTimer *)aTimer;

- (NSString *)path;

- (void)abortConnection;
@end

#endif
