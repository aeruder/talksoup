#import <math.h>
#import <AppKit/NSScroller.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSClipView.h>
#import "NetClasses/IRCObject.h"
#import "ChannelView.h"

@implementation ChannelView
-(id)getTerminalView
{
    return terminal;
}
-(void)setChannelName:(NSString *)channelName
{
    [channelName retain];

    channel=channelName;
}
-(NSString *)getChannelName
{
    return channel;
}
-(void) dealloc
{
    if(channel)
        [channel release];
}
-(id) initWithLabel:(NSString *) labelName
{
    GSHbox *hbox;
    NSScroller *scroller;
    NSFont *font;
    int scroller_width;
    float fx, fy;
    NSScrollView *scrollView;
    NSTableColumn *usersColumn;

    channel=nil;
    [super initWithIdentifier:nil];
    [self setLabel:labelName];

    font =[TerminalView terminalFont];
    fx =[font boundingRectForFont].size.width;
    fy =[font boundingRectForFont].size.height;
    scroller_width = ceil ([NSScroller scrollerWidth] / fx);

    vbox =[[GSVbox alloc] init];
    [vbox setDefaultMinYMargin:2];
    [vbox setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [vbox setAutoresizesSubviews:YES];
    [vbox setBorder:1];

    hbox =[[GSHbox alloc] init];
    [hbox setDefaultMinXMargin:0];
    [hbox setAutoresizesSubviews:YES];
    [hbox setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    scrollView=[[NSScrollView alloc] initWithFrame: NSMakeRect(0,0,120,90)];
    [scrollView setAutoresizingMask: NSViewHeightSizable|
                                     NSViewWidthSizable];
    [scrollView setHasVerticalScroller: YES];
    [scrollView setHasHorizontalScroller: NO];

    usersColumn=[[NSTableColumn alloc] initWithIdentifier: @"Users"];
    [usersColumn setEditable: NO];
    [usersColumn setResizable: YES];
    [usersColumn setWidth: 90];

    usersTableView=[NSTableView alloc];
    [usersTableView initWithFrame:[[scrollView contentView] frame]];
    [usersTableView setAllowsMultipleSelection: NO];
    [usersTableView setAllowsColumnSelection: NO];
    [usersTableView setAllowsEmptySelection: YES];
    [usersTableView setBackgroundColor:[NSColor whiteColor]];
    [usersTableView addTableColumn: usersColumn];
    [usersTableView setAutoresizesAllColumnsToFit: YES];
    [usersTableView setHeaderView: nil];
    [usersTableView setCornerView: nil];
    
    [scrollView setDocumentView: usersTableView];


    terminal=[[TerminalView alloc] init];
    [terminal setIgnoreResize:NO];
    [terminal setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];

    scroller =[[NSScroller alloc] initWithFrame:
                NSMakeRect (0, 0,[NSScroller scrollerWidth], fy)];
    [scroller setArrowsPosition:NSScrollerArrowsMaxEnd];
    [scroller setEnabled:YES];
    [scroller setAutoresizingMask:NSViewHeightSizable];

    [terminal setScroller:scroller];

    [hbox addView: scroller enablingXResizing:NO];
    [hbox addView: terminal enablingXResizing:YES];
    [hbox addView: scrollView enablingXResizing:NO];
    [vbox addView: hbox enablingYResizing:YES];

    [self setView:vbox];

    return self;
}

-(void)writeMessage:(NSString *)message 
               from:(NSString *)from
{
    [terminal writeMessage: message 
                      from: ExtractIRCNick(from)];
};

@end
