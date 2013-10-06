//
//  NSFileManager+Traverising.h
//  appicon
//
//  Created by Dmitry Nesterenko on 06.10.13.
//  Copyright (c) 2013 chebur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Traverising)

- (NSArray *)filesWithPrefix:(NSString *)prefix atPath:(NSString *)path;

@end
