//
//  main.m
//  appicon
//
//  Created by Dmitry Nesterenko on 03.10.13.
//  Copyright (c) 2013 chebur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSImage+TextOverlay.h"
#import "NSFileManager+Traverising.h"

NSDictionary *AIEnvDictionaryFromStdin()
{
    NSFileHandle *input = [NSFileHandle fileHandleWithStandardInput];
    NSData *inputData = [NSData dataWithData:[input readDataToEndOfFile]];
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

NSString *AIBundleVersionFromInfoPlistFileAtPath(NSString *plist)
{
    NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:plist];
    return data[(NSString *)kCFBundleVersionKey];
}

BOOL AIBurnTextOnImageAtPath(NSString *text, NSString *imagePath)
{
    NSShadow *shadow = [NSShadow new];
    shadow.shadowOffset = CGSizeMake(0.5, -0.5);
    shadow.shadowColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.3];
    NSDictionary *attributes = @{NSForegroundColorAttributeName: [NSColor whiteColor],
                                 NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:6],
                                 NSShadowAttributeName: shadow};
    NSSize textSize = [text sizeWithAttributes:attributes];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
    [image drawText:text withAttributes:attributes inRect:NSMakeRect(image.size.width / 2.0 - textSize.width / 2.0, - image.size.height + textSize.height + 3, image.size.width, image.size.height)];
    
    return [image writeUsingImageType:NSPNGFileType toFile:imagePath];
}

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        NSDictionary *env = AIEnvDictionaryFromStdin();
        NSLog(@"Using target build dir: %@", env[@"TARGET_BUILD_DIR"]);
        
        NSArray *appIcons = [[NSFileManager defaultManager] filesWithPrefix:env[@"ASSETCATALOG_COMPILER_APPICON_NAME"] atPath:[env[@"TARGET_BUILD_DIR"] stringByAppendingPathComponent:env[@"CONTENTS_FOLDER_PATH"]]];
        
        NSString *version = AIBundleVersionFromInfoPlistFileAtPath([env[@"TARGET_BUILD_DIR"] stringByAppendingPathComponent:env[@"INFOPLIST_PATH"]]);

        [appIcons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSLog(@"Burning \"%@\" to the image named %@", version, [obj lastPathComponent]);
            BOOL result = AIBurnTextOnImageAtPath(version, obj);
            *stop = result == NO;
        }];
    }

    return 0;
}

