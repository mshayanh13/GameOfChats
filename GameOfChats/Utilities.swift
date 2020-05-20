//
//  Utilities.swift
//  GameOfChats
//
//  Created by Mohammad Shayan on 5/19/20.
//  Copyright © 2020 Mohammad Shayan. All rights reserved.
//

import UIKit
import Firebase

class Utilities {
    static let shared = Utilities()
    
    var currentUser: User?
    
    let imageCache = NSCache<NSString, UIImage>()
}

extension UIImageView {
    func loadImageUsingCacheWithUrlString(url: URL?) {
        
        self.image = nil
        
        guard let profileImageUrl = url else { return }
        
        if let cachedImage = Utilities.shared.imageCache.object(forKey: profileImageUrl.absoluteString as NSString) {
            self.image = cachedImage
        } else {
            URLSession.shared.dataTask(with: profileImageUrl) { (data, response, error) in
            
            if let error = error {
                debugPrint(error.localizedDescription)
            } else if let data = data {
                
                DispatchQueue.main.async {
                    
                    if let downloadedImage = UIImage(data: data) {
                        Utilities.shared.imageCache.setObject(downloadedImage, forKey:
                            
                            profileImageUrl.absoluteString as NSString)
                        self.image = downloadedImage
                    }
                    
                }
            }
            
            }.resume()
        }
        
        
        
        
    }
}
