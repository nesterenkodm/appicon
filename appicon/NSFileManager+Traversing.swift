//
//  NSFileManager+Traversal.swift
//  appicon
//
//  Created by Dmitry Nesterenko on 17.06.14.
//  Copyright (c) 2014 chebur. All rights reserved.
//

import Foundation

extension NSFileManager {
    
    func filesWithPrefix(prefix: String, atPath path: String) -> String[] {
        var files: String[] = []
    
        let enumerator = NSFileManager.defaultManager().enumeratorAtPath(path)
        while let file = enumerator.nextObject() as? String {
            if file.hasPrefix(prefix) {
                files += path.stringByAppendingPathComponent(file)
            }
        }
    
        return files
    }
    
}