/*
copyright 2002 Alexander Malmberg <alexander@malmberg.org>
*/

#include "Label.h"

@implementation NSTextField (label)
+ newLabel: (NSString *)title
{
	NSTextField *f;
	f=[[self alloc] init];
	[f setStringValue: title];
	[f setEditable: NO];
	[f setDrawsBackground: NO];
	[f setBordered: NO];
	[f setBezeled: NO];
	[f setSelectable: NO];
	[f sizeToFit];
	return f;
}
@end
