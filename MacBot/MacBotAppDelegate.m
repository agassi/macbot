#import "MacBotAppDelegate.h"

@implementation MacBotAppDelegate

@synthesize window;
@synthesize easyInstall;

@synthesize jarLocation;
@synthesize scriptLocation;
@synthesize compileButton;

@synthesize jarPath;
@synthesize scriptPath;
@synthesize scriptPaths;

- (IBAction) performEasyInstall: (id)sender {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    NSError* error;
    
	NSInteger result = [openPanel runModal];
    
	if (result != NSFileHandlingPanelOKButton) {
        return;
	}
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    NSString *directory = [NSString stringWithFormat:@"%@%@", [[openPanel URL] path], @"/RSBot"];

    if(![fileManager fileExistsAtPath:directory isDirectory:&isDir]) {
        [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    NSString *command = [NSString stringWithFormat:@"%@/%@/%@", @"/usr/bin/curl -L --referer http://www.powerbot.org/ http://www.powerbot.org/download/ -o ", directory, @"/RSBot.jar"];
    system([command UTF8String]);
    
    NSString *src = [NSString stringWithFormat:@"%@%@", directory, @"/src"];
    if(![fileManager fileExistsAtPath:src isDirectory:&isDir]) {
        [fileManager createDirectoryAtPath:src withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    NSString *bin = [NSString stringWithFormat:@"%@%@", directory, @"/bin"];
    if(![fileManager fileExistsAtPath:bin isDirectory:&isDir]) {
        [fileManager createDirectoryAtPath:bin withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    NSString *shell = @"#!/bin/bash\nDIR=\"$( cd \"$( dirname \"$0\" )\" && pwd )\"\ncd \"$DIR\"\njava -jar -Xmx1024m RSBot.jar -dev";
    [shell writeToFile:[NSString stringWithFormat:@"%@%@", directory, @"/RSBot"] atomically:YES encoding:NSASCIIStringEncoding error:&error];
    NSDictionary *attributes;
    NSNumber *permissions;
    permissions = [NSNumber numberWithUnsignedLong: 493];
    attributes = [NSDictionary dictionaryWithObject:permissions forKey:NSFilePosixPermissions];
    
    // This actually sets the permissions
    [fileManager setAttributes:attributes ofItemAtPath:[NSString stringWithFormat:@"%@%@", directory, @"/RSBot"] error:&error];
    
    if (error == nil) {
        easyInstall.title = @"Success!";
    } else {
        easyInstall.title = [error description];
    }
}

- (IBAction) chooseJar: (id)sender {
    NSArray *filetypes = [NSArray arrayWithObjects:@"jar", nil];
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:filetypes];
    
    if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
        jarPath = [NSString stringWithString:[[openPanel URL] path]];
        jarLocation.title = jarPath;
	}
}

- (IBAction) chooseScript: (id)sender {
    NSArray *filetypes = [NSArray arrayWithObjects:@"java", nil];
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:filetypes];
    
    if ([openPanel runModal] != NSFileHandlingPanelOKButton) {
        return;
	}
    
    NSArray* urls = [openPanel URLs];
    if ([urls count] < 2) {
        scriptPaths = nil;
        scriptPath = [NSString stringWithString:[[urls objectAtIndex:0] path]];
        scriptLocation.title = scriptPath;
        return;
    }
    
    scriptPath = nil;
    [self setScriptPaths:urls];
    scriptLocation.title = @"Multiple Scripts";
}

- (IBAction) performCompile: (id)sender {
    if (jarPath == nil) {
        compileButton.title = @"Choose RSBot.jar";
        return;
    }
    
    if (scriptPath == nil && scriptPaths == nil) {
        compileButton.title = @"Choose Script(s)";
        return;
    }

    NSString *parent = [[[NSURL fileURLWithPath:jarPath] URLByDeletingLastPathComponent] path];
    NSString *currentDirectoryPath;
    
    NSArray *array;
    if (scriptPath == nil) {
        currentDirectoryPath = [NSString stringWithString:[[[scriptPaths objectAtIndex:0] URLByDeletingLastPathComponent] path]];
        array = scriptPaths;
    } else {
        currentDirectoryPath = [NSString stringWithString:[[[NSURL fileURLWithPath:scriptPath] URLByDeletingLastPathComponent] path]];
        array = [NSArray arrayWithObjects:[NSURL fileURLWithPath:scriptPath], nil];
    }
    
    NSMutableString *message = [[NSMutableString alloc] init];
    int count = 0;
    for (NSURL* url in array) {
        NSTask *task;
        task = [[NSTask alloc] init];
        [task setLaunchPath: @"/usr/bin/javac"];
        [task setCurrentDirectoryPath:currentDirectoryPath];
        
        NSArray *arguments;
        // javac -cp ../RSBot.jar -d ../bin *.java
        arguments = [NSArray arrayWithObjects: @"-cp", jarPath, @"-d", [NSString stringWithFormat:@"%@%@", parent, @"/bin"], [[url path] lastPathComponent], nil];
        [task setArguments: arguments];
        
        NSPipe *pipe;
        pipe = [NSPipe pipe];
        [task setStandardError: pipe];
        [task setStandardInput:[NSPipe pipe]];
        
        NSFileHandle *file;
        file = [pipe fileHandleForReading];
        
        [task launch];
        
        NSData *data;
        data = [file readDataToEndOfFile];
        
        NSString *string;
        string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        [message appendString:string];
        if ([string length] > 0) {
            count = count + 1;
        }
        
        [string release];
        [task release];
    }
    
    if ([message length] == 0) {
        compileButton.title = @"Success!";
    } else {
        [message writeToFile:[NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Desktop/macbot_log.txt"] atomically:YES encoding:NSASCIIStringEncoding error:NULL];
        compileButton.title = [NSString stringWithFormat:@"%d%@", count, @" Failed - Check macbot_log.txt on Desktop"];
    }
    
    [message release];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
}

- (void)awakeFromNib {
	[window setDelegate:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

@end
