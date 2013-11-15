//
//  NSFileManager+Traverising.m
//  appicon
//
//  Created by Dmitry Nesterenko on 06.10.13.
//  Copyright (c) 2013 chebur. All rights reserved.
//

#import "NSFileManager+Traversing.h"

@implementation NSFileManager (Traversing)

- (NSArray *)filesWithPrefix:(NSString *)prefix atPath:(NSString *)path
{
    NSMutableArray *files = [NSMutableArray new];
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
    NSString *file;
    while ((file = enumerator.nextObject)) {
        if ([[file substringWithRange:NSMakeRange(0, MIN(prefix.length, file.length))] isEqualToString:prefix])
            [files addObject:[path stringByAppendingPathComponent:file]];
    }
    
    return files;
}

@end
