/***************************************************************************
                                TabTextField.m
                          -------------------
    begin                : Thu Dec  5 15:58:14 CST 2002
    copyright            : (C) 2002 by Andy Ruder
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

#import "Views/TabTextField.h"

#import <Foundation/NSValue.h>
#import <Foundation/NSNotification.h>

@implementation TabTextField
- (void)textDidEndEditing: (NSNotification *)aNotification
{
	NSNumber *textMovement = [[aNotification userInfo] objectForKey: 
	  @"NSTextMovement"];
	
	if (!textMovement)
	{
		[super textDidEndEditing: aNotification];
	}
	else
	{
		if ([textMovement intValue] == NSTabTextMovement)
		{
			id del;
			SEL sel;
			del = [self delegate];
			sel = NSSelectorFromString(@"textFieldReceivedTab:");
			
			if (del && sel)
			{
				if ([del respondsToSelector: sel])
				{
					[del performSelector: sel withObject: self];
				}
			}
		}
		else if ([textMovement intValue] == NSBacktabTextMovement)
		{
			id del;
			SEL sel;
			del = [self delegate];
			sel = NSSelectorFromString(@"textFieldReceivedBacktab:");

			if (del && sel)
			{
				if ([del respondsToSelector: sel])
				{
					[del performSelector: sel withObject: self];
				}
			}
		}
		else
		{
			[super textDidEndEditing: aNotification];
		}
	}
}
- (BOOL) becomeFirstResponder
{
	BOOL x = [super becomeFirstResponder];

	if ([self currentEditor])
	{
		[[self currentEditor] setSelectedRange: 
		   NSMakeRange([[self stringValue] length], 0)];
	}

	return x;
}
@end
