#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSTextField.h>
#import <AppKit/GSVbox.h>
#import <AppKit/GSHbox.h>
#import <AppKit/GSTable.h>

#import "GeneralPrefs.h"

static NSUserDefaults *ud=NULL;

static NSString *nick;
static NSString *alternateNick;
@implementation GeneralPrefs
+(NSArray *) getDefaultNicks
{
    return [NSArray arrayWithObjects:[NSString stringWithString:nick],
                                     [NSString stringWithString:alternateNick],
                                     nil];
};
+(void) initialize
{
    if (!ud)
    {
        ud=[NSUserDefaults standardUserDefaults];
        nick=[ud stringForKey:@"nick"];
        alternateNick=[ud stringForKey:@"alternateNick"];
        if(!nick)
        {
            nick=@"ChangeMe";
            [ud setObject:nick forKey:@"nick"];
        }
        if(!alternateNick)
        {
            alternateNick=@"ChangeMeToo";
            [ud setObject:alternateNick forKey:@"alternateNick"];
        }
    }
}

-(void) save
{
    [ud setObject:[alternateNickField stringValue] forKey:@"alternateNick"];
    [ud setObject:[nickField stringValue] forKey:@"nick"];
};
-(void) revert
{
};
-(NSString *) name
{
    return @"General";
};
-(void) setupButton: (NSButton *)b
{
    [b setTitle: _(@"General")];
    [b sizeToFit];
}
-(void) willHide
{
};
-(NSView *) willShow
{
    if(!view)
    {
        GSTable *table;
        NSTextField *label;
        
        view=[[GSVbox alloc] init];
        [view setDefaultMinYMargin: 8];

        [view addView: [[[NSView alloc] init] autorelease] enablingYResizing: YES]; //This is for bringing all up to the top of the screen
        [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [view setAutoresizesSubviews:YES];

        table=[[GSTable alloc] initWithNumberOfRows: 2 numberOfColumns: 2];
        [table setAutoresizingMask:NSViewWidthSizable];
        [table setXResizingEnabled: NO  forColumn: 0];
        [table setXResizingEnabled: YES forColumn: 1];
        [table setAutoresizesSubviews:YES];
        label=[NSTextField newLabel:@"Primary Nick:"];
        [label setAutoresizingMask: NSViewMinXMargin|
                                    NSViewMinYMargin|
                                    NSViewMaxYMargin];
        [label sizeToFit];
        [table putView:label atRow:1 column:0];
        nickField=[[NSTextField alloc] init];
        [nickField setAutoresizingMask: NSViewWidthSizable];
        [nickField sizeToFit];
        [nickField setStringValue:nick];
        [table putView:nickField atRow:1 column:1];
        label=[NSTextField newLabel:@"Alternate Nick:"];
        [label setAutoresizingMask: NSViewMinXMargin|
                                    NSViewMinYMargin|
                                    NSViewMaxYMargin];
        [label sizeToFit];
        [table putView:label atRow:0 column:0];
        alternateNickField=[[NSTextField alloc] init];
        [alternateNickField setAutoresizingMask: NSViewWidthSizable];
        [alternateNickField sizeToFit];
        [alternateNickField setStringValue:alternateNick];
        [table putView:alternateNickField atRow:0 column:1];
        [view addView:table  enablingYResizing: NO];
    };

    return view;
};
-(void) dealloc
{
    if(view)
        DESTROY(view);
    [super dealloc];
}
@end
