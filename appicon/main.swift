//
//  main.swift
//  appicon
//
//  Created by Dmitry Nesterenko on 17.06.14.
//  Copyright (c) 2014 chebur. All rights reserved.
//

import AppKit

enum AIEnvDictionaryKey : String {
    case TargetBuildDir = "TARGET_BUILD_DIR"
    case AssetCatalogCompilerAppiconName = "ASSETCATALOG_COMPILER_APPICON_NAME"
    case ContentsFolderPath = "CONTENTS_FOLDER_PATH"
    case InfoPlistPathKey = "INFOPLIST_PATH"
}

func AIEnvDictionaryWithFileHandle(fileHandle: NSFileHandle) -> [String: String] {
    let inputData = NSData(data: fileHandle.readDataToEndOfFile())
    let inputString = NSString(data: inputData, encoding: NSUTF8StringEncoding) as! String
    
    var data = Dictionary<String, String>()

    for obj in inputString.componentsSeparatedByString("\n") {
        var components = obj.componentsSeparatedByString("=")
        let key = components.removeAtIndex(0) as String
        data[key] = "=".join(components)
    }
    
    return data
}

func AIValueForInfoPlistKeyAtPath(key: String, plist: String) -> String? {
    if let data = NSDictionary(contentsOfFile: plist) {
        return data[key] as? String
    }
    return nil
}

enum AIBurnTextOverImageOption : UInt8 {
    // backup original image if not have been backuped already. And use backuped copy for image processing
    case UseBackupCopy = 1
}

func AILoadOriginalImage(imagePath: String, options: UInt8) -> NSImage? {
    if options & AIBurnTextOverImageOption.UseBackupCopy.rawValue > 0 {
        let backupPath = imagePath.stringByDeletingLastPathComponent.stringByAppendingPathComponent("." + imagePath.lastPathComponent)
        if !NSFileManager.defaultManager().isReadableFileAtPath(backupPath) {
            do {
                try NSFileManager.defaultManager().copyItemAtPath(imagePath, toPath: backupPath)
            } catch {
                NSLog("Copy operation failed with error \(error)")
            }
        }
        return NSImage(contentsOfFile: backupPath)
        
    } else {
        return NSImage(contentsOfFile: imagePath)
    }
}

func AIBurnTextOverImageAtPath(text: String, imagePath: String, options: UInt8) -> Bool? {
    if let image = AILoadOriginalImage(imagePath, options: options) {
        // hint NSImage that "@2x~ipad.png" image should be treated as HD image
        if let imageRep = image.bestRepresentationForRect(NSRect(origin: CGPointZero, size: image.size), context: nil, hints: nil) {
            if imagePath.hasSuffix("@2x~ipad.png") {
                imageRep.size = NSSize(width: image.size.width / 2.0, height: image.size.height / 2.0)
                image.size = imageRep.size
            }

            let shadow = NSShadow()
            shadow.shadowOffset = CGSize(width: 0.5, height: -0.5)
            shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.3)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .Center
            var attributes = [
                NSForegroundColorAttributeName: NSColor.whiteColor(),
                NSParagraphStyleAttributeName: paragraphStyle,
                NSShadowAttributeName: shadow
            ]
            if let font = NSFont(name: "Menlo", size: CGFloat(7 * imageRep.pixelsWide) / imageRep.size.width) {
                attributes[NSFontAttributeName] = font
            }

            let modifiedImage = image.imageByOverlayingText(text, withAttributes: attributes, inRect: NSRect(x: 0, y: 0, width: image.size.width, height: 22))
            
            return modifiedImage?.writeUsingImageType(NSBitmapImageFileType.NSPNGFileType, toFile: imagePath)
        }
    }
    
    return nil
}

autoreleasepool {
    let env = AIEnvDictionaryWithFileHandle(NSFileHandle.fileHandleWithStandardInput())
//    let env = AIEnvDictionaryWithFileHandle(NSFileHandle(forReadingAtPath: "/Users/chebur/Desktop/env.txt")!)

    let textFirstLine = AIValueForInfoPlistKeyAtPath("CFBundleShortVersionString", plist: env[AIEnvDictionaryKey.TargetBuildDir.rawValue]!.stringByAppendingPathComponent(env[AIEnvDictionaryKey.InfoPlistPathKey.rawValue]!)) ?? "-"
    let textSecondLine = AIValueForInfoPlistKeyAtPath(String(kCFBundleVersionKey), plist: env[AIEnvDictionaryKey.TargetBuildDir.rawValue]!.stringByAppendingPathComponent(env[AIEnvDictionaryKey.InfoPlistPathKey.rawValue]!)) ?? "-"
    let text = "\(textFirstLine)\n\(textSecondLine)"

    let path = env[AIEnvDictionaryKey.TargetBuildDir.rawValue]!.stringByAppendingPathComponent(env[AIEnvDictionaryKey.ContentsFolderPath.rawValue]!)
    if let appIcons = NSFileManager.defaultManager().filesWithPrefix(env[AIEnvDictionaryKey.AssetCatalogCompilerAppiconName.rawValue]!, atPath: path) {
        for path in appIcons {
            NSLog("Processing image at path \(path)")
            let result = AIBurnTextOverImageAtPath(text, imagePath: path, options: AIBurnTextOverImageOption.UseBackupCopy.rawValue)
            if result == nil {
                NSLog("Can't burn text over image")
            }
        }
    } else {
        NSLog("No app icons found at path \(path)")
    }
}
