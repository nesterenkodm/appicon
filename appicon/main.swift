//
//  main.swift
//  appicon
//
//  Created by Dmitry Nesterenko on 17.06.14.
//  Copyright (c) 2014 chebur. All rights reserved.
//

import AppKit

let AILocaledDefaultIdentifier = "ru_RU"

enum AIEnvDictionaryKey : String {
    case TargetBuildDir = "TARGET_BUILD_DIR"
    case AssetCatalogCompilerAppiconName = "ASSETCATALOG_COMPILER_APPICON_NAME"
    case ContentsFolderPath = "CONTENTS_FOLDER_PATH"
    case InfoPlistPathKey = "INFOPLIST_PATH"
}

func AIEnvDictionaryWithFileHandle(fileHandle: NSFileHandle) -> Dictionary<String, String> {
    let inputData = NSData.dataWithData(fileHandle.readDataToEndOfFile())
    var inputString = NSString(data: inputData, encoding: NSUTF8StringEncoding) as String
    
    var data = Dictionary<String, String>()

    for obj in inputString.componentsSeparatedByString("\n") {
        var components = obj.componentsSeparatedByString("=")
        let key = components.removeAtIndex(0) as String
        data[key] = join("=", components)
    }
    
    return data
}

func AIValueForInfoPlistKeyAtPath(key: String, plist: String) -> String? {
    let data = NSDictionary(contentsOfFile: plist) as Dictionary
    let value: AnyObject? = data[key]
    return value as? String
}

enum AIBurnTextOverImageOption : UInt8 {
    // backup original image if not have been backuped already. And use backuped copy for image processing
    case UseBackupCopy = 1
}

func AIBurnTextOverImageAtPath(text: String, imagePath: String, options: UInt8) -> Bool {
    var image: NSImage
    
    if options & AIBurnTextOverImageOption.UseBackupCopy.toRaw() > 0 {
        let backupPath = imagePath.stringByDeletingLastPathComponent.stringByAppendingPathComponent("." + imagePath.lastPathComponent)
        if !NSFileManager.defaultManager().isReadableFileAtPath(backupPath) {
            var copyError: NSError?
            let result = NSFileManager.defaultManager().copyItemAtPath(imagePath, toPath: backupPath, error: &copyError)
            if (!result) {
                if let error = copyError {
                    NSLog("Copy operation failed with error \(error.localizedDescription)")
                }
            }
        }
        image = NSImage(contentsOfFile: backupPath)
        
    } else {
        image = NSImage(contentsOfFile: imagePath)
    }
    
    // hint NSImage that "@2x~ipad.png" image should be treated as HD image
    let imageRep = image.bestRepresentationForRect(NSRect(origin: CGPointZero, size: image.size), context: nil, hints: nil)
    if (imagePath.hasSuffix("@2x~ipad.png")) {
        imageRep.size = NSSize(width: image.size.width / 2.0, height: image.size.height / 2.0)
        image.size = imageRep.size
    }
    
    let shadow = NSShadow()
    shadow.shadowOffset = CGSize(width: 0.5, height: -0.5)
    shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.3)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = NSTextAlignment.CenterTextAlignment
    let attributes = [
        NSForegroundColorAttributeName: NSColor.whiteColor(),
        NSParagraphStyleAttributeName: paragraphStyle,
        NSFontAttributeName: NSFont(name: "Menlo", size: CGFloat(7 * imageRep.pixelsWide) / imageRep.size.width),
        NSShadowAttributeName: shadow
    ]
    image = image.imageByOverlayingText(text, withAttributes: attributes as Dictionary<String, String>, inRect: NSRect(x: 0, y: 0, width: image.size.width, height: 22))
    
    return image.writeUsingImageType(NSBitmapImageFileType.NSPNGFileType, toFile: imagePath)
}

autoreleasepool {
    let env = AIEnvDictionaryWithFileHandle(NSFileHandle.fileHandleWithStandardInput())
//    let env = AIEnvDictionaryWithFileHandle(NSFileHandle(forReadingAtPath: "/Users/chebur/Desktop/env.txt"))

    let textFirstLine = AIValueForInfoPlistKeyAtPath("CFBundleShortVersionString", env[AIEnvDictionaryKey.TargetBuildDir.toRaw()]!.stringByAppendingPathComponent(env[AIEnvDictionaryKey.InfoPlistPathKey.toRaw()]!))
    let textSecondLine = AIValueForInfoPlistKeyAtPath(kCFBundleVersionKey, env[AIEnvDictionaryKey.TargetBuildDir.toRaw()]!.stringByAppendingPathComponent(env[AIEnvDictionaryKey.InfoPlistPathKey.toRaw()]!))
    let text = "\(textFirstLine)\n\(textSecondLine)"

    let path = env[AIEnvDictionaryKey.TargetBuildDir.toRaw()]!.stringByAppendingPathComponent(env[AIEnvDictionaryKey.ContentsFolderPath.toRaw()]!)
    let appIcons = NSFileManager.defaultManager().filesWithPrefix(env[AIEnvDictionaryKey.AssetCatalogCompilerAppiconName.toRaw()]!, atPath: path)
    if appIcons.count == 0 {
        NSLog("No app icons found at path \(path)")
        return
    }

    for path in appIcons {
        NSLog("Processing image at path \(path)")
        let result = AIBurnTextOverImageAtPath(text, path, AIBurnTextOverImageOption.UseBackupCopy.toRaw())
        assert(result, "Can't burn text over image")
    }
}
