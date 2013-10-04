//
//  NSImage+TextOverlay.h
//  appicon
//
//  Created by Dmitry Nesterenko on 04.10.13.
//  Copyright (c) 2013 chebur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (TextOverlay)

- (void)drawText:(NSString *)text withAttributes:(NSDictionary *)attributes inRect:(NSRect)rect;
- (BOOL)writeUsingImageType:(NSBitmapImageFileType)imageType toFile:(NSString *)file;

@end
