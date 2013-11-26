//
//  NSImage+TextOverlay.m
//  appicon
//
//  Created by Dmitry Nesterenko on 04.10.13.
//  Copyright (c) 2013 chebur. All rights reserved.
//

#import "NSImage+TextOverlay.h"

@implementation NSImage (TextOverlay)

- (void)drawText:(NSString *)text withAttributes:(NSDictionary *)attributes inRect:(NSRect)rect;
{
    [self lockFocus]; {
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.4] setFill];
        NSRectFillUsingOperation(rect, NSCompositeSourceAtop);
        
        [text drawInRect:rect withAttributes:attributes];
    } [self unlockFocus];
}

- (BOOL)writeUsingImageType:(NSBitmapImageFileType)imageType toFile:(NSString *)file
{
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:self.TIFFRepresentation];
    NSData *data = [imageRep representationUsingType:imageType properties:nil];
    return [data writeToFile:file atomically:YES];
}

@end
