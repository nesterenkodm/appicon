//
//  NSImage+TextOverlay.swift
//  appicon
//
//  Created by Dmitry Nesterenko on 17.06.14.
//  Copyright (c) 2014 chebur. All rights reserved.
//

import AppKit

extension NSImage {
    
    func imageByOverlayingText(text: String, withAttributes attributes: [NSObject : AnyObject], inRect rect: NSRect) -> NSImage? {
        // configure bitmap context
        if let imageRep = self.bestRepresentationForRect(NSRect(x: 0, y: 0, width: self.size.width, height: self.size.height), context: nil, hints: nil) {
            var proposedRect = NSRect(x: 0, y: 0, width: imageRep.pixelsWide, height: imageRep.pixelsHigh)
            let image = self.CGImageForProposedRect(&proposedRect, context: nil, hints: nil)?.takeUnretainedValue()
            let colorSpace = CGImageGetColorSpace(image)
            let bitmapContext = CGBitmapContextCreate(UnsafeMutablePointer.null(), UInt(proposedRect.width), UInt(proposedRect.height), CGImageGetBitsPerComponent(image), 0, colorSpace, CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.rawValue))

            // drawing
//            let bitmapContextAddress = unsafeBitCast(bitmapContext, Int.self)
//            let bitmapContextPointer = UnsafePointer<CGContext>(bitmapContextAddress)
            let context = NSGraphicsContext(CGContext: bitmapContext, flipped: false)// t(graphicsPort: bitmapContext, flipped: false)
            NSGraphicsContext.setCurrentContext(context)
            CGContextDrawImage(bitmapContext, proposedRect, image)
            CGContextSetFillColorWithColor(bitmapContext, NSColor(calibratedWhite: 0, alpha: 0.4).CGColor)
            let proposedTextRect = NSRect(x: 0, y: rect.origin.y / self.size.height * proposedRect.height, width: rect.width / self.size.width * proposedRect.width, height: rect.height / self.size.height * proposedRect.height)
            CGContextFillRect(bitmapContext, proposedTextRect)
            (text as NSString).drawInRect(proposedTextRect, withAttributes: attributes)
            NSGraphicsContext.setCurrentContext(nil)
            
            // returning image
            let scaledImageRef = CGBitmapContextCreateImage(bitmapContext)
            let scaledImage = NSImage(CGImage: scaledImageRef, size: NSSize(width: imageRep.pixelsWide, height: imageRep.pixelsHigh))
            
            return scaledImage
        }
        
        return nil
    }
    
    func writeUsingImageType(imageType: NSBitmapImageFileType, toFile file: String) -> Bool? {
        if let data = self.TIFFRepresentation {
            let imageRep = NSBitmapImageRep(data: data)
            if let data = imageRep?.representationUsingType(imageType, properties: NSDictionary()) {
                return data.writeToFile(file, atomically: true)
            }
        }
        
        return nil
    }
    
}