#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong) NSWindow *window;
@property (strong) NSTask *compressionTask;
@property (strong) NSButton *stopButton;
@property (strong) NSTextField *sizeLabel;
@property (strong) NSTextField *statusLabel;
@property (strong) NSProgressIndicator *progressBar;
@property (strong) NSURL *currentInputURL;
@property (strong) NSURL *tempOutputURL;
@property (strong) NSButton *smallQualityButton;
@property (strong) NSButton *mediumQualityButton;
@property (strong) NSButton *largeQualityButton;
@property (strong) NSFileHandle *outputHandle;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    @try {
        NSLog(@"Starting application initialization...");
        
        // Create the window
        self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 300)
                                                 styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
        if (!self.window) {
            NSLog(@"Failed to create window");
            return;
        }
        
        NSLog(@"Window created successfully");
        self.window.title = @"Video Compressor";
        [self.window center];
        [self.window makeKeyAndOrderFront:nil];
        [self.window setReleasedWhenClosed:NO];
        
        // Create main stack view
        NSStackView *mainStack = [[NSStackView alloc] initWithFrame:NSMakeRect(20, 20, 360, 260)];
        if (!mainStack) {
            NSLog(@"Failed to create main stack view");
            return;
        }
        
        NSLog(@"Creating UI elements...");
        mainStack.orientation = NSUserInterfaceLayoutOrientationVertical;
        mainStack.spacing = 10;
        mainStack.alignment = NSLayoutAttributeLeading;
        [self.window.contentView addSubview:mainStack];
        
        // Create progress bar
        self.progressBar = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 360, 20)];
        self.progressBar.style = NSProgressIndicatorStyleBar;
        self.progressBar.indeterminate = NO;
        [mainStack addView:self.progressBar inGravity:NSStackViewGravityTop];
        
        // Create status label
        self.statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 360, 20)];
        self.statusLabel.editable = NO;
        self.statusLabel.bordered = NO;
        self.statusLabel.backgroundColor = [NSColor clearColor];
        self.statusLabel.stringValue = @"Select a video file to compress...";
        [mainStack addView:self.statusLabel inGravity:NSStackViewGravityTop];
        
        // Create size label
        self.sizeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 360, 20)];
        self.sizeLabel.editable = NO;
        self.sizeLabel.bordered = NO;
        self.sizeLabel.backgroundColor = [NSColor clearColor];
        self.sizeLabel.stringValue = @"";
        [mainStack addView:self.sizeLabel inGravity:NSStackViewGravityTop];
        
        // Create quality label
        NSTextField *qualityLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 100, 20)];
        qualityLabel.editable = NO;
        qualityLabel.bordered = NO;
        qualityLabel.backgroundColor = [NSColor clearColor];
        qualityLabel.stringValue = @"Quality:";
        [mainStack addView:qualityLabel inGravity:NSStackViewGravityTop];
        
        NSLog(@"Creating quality buttons...");
        // Create quality buttons stack
        NSStackView *qualityStack = [[NSStackView alloc] initWithFrame:NSMakeRect(0, 0, 360, 30)];
        qualityStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
        qualityStack.spacing = 10;
        
        // Create quality radio buttons
        self.smallQualityButton = [self createRadioButton:@"Small"];
        self.mediumQualityButton = [self createRadioButton:@"Medium"];
        self.largeQualityButton = [self createRadioButton:@"Large"];
        
        [qualityStack addView:self.smallQualityButton inGravity:NSStackViewGravityLeading];
        [qualityStack addView:self.mediumQualityButton inGravity:NSStackViewGravityLeading];
        [qualityStack addView:self.largeQualityButton inGravity:NSStackViewGravityLeading];
        
        [mainStack addView:qualityStack inGravity:NSStackViewGravityTop];
        
        // Set default quality
        [self.mediumQualityButton setState:NSControlStateValueOn];
        
        NSLog(@"Creating action buttons...");
        // Create button stack
        NSStackView *buttonStack = [[NSStackView alloc] initWithFrame:NSMakeRect(0, 0, 360, 30)];
        buttonStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
        buttonStack.spacing = 10;
        
        // Create select button
        NSButton *selectButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 100, 30)];
        selectButton.title = @"Select Video";
        selectButton.bezelStyle = NSBezelStyleRounded;
        selectButton.buttonType = NSButtonTypeMomentaryPushIn;
        [selectButton setTarget:self];
        [selectButton setAction:@selector(selectVideo)];
        [buttonStack addView:selectButton inGravity:NSStackViewGravityLeading];
        
        // Create stop button
        self.stopButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 100, 30)];
        self.stopButton.title = @"Stop";
        self.stopButton.bezelStyle = NSBezelStyleRounded;
        self.stopButton.buttonType = NSButtonTypeMomentaryPushIn;
        [self.stopButton setTarget:self];
        [self.stopButton setAction:@selector(stopCompression)];
        self.stopButton.hidden = YES;
        [buttonStack addView:self.stopButton inGravity:NSStackViewGravityLeading];
        
        [mainStack addView:buttonStack inGravity:NSStackViewGravityTop];
        
        NSLog(@"Setting up menu...");
        // Add Cmd+Q support
        NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit" 
                                                             action:@selector(terminate:) 
                                                      keyEquivalent:@"q"];
        NSMenu *appMenu = [[NSMenu alloc] init];
        [appMenu addItem:quitMenuItem];
        NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
        [appMenuItem setSubmenu:appMenu];
        NSMenu *menuBar = [[NSMenu alloc] init];
        [menuBar addItem:appMenuItem];
        [NSApp setMainMenu:menuBar];
        
        NSLog(@"Application initialization complete");
    } @catch (NSException *exception) {
        NSLog(@"CRASH: %@", exception);
        NSLog(@"Stack trace: %@", [exception callStackSymbols]);
    }
}

- (NSButton *)createRadioButton:(NSString *)title {
    @try {
        NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 80, 20)];
        button.title = title;
        button.buttonType = NSButtonTypeRadio;
        [button setTarget:self];
        [button setAction:@selector(qualityChanged:)];
        return button;
    } @catch (NSException *exception) {
        NSLog(@"Error creating radio button: %@", exception);
        return nil;
    }
}

- (void)qualityChanged:(NSButton *)sender {
    @try {
        // Turn off all buttons
        self.smallQualityButton.state = NSControlStateValueOff;
        self.mediumQualityButton.state = NSControlStateValueOff;
        self.largeQualityButton.state = NSControlStateValueOff;
        
        // Turn on the selected button
        sender.state = NSControlStateValueOn;
    } @catch (NSException *exception) {
        NSLog(@"Error in qualityChanged: %@", exception);
    }
}

- (void)selectVideo {
    @try {
        NSLog(@"Opening file selection dialog...");
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        panel.allowsMultipleSelection = NO;
        panel.canChooseDirectories = NO;
        panel.canChooseFiles = YES;
        panel.allowedFileTypes = @[@"mp4", @"mov"];
        
        [panel beginWithCompletionHandler:^(NSInteger result) {
            @try {
                if (result == NSModalResponseOK) {
                    NSLog(@"File selected: %@", panel.URLs.firstObject);
                    self.currentInputURL = panel.URLs.firstObject;
                    [self compressVideo:self.currentInputURL];
                }
            } @catch (NSException *exception) {
                NSLog(@"Error in file selection completion handler: %@", exception);
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"Error in selectVideo: %@", exception);
    }
}

- (NSString *)createTempDirectory {
    NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"VideoCompressor"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:tempDir]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"Error creating temp directory: %@", error);
            return nil;
        }
    }
    return tempDir;
}

- (void)cleanupTempFiles {
    if (self.tempOutputURL) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        [fileManager removeItemAtURL:self.tempOutputURL error:&error];
        if (error) {
            NSLog(@"Error removing temp file: %@", error);
        }
        self.tempOutputURL = nil;
    }
}

- (void)cleanupTask {
    if (self.outputHandle) {
        [self.outputHandle setReadabilityHandler:nil];
        [self.outputHandle closeFile];
        self.outputHandle = nil;
    }
    if (self.compressionTask) {
        [self.compressionTask terminate];
        self.compressionTask = nil;
    }
}

- (void)resetToInitialState {
    [self cleanupTask];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressBar setDoubleValue:0];
        [self.statusLabel setStringValue:@"Select a video file to compress..."];
        [self.sizeLabel setStringValue:@""];
        [self.stopButton setHidden:YES];
        [self cleanupTempFiles];
    });
}

- (void)stopCompression {
    [self resetToInitialState];
}

- (NSString *)formatFileSize:(NSNumber *)bytes {
    double size = [bytes doubleValue];
    NSArray *units = @[@"B", @"KB", @"MB", @"GB"];
    int unit = 0;
    while (size >= 1024 && unit < units.count - 1) {
        size /= 1024;
        unit++;
    }
    return [NSString stringWithFormat:@"%.1f %@", size, units[unit]];
}

- (void)compressVideo:(NSURL *)inputURL {
    NSString *inputPath = inputURL.path;
    
    // Create temp directory and output path
    NSString *tempDir = [self createTempDirectory];
    if (!tempDir) {
        [self resetToInitialState];
        return;
    }
    
    NSString *tempOutputPath = [tempDir stringByAppendingPathComponent:@"temp_output.mp4"];
    self.tempOutputURL = [NSURL fileURLWithPath:tempOutputPath];
    
    // Get input file size
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:inputPath error:nil];
    NSNumber *inputSize = [attributes objectForKey:NSFileSize];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.sizeLabel setStringValue:[NSString stringWithFormat:@"Original size: %@", [self formatFileSize:inputSize]]];
    });
    
    // Get the path to the bundled FFmpeg
    NSString *ffmpegPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/MacOS/ffmpeg"];
    
    NSLog(@"Input path: %@", inputPath);
    NSLog(@"Temp output path: %@", tempOutputPath);
    NSLog(@"FFmpeg path: %@", ffmpegPath);
    
    self.compressionTask = [[NSTask alloc] init];
    self.compressionTask.launchPath = ffmpegPath;
    
    // Get selected quality
    NSString *videoBitrate;
    NSString *audioBitrate;
    if (self.smallQualityButton.state == NSControlStateValueOn) {
        videoBitrate = @"1M";
        audioBitrate = @"96k";
    } else if (self.mediumQualityButton.state == NSControlStateValueOn) {
        videoBitrate = @"2M";
        audioBitrate = @"128k";
    } else {
        videoBitrate = @"4M";
        audioBitrate = @"192k";
    }
    
    // Standard settings with quality options
    self.compressionTask.arguments = @[
        @"-i", inputPath,
        @"-c:v", @"h264_videotoolbox",  // Hardware acceleration
        @"-b:v", videoBitrate,          // Video bitrate based on quality
        @"-c:a", @"aac",                // Audio codec
        @"-b:a", audioBitrate,          // Audio bitrate based on quality
        @"-y",                          // Overwrite output file
        tempOutputPath
    ];
    
    NSPipe *outputPipe = [NSPipe pipe];
    self.compressionTask.standardOutput = outputPipe;
    self.compressionTask.standardError = outputPipe;
    
    self.outputHandle = outputPipe.fileHandleForReading;
    
    [self.outputHandle setReadabilityHandler:^(NSFileHandle *handle) {
        if (!self.compressionTask) {
            [handle setReadabilityHandler:nil];
            return;
        }
        
        NSData *data = [handle availableData];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"FFmpeg output: %@", output);
        
        // Parse FFmpeg output for progress
        if ([output containsString:@"time="]) {
            NSArray *components = [output componentsSeparatedByString:@"time="];
            if (components.count > 1) {
                NSString *timeStr = [components[1] componentsSeparatedByString:@" "][0];
                NSArray *timeComponents = [timeStr componentsSeparatedByString:@":"];
                if (timeComponents.count == 3) {
                    float hours = [timeComponents[0] floatValue];
                    float minutes = [timeComponents[1] floatValue];
                    float seconds = [timeComponents[2] floatValue];
                    float totalSeconds = hours * 3600 + minutes * 60 + seconds;
                    
                    // Update progress bar (assuming 2-minute video as default)
                    float progress = totalSeconds / 120.0;
                    if (progress > 1.0) progress = 1.0;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.compressionTask) {  // Only update if task is still running
                            [self.progressBar setDoubleValue:progress * 100];
                            [self.statusLabel setStringValue:[NSString stringWithFormat:@"Compressing... %.1f%%", progress * 100]];
                        }
                    });
                }
            }
        }
    }];
    
    [self.compressionTask setTerminationHandler:^(NSTask *task) {
        [self cleanupTask];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (task.terminationStatus == 0) {
                // Compression successful, move file to final location
                NSString *finalOutputPath = [[inputPath stringByDeletingPathExtension] stringByAppendingString:@".compressed.mp4"];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *error = nil;
                
                // Remove existing file if it exists
                if ([fileManager fileExistsAtPath:finalOutputPath]) {
                    [fileManager removeItemAtPath:finalOutputPath error:&error];
                }
                
                // Move temp file to final location
                [fileManager moveItemAtPath:tempOutputPath toPath:finalOutputPath error:&error];
                
                if (!error) {
                    // Get output file size
                    NSDictionary *outputAttributes = [fileManager attributesOfItemAtPath:finalOutputPath error:nil];
                    NSNumber *outputSize = [outputAttributes objectForKey:NSFileSize];
                    
                    if (outputSize) {
                        float compressionRatio = [outputSize floatValue] / [inputSize floatValue] * 100;
                        [self.statusLabel setStringValue:[NSString stringWithFormat:@"Compression complete! (%.1f%% of original size)", compressionRatio]];
                        [self.sizeLabel setStringValue:[NSString stringWithFormat:@"Original: %@ → Compressed: %@", 
                            [self formatFileSize:inputSize], 
                            [self formatFileSize:outputSize]]];
                    }
                }
            }
            
            [self.progressBar setDoubleValue:100];
            [self.stopButton setHidden:YES];
            [self cleanupTempFiles];
        });
    }];
    
    @try {
        [self.compressionTask launch];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.stopButton setHidden:NO];
        });
    } @catch (NSException *exception) {
        NSLog(@"Error launching task: %@", exception);
        [self resetToInitialState];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self cleanupTask];
    [self cleanupTempFiles];
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        @try {
            NSLog(@"Starting application...");
            NSApplication *application = [NSApplication sharedApplication];
            [application setActivationPolicy:NSApplicationActivationPolicyRegular];
            AppDelegate *delegate = [[AppDelegate alloc] init];
            application.delegate = delegate;
            [application activateIgnoringOtherApps:YES];
            [application run];
        } @catch (NSException *exception) {
            NSLog(@"Fatal error in main: %@", exception);
            NSLog(@"Stack trace: %@", [exception callStackSymbols]);
        }
    }
    return 0;
} 