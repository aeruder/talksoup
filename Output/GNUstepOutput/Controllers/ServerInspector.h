/***************************************************************************
                                ServerInspector.h
                          -------------------
    begin                : Mon Jan 19 12:00:37 CST 2004
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

@class ServerInspector;

#ifndef SERVER_INSPECTOR_H
#define SERVER_INSPECTOR_H

#import <Foundation/NSObject.h>

@interface ServerInspector : NSObject
	{
	}

- registerMaster: (id <MasterController>)aMaster;
- unregisterMaster: (id <MasterController>)aMaster;
- reloadMaster: (id <MasterController>)aMaster;

@end

#endif
