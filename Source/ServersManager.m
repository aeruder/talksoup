#import <Foundation/NSString.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSUserDefaults.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSScroller.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/GSHbox.h>
#import <AppKit/GSVbox.h>
#import <AppKit/NSOutlineView.h>
#import <AppKit/NSTableColumn.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDictionary.h>
#import <string.h>

#import "ServersManager.h"
#import "ServerInfo.h"
#import "Preferences/GeneralPrefs.h" 
#import "IRCApp.h"

const NSString *IRCServersColumnIdentifier = @"Irc Server";

@implementation ServersManager
-(id)init
{
    GSVbox *vbox;
    NSOutlineView *serversView;
    NSTableColumn *serversColumn;
    NSScrollView  *scrollView;
                
    if([super init] != nil)
    {
        groups=[[NSMutableArray alloc] init];
        [self readDefaultServerList];
        win=[NSWindow alloc];
        [win initWithContentRect: NSMakeRect(150, 150, 400,265)
                       styleMask: NSClosableWindowMask  |
                                  NSTitledWindowMask    |
                                  NSResizableWindowMask |
                                  NSMiniaturizableWindowMask
                         backing: NSBackingStoreRetained
                           defer: YES];
        [win setFrameUsingName:@"Servers Window"];
        [win setTitle: @"Double click a server to connect...."];
         [win setHidesOnDeactivate: YES];
         [win setReleasedWhenClosed: NO];
    
        vbox=[[GSVbox alloc] init];
        [vbox setDefaultMinYMargin:0];
        [vbox setAutoresizingMask: NSViewWidthSizable |
                                   NSViewHeightSizable];
        [vbox setAutoresizesSubviews:YES];
        [vbox setBorder:0];

        serversColumn=[[NSTableColumn alloc]
                        initWithIdentifier:(id)IRCServersColumnIdentifier];
        [serversColumn setEditable: NO];
        [[serversColumn headerCell] setStringValue: @"Servers"];
        [serversColumn setMinWidth: 270];

        serversView=[[NSOutlineView alloc] initWithFrame: 
                                            NSMakeRect(0,0,340,125)];
        [serversView sizeToFit];
        [serversView addTableColumn: serversColumn];
        [serversView setOutlineTableColumn: serversColumn];
        [serversView setDrawsGrid: NO];
        [serversView setIndentationPerLevel:25];

        scrollView=[[NSScrollView alloc] init];
        [scrollView setHasHorizontalScroller: YES];
        [scrollView setHasVerticalScroller: YES];
        [scrollView setDocumentView: serversView];
        [scrollView setAutoresizingMask: NSViewWidthSizable|
                                         NSViewHeightSizable];

        [serversView setTarget:self];
        [serversView setDoubleAction:@selector(testing:)];

        [serversView setDataSource: self];

        [vbox addView: scrollView];

        [win setContentView:vbox];
        RELEASE(scrollView);     
    }
    return self;
};
-(void)dealloc
{
    if(groups!=nil) [groups release]; 
    [super dealloc];
};
-(int)readDefaultServerList
{
    FILE *file;
    char filename[512],C;
    char buffer[512];
    int x;
    NSMutableArray *serverList;
    ServerInfo *serverInfo;
    GroupInfo *groupInfo;

    serverInfo=nil;
    serverList=nil;
    
    strcpy(filename,[[[NSBundle mainBundle] resourcePath] cString]);
    strcat(filename,"/Serverlist.txt");
    
    if((file=fopen(filename,"r")) != NULL)
    {
        while(!feof(file))
        {
            C=fgetc(file);
            if(C=='G')
            {
                fgetc(file);
                x=0;
                while((buffer[x]=fgetc(file))!='\n') x++;
                buffer[x]=0;
                C=fgetc(file);
                groupInfo=[[GroupInfo alloc] init];
                [groupInfo setName:[NSString stringWithCString:buffer]];
                [groups addObject:groupInfo];
                serverList=[groupInfo getServers];
            }
            if(C=='S')
            {
                serverInfo=[[ServerInfo alloc] init];
                fgetc(file);
                x=0;
                while((buffer[x]=fgetc(file))!='\n') x++;
                buffer[x]=0;
                [serverInfo setServerName:buffer];
                x=0;
                while((buffer[x]=fgetc(file))!='\n') x++;
                buffer[x]=0;
                [serverInfo setPort:atoi(buffer)];
                x=0;
                while((buffer[x]=fgetc(file))!='\n') x++;
                buffer[x]=0;
                [serverInfo setChannel:buffer];
                x=0;
                while((buffer[x]=fgetc(file))!='\n') x++;
                buffer[x]=0;
                [serverInfo setPassword:buffer];
                x=0;
                while((buffer[x]=fgetc(file))!='\n') x++;
                buffer[x]=0;
                [serverInfo setNick:buffer];
                x=0;
                while(((buffer[x]=fgetc(file))!='\n') && (!feof(file))) x++;
                buffer[x]=0;
                [serverInfo setComment:buffer];
                [serverList addObject:serverInfo];
            };
        };
        
        fclose(file);
    }

    return 0;
};
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
{
    static GroupInfo *group;

    if(item == nil)
        return [groups count];

    group=(GroupInfo *)item;
    
    if([item class] == [GroupInfo class])
        return [[group getServers] count];

    return 0;
};
- (id)outlineView:(NSOutlineView *)outlineView
            child:(int)index
           ofItem:(id)item
{
    static GroupInfo *group;
   
    if(item == nil)
        return [groups objectAtIndex:index];

    group=(GroupInfo *)item;
    
    return [[group getServers] objectAtIndex:index];
};
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if([item class]==[GroupInfo class])
        return YES;

    return NO;
}
- (id)outlineView:(NSOutlineView *)outlineView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
                       byItem:(id)item
{
    return [item getName];
};
-(void) testing:(id) sender
{
    id item;
    NSArray *nicks;

    NSLog(@" El item es: %@", sender);
    item=[sender itemAtRow:[sender selectedRow]];

    if([sender isExpandable:item])
    {
        if([sender isItemExpanded:item])
            [sender collapseItem:item];
        else
            [sender expandItem:item];
        return;
    }
    
    nicks=[GeneralPrefs getDefaultNicks];
    [IRCApp connectToServer:[item getName]
                     onPort:[item getPort]
                withTimeout:30
              withNicknames:nicks];
    [win saveFrameUsingName:@"Servers Window"];
    [win orderOut:nil];
}
-(void)showWindow
{
    [win orderFrontRegardless];
};
-(id)getServersWindow
{
    return win;
};
@end
