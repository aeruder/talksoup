#import "IRCApp.h"
#import "IRCWindow.h"
#import "ServersManager.h"
#import "Preferences/PreferencesWindowController.h"
#import "Preferences/GeneralPrefs.h"

static ServersManager *ircServers=NULL;
static NSMutableArray *activeServerWindows=NULL;

@implementation IRCApp 
+(void)initialize
{
    activeServerWindows=[[NSMutableArray alloc] init];
    ircServers=[[ServersManager alloc] init];
};
+(void)connectToServer:(NSString *)server
                onPort:(int)port
           withTimeout:(int)timeout
         withNicknames:(NSArray *)nicks
{
    IRCWindowController *iwc;
    
    if(!nicks);
    iwc =[[IRCWindowController alloc] init];
    [iwc showWindow:nil];
    [iwc connectToServer: server
	              onPort: port
             withTimeout: timeout
           withNicknames: nicks
            withUserName: nil
            withRealName: nil
            withPassword: nil];

    [activeServerWindows addObject:iwc];
};
-(id)init
{
    NSLog (@"Enter - init");

    if((self =[super init]))
    {
        NSObject<PrefBox> *pb;
        
        pwc=[[PreferencesWindowController alloc] init];
        
        pb=[[GeneralPrefs alloc] init];
        [pwc addPrefBox: pb];
        DESTROY(pb);
    }

    return self;
}
-(void)dealloc
{
    NSLog (@"Enter - dealloc");

  /*  if (serversWindow != nil)
        [serversWindow release];*/
    if (ircServers != nil)
        [ircServers release];
    if (pwc)
        [pwc release];

    [super dealloc];
}
-(void)applicationWillFinishLaunching:(NSNotification *) notif
{
    NSMenu *menu, *tmp;

    menu=[[NSMenu alloc] init];
    tmp=[[NSMenu alloc] init];
    [tmp addItemWithTitle: @"Info..." 
                   action: @selector(orderFrontStandardInfoPanel:)
            keyEquivalent: nil];
    [tmp addItemWithTitle: @"Preferences..."
                   action: @selector(openPreferencesWindow:)
            keyEquivalent: nil];
    [menu setSubmenu: tmp 
             forItem: [menu addItemWithTitle: @"Info" 
                                      action: (SEL)nil 
                               keyEquivalent: nil]];
    [tmp release];

    tmp=[[NSMenu alloc] init];
    [tmp addItemWithTitle: @"Connect to.."
                   action: @selector(showServersWindow:)
            keyEquivalent: nil];
    [menu setSubmenu: tmp 
             forItem: [menu addItemWithTitle: @"Server" 
                                      action: (SEL)nil 
                               keyEquivalent: nil]];
    [tmp release];

    [menu addItemWithTitle: @"Hide" 
                    action: @selector(hide:)
             keyEquivalent: @"h"];
    [menu addItemWithTitle: @"Quit" 
                    action: @selector(terminate:)
             keyEquivalent: @"q"];
    [NSApp setMainMenu:menu];
    
    [menu release];
}
-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSLog (@"Enter - applicationDidFinishLaunching:");
}
-(void)openPreferencesWindow:(id)sender
{
    [pwc showWindow: self];
    NSLog(@" Preferences open");

};
-(void)showServersWindow:(id)sender
{
    if(ircServers != nil)    
    {
        NSLog(@"Entering showServersWindow");
        [ircServers showWindow];
    }
        NSLog(@"leaving showServersWindow");
};
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    NSLog(@"Enter App will terminate");
    
    [activeServerWindows makeObjectsPerformSelector:@selector(release)];    
};
@end
