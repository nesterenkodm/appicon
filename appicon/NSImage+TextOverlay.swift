//
//  NSImage+TextOverlay.swift
//  appicon
//
//  Created by Dmitry Nesterenko on 17.06.14.
//  Copyright (c) 2014 chebur. All rights reserved.
//

import AppKit

extension NSImage {
    
    func imageByOverlayingText(text: String, withAttributes attributes: Dictionary<String, String>, inRect rect: NSRect) -> NSImage {
        // configure bitmap context
        let imageRep = self.bestRepresentationForRect(NSRect(x: 0, y: 0, width: self.size.width, height: self.size.height), context: nil, hints: nil)
        var proposedRect = NSRect(x: 0, y: 0, width: imageRep.pixelsWide, height: imageRep.pixelsHigh)
        let image = self.CGImageForProposedRect(&proposedRect, context: nil, hints: nil).takeUnretainedValue()
        let colorSpace = CGImageGetColorSpace(image)
        let data: CMutableVoidPointer = nil
        var bitmapContext: CGContext = CGBitmapContextCreate(data, UInt(proposedRect.width), UInt(proposedRect.height), CGImageGetBitsPerComponent(image), 0, colorSpace, CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.toRaw()))

        // drawing
        let bitmapContextAddress: Int = reinterpretCast(bitmapContext)
        let bitmapContextPointer: CMutableVoidPointer = COpaquePointer(UnsafePointer<CGContext>(bitmapContextAddress))
        let context = NSGraphicsContext(graphicsPort: bitmapContextPointer, flipped: false)
        NSGraphicsContext.setCurrentContext(context)
        CGContextDrawImage(bitmapContext, proposedRect, image)
        CGContextSetFillColorWithColor(bitmapContext, NSColor(calibratedWhite: 0, alpha: 0.4).CGColor)
        let proposedTextRect = NSRect(x: 0, y: rect.origin.y / self.size.height * proposedRect.height, width: rect.width / self.size.width * proposedRect.width, height: rect.height / self.size.height * proposedRect.height)
        CGContextFillRect(bitmapContext, proposedTextRect)
        text.bridgeToObjectiveC().drawInRect(proposedTextRect, withAttributes: attributes)
        NSGraphicsContext.setCurrentContext(nil)
        
        // returning image
        let scaledImageRef = CGBitmapContextCreateImage(bitmapContext)
        let scaledImage = NSImage(CGImage: scaledImageRef, size: NSSize(width: imageRep.pixelsWide, height: imageRep.pixelsHigh))
        
        return scaledImage
    }
    
    func writeUsingImageType(imageType: NSBitmapImageFileType, toFile file: String) -> Bool {
        let imageRep = NSBitmapImageRep(data: self.TIFFRepresentation)
        var data = imageRep.representationUsingType(imageType, properties: nil)
        
        return data.writeToFile(file, atomically: true)
    }
    
}