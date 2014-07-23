//
//  NSFileManager+Traversing.swift
//  appicon
//
//  Created by Dmitry Nesterenko on 17.06.14.
//  Copyright (c) 2014 chebur. All rights reserved.
//

import Foundation

extension NSFileManager {
    
    func filesWithPrefix(prefix: String, atPath path: String) -> [String]? {
        if let enumerator = NSFileManager.defaultManager().enumeratorAtPath(path) {
            var files: [String] = []
            while let file = enumerator.nextObject() as? String {
                if file.hasPrefix(prefix) {
                    files.append(path.stringByAppendingPathComponent(file))
                }
            }
            return files
        }
        
        return nil
    }
    
}