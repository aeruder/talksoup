/***************************************************************************
                                ConnectionControllerDelegate.h
                          -------------------
    begin                : Tue May 20 18:38:20 CDT 2003
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

#ifndef CONNECTION_CONTROLLER_DELEGATE_H
#define CONNECTION_CONTROLLER_DELEGATE_H

#include "Controllers/ConnectionController/ConnectionController.h"

@interface ConnectionController (TableViewTarget)
@end

@interface ConnectionController (ApplicationDelegate)
@end

@interface ConnectionController (WindowDelegate)
@end

#endif
