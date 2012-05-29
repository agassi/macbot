#import <Cocoa/Cocoa.h>

@interface MacBotAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (retain) IBOutlet NSButton *easyInstall;

@property (retain) IBOutlet NSButton *jarLocation;
@property (retain) IBOutlet NSButton *scriptLocation;
@property (retain) IBOutlet NSButton *compileButton;

@property (copy) NSString *jarPath;
@property (copy) NSString *scriptPath;
@property (copy) NSArray  *scriptPaths;

- (IBAction) performEasyInstall: (id)sender;

- (IBAction) chooseJar: (id)sender;
- (IBAction) chooseScript: (id)sender;
- (IBAction) performCompile: (id)sender;

@end
