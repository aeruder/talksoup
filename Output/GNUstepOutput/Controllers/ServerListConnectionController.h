/***************************************************************************
                                ServerListConnectionController.h
                          -------------------
    begin                : Wed May  7 03:31:51 CDT 2003
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

#ifndef SERVER_LIST_CONNECTION_CONTROLLER_H
#define SERVER_LIST_CONNECTION_CONTROLLER_H

#import "Controllers/ConnectionController.h"

@class NSDictionary, NSNotification, NSMutableDictionary;

@interface ServerListConnectionController : ConnectionController
	{
		int serverRow;
		int serverGroup;
		NSDictionary *oldInfo;
		NSMutableDictionary *newInfo;
	}

- initWithServerListDictionary: (NSDictionary *)info
 inGroup: (int)group atRow: (int)row;
@end

#endif
