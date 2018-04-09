// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>


@interface WOTDPlugInMock : QCPlugIn

+(NSArray<NSDictionary *> *)dictionaryList;
-(void)_dumpAllEntries:(NSDictionary *)dictionaryInfo;

@end

@implementation WOTDPlugInMock

+(NSArray<NSDictionary *> *)dictionaryList { return nil; }
-(void)_dumpAllEntries:(NSDictionary *)dictionaryInfo { }

@end


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Load dat bundle.
        // +[QCPlugin loadPlugInAtPath:] honors the restricted host settings in the Info.plist, so I'm just going this route.

        NSArray *libraryURLs = [NSFileManager.defaultManager URLsForDirectory:NSLibraryDirectory inDomains:NSAllDomainsMask];
        NSURL *pluginURL = nil;
        for(NSURL *libraryURL in libraryURLs) {
            NSURL *potentialPluginURL = libraryURL;
            potentialPluginURL = [potentialPluginURL URLByAppendingPathComponent:@"Graphics" isDirectory:YES];
            potentialPluginURL = [potentialPluginURL URLByAppendingPathComponent:@"Quartz Composer Plug-Ins" isDirectory:YES];
            potentialPluginURL = [potentialPluginURL URLByAppendingPathComponent:@"WOTD.plugin" isDirectory:YES];

            NSNumber *isDir = nil;
            BOOL worstAPIEverDidSucceed = [potentialPluginURL getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:nil];

            if(worstAPIEverDidSucceed && isDir.boolValue) {
                pluginURL = potentialPluginURL;
                break;
            }
        }

        NSCAssert(pluginURL != nil, @"Couldn't find WOTD.plugin!");

        NSLog(@"Using plugin at %@", pluginURL.path);


        NSBundle *pluginBundle = [NSBundle bundleWithURL:pluginURL];
        NSCAssert(pluginBundle != nil, @"Couldn't create bundle for WotD plugin");

        NSError *error = nil;
        BOOL loadSuccess = [pluginBundle loadAndReturnError:&error];
        NSCAssert(loadSuccess, @"Error loading bundle: %@", error);


        // Fetch the plugin class and make sure it's what we're expecting
        Class pluginClass = NSClassFromString(@"WOTDPlugIn");
        NSCAssert(pluginClass != nil, @"Couldn't find plugin class");
        NSCAssert([pluginClass isSubclassOfClass:[QCPlugIn class]], @"Plugin class is not a subclass of QCPlugin");


        // Call +[WOTDPlugin dictionaryList], which returns specially-formatted NSDictionaries of supported dictionaries.
        // Pull out the entry we want.
        NSArray *dictionaries = [pluginClass dictionaryList];
        NSString *noadName = @"New Oxford American Dictionary";
        NSString *winningInfoDictFilename = @"noad-super-list.plist";
        NSDictionary *noadDictInfo = nil;
        for(NSDictionary *dictInfo in dictionaries) {
            if([dictInfo[@"dictName"] isEqualToString:noadName]) {
                NSURL *url = dictInfo[@"wotdInfoURL"];
                if([url.lastPathComponent isEqualToString:winningInfoDictFilename]) {
                    noadDictInfo = dictInfo;
                    break;
                }
            }
        }
        NSCAssert(noadDictInfo != nil, @"Couldn't get dictionary info");


        // Make an instance of the plugin, because _dumpAllEntries: is an instance method for some reason...
        QCPlugIn *realPlugin = [[pluginClass alloc] init];
        NSCAssert(realPlugin != nil, @"Couldn't make instance of plugin");


        // Delete the old log file. The _dumpAllEntries: method just appends.
        NSString *logPath = @"~/Library/Logs/WotD/com.apple.dictionary.NOAD.txt".stringByExpandingTildeInPath;
        NSURL *logURL = [NSURL fileURLWithPath:logPath];
        if([NSFileManager.defaultManager isDeletableFileAtPath:logPath]) {
            NSLog(@"Deleting old log file @ %@", logURL.path);

            NSError *deleteError = nil;
            if(![NSFileManager.defaultManager removeItemAtURL:logURL error:&deleteError]) {
                NSLog(@"Proceeding, but couldn't delete old log: %@", error);
            }
        }


        // And dump.
        // ~/Library/Logs/WotD/com.apple.dictionary.NOAD.txt now contains all the in the word list,
        // formatted as they will be in the screensaver.
        WOTDPlugInMock *plugin = (WOTDPlugInMock *)realPlugin;
        [plugin _dumpAllEntries:noadDictInfo];


        [[NSWorkspace sharedWorkspace] openURL:logURL];
    }
    return 0;
}
