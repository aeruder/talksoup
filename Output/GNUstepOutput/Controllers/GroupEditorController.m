/***************************************************************************
                                GroupEditorController.m
                          -------------------
    begin                : Tue May  6 14:34:46 CDT 2003
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

#include "Controllers/GroupEditorController.h"

#include <Foundation/NSString.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSButton.h>

@implementation GroupEditorController
- (void)awakeFromNib
{
	[window makeKeyAndOrderFront: nil];
	[window makeFirstResponder: entryField];
}
- (void)dealloc
{
	[entryField setDelegate: nil];
	DESTROY(extraField);
	DESTROY(okButton);
	DESTROY(window);
	DESTROY(entryField);
	
	[super dealloc];
}
- (NSButton *)okButton
{
	return okButton;
}
- (NSTextField *)extraField
{
	return extraField;
}
- (NSTextField *)entryField
{
	return entryField;
}
- (NSWindow *)window
{
	return window;
}
- (void)setEntry: (id)sender
{
	[okButton performClick: nil];
}

@end
 
