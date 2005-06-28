/***************************************************************************
                         FocusNotificationTextView.h
                          -------------------
    begin                : Mon Jun 27 23:53:30 CDT 2005
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

#import "Views/KeyTextView.h"

@class FocusNotificationTextView;

@protocol FocusNotificationTextViewInformalProtocol
- (void)textViewTookFocus: (FocusNotificationTextView *)aTextView;
- (void)textViewResignedFocus: (FocusNotificationTextView *)aTextView;
@end

@interface FocusNotificationTextView : KeyTextView
@end
