//
//  NSImage+TextOverlay.m
//  appicon
//
//  Created by Dmitry Nesterenko on 04.10.13.
//  Copyright (c) 2013 chebur. All rights reserved.
//

#import "NSImage+TextOverlay.h"

@implementation NSImage (TextOverlay)

- (NSImage *)imageByOverlayingText:(NSString *)text withAttributes:(NSDictionary *)attributes inRect:(NSRect)rect
{
    // configure bitmap context
    NSImageRep *imageRep = [self bestRepresentationForRect:NSMakeRect(0, 0, self.size.width, self.size.height) context:nil hints:nil];
    NSRect proposedRect = NSMakeRect(0, 0, imageRep.pixelsWide, imageRep.pixelsHigh);
    CGImageRef imageRef = [self CGImageForProposedRect:&proposedRect context:nil hints:nil];
    CGColorSpaceRef colorSpaceRef = CGImageGetColorSpace(imageRef);
    CGContextRef contextRef = CGBitmapContextCreate(NULL,
                                                    proposedRect.size.width,
                                                    proposedRect.size.height,
                                                    CGImageGetBitsPerComponent(imageRef),
                                                    0,
                                                    colorSpaceRef,
                                                    (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);

    // drawing
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithGraphicsPort:contextRef flipped:NO];
    [NSGraphicsContext setCurrentContext:context]; {
        CGContextDrawImage(contextRef, proposedRect, imageRef);
        CGContextSetFillColorWithColor(contextRef, [NSColor colorWithCalibratedWhite:0.0 alpha:0.4].CGColor);
        NSRect proposedTextRect = NSMakeRect(0, rect.origin.y / self.size.height * proposedRect.size.height, rect.size.width / self.size.width * proposedRect.size.width, rect.size.height / self.size.height * proposedRect.size.height);
        CGContextFillRect(contextRef, proposedTextRect);
        [text drawInRect:proposedTextRect withAttributes:attributes];
    }
    [NSGraphicsContext setCurrentContext:nil];
    
    // returning image
    CGImageRef scaledImageRef = CGBitmapContextCreateImage(contextRef);
    NSImage *scaledImage = [[NSImage alloc] initWithCGImage:scaledImageRef size:NSMakeSize(imageRep.pixelsWide, imageRep.pixelsHigh)];
    
    // cleaning up
    CGImageRelease(scaledImageRef);
    CGContextRelease(contextRef);
    
    return scaledImage;
}

- (BOOL)writeUsingImageType:(NSBitmapImageFileType)imageType toFile:(NSString *)file
{
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:self.TIFFRepresentation];
    NSData *data = [imageRep representationUsingType:imageType properties:nil];
    return [data writeToFile:file atomically:YES];
}

@end
