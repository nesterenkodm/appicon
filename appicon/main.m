//
//  main.m
//  appicon
//
//  Created by Dmitry Nesterenko on 03.10.13.
//  Copyright (c) 2013 chebur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSImage+TextOverlay.h"
#import "NSFileManager+Traversing.h"

NSString * const AIEnvTargetBuildDirKey = @"TARGET_BUILD_DIR";
NSString * const AIEnvAssetCatalogCompilerAppiiconNameKey = @"ASSETCATALOG_COMPILER_APPICON_NAME";
NSString * const AIEnvContentsFolderPathKey = @"CONTENTS_FOLDER_PATH";
NSString * const AIEnvInfoPlistPathKey = @"INFOPLIST_PATH";
NSString * const AILocaleDefaultIdentifier = @"ru_RU";

NSDictionary *AIEnvDictionaryWithFileHandle(NSFileHandle *fileHandle)
{
    NSData *inputData = [NSData dataWithData:[fileHandle readDataToEndOfFile]];
    NSString *inputString = [[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding];
    
    __block NSDictionary *data = [NSMutableDictionary new];

    [[inputString componentsSeparatedByString:@"\n"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSMutableArray *components = [[obj componentsSeparatedByString:@"="] mutableCopy];
        NSString *key = components[0];
        [components removeObjectAtIndex:0];
        [data setValue:[components componentsJoinedByString:@"="] forKey:key];
    }];
    
    return data;
}

NSString *AIValueForInfoPlistKeyAtPath(NSString *key, NSString *plist)
{
    NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:plist];
    return data[key];
}

typedef NS_OPTIONS(NSInteger, AIBurnTextOverImageOption) {
    AIBurnTextOverImageOptionUseBackupCopy = 1 // backup original image if not have been backuped already. And use backuped copy for image processing
};

BOOL AIBurnTextOverImageAtPath(NSString *text, NSString *imagePath, AIBurnTextOverImageOption options)
{
    NSImage *image;
    if (options & AIBurnTextOverImageOptionUseBackupCopy) {
        NSString *lastPathComponent = [NSString stringWithFormat:@".%@", imagePath.lastPathComponent];
        NSString *backupPath = [imagePath.stringByDeletingLastPathComponent stringByAppendingPathComponent:lastPathComponent];
        if (![[NSFileManager defaultManager] isReadableFileAtPath:backupPath]) {
            NSError *error;
            __unused BOOL result = [[NSFileManager defaultManager] copyItemAtPath:imagePath toPath:backupPath error:&error];
            NSCAssert(result, @"%@", error);
        }
        image = [[NSImage alloc] initWithContentsOfFile:backupPath];
        
    } else
        image = [[NSImage alloc] initWithContentsOfFile:imagePath];

    // hint NSImage that "@2x~ipad.png" image should be treated as HD image
    NSImageRep *imageRep = [image bestRepresentationForRect:NSMakeRect(0, 0, image.size.width, image.size.height) context:nil hints:nil];
    if ([imagePath rangeOfString:@"@2x~ipad.png" options:NSBackwardsSearch].location == imagePath.length - 12) {
        imageRep.size =
        image.size = NSMakeSize(image.size.width / 2.0, image.size.height / 2.0);
    }
    
    NSShadow *shadow = [NSShadow new];
    shadow.shadowOffset = CGSizeMake(0.5, -0.5);
    shadow.shadowColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.3];
    NSMutableParagraphStyle *paragrapStyle = [NSMutableParagraphStyle new];
    paragrapStyle.alignment = NSCenterTextAlignment;
    NSDictionary *attributes = @{NSForegroundColorAttributeName: [NSColor whiteColor],
                                 NSParagraphStyleAttributeName: paragrapStyle,
                                 NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:7 * imageRep.pixelsWide / imageRep.size.width],
                                 NSShadowAttributeName: shadow};
    image = [image imageByOverlayingText:text withAttributes:attributes inRect:NSMakeRect(0, 0, image.size.width, 22)];

    return [image writeUsingImageType:NSPNGFileType toFile:imagePath];
}

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        NSDictionary *env = AIEnvDictionaryWithFileHandle([NSFileHandle fileHandleWithStandardInput]);
//        NSDictionary *env = AIEnvDictionaryWithFileHandle([NSFileHandle fileHandleForReadingAtPath:@"/Users/chebur/Desktop/env.txt"]);

        NSArray *appIcons = [[NSFileManager defaultManager] filesWithPrefix:env[AIEnvAssetCatalogCompilerAppiiconNameKey] atPath:[env[AIEnvTargetBuildDirKey] stringByAppendingPathComponent:env[AIEnvContentsFolderPathKey]]];
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        calendar.locale = [NSLocale localeWithLocaleIdentifier:AILocaleDefaultIdentifier];
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.calendar = calendar;
        dateFormatter.locale = calendar.locale;
        dateFormatter.dateStyle = kCFDateFormatterShortStyle;
        NSString *text = [NSString stringWithFormat:@"%@\n%@",
                          AIValueForInfoPlistKeyAtPath((NSString *)kCFBundleVersionKey, [env[AIEnvTargetBuildDirKey] stringByAppendingPathComponent:env[AIEnvInfoPlistPathKey]]),
                          [[dateFormatter stringFromDate:[NSDate date]] stringByReplacingOccurrencesOfString:@" " withString:@" "]];

        [appIcons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSLog(@"Processing image at path %@", obj);
            BOOL result = AIBurnTextOverImageAtPath(text, obj, AIBurnTextOnImageOptionUseBackupCopy);
            NSCAssert(result, @"Can't burn text over image at path %@", obj);
            
            *stop = result == NO;
        }];
    }

    return 0;
}

