//
//  W3WImageCache.swift
//  w3w-swift-components-map-apple
//
//  Created by Henry Ng on 3/3/25.
//

import UIKit
import W3WSwiftThemes


class W3WImageCache {
    static let shared = W3WImageCache()
    private var cache = NSCache<NSString, UIImage>()

  func getImage(for color: W3WColor, size: CGSize) -> UIImage? {
      let key = "\(color.description)_\(size.width)_\(size.height)" as NSString
      
      if let cachedImage = cache.object(forKey: key) {
          return cachedImage
      }
      
      // Get the image
    let newImage = W3WImage(drawing: .mapSquare, colors: .standardMaps.with(background: color))
          .get(size: W3WIconSize(value: size))
      
      // Cache it if it's not nil
      cache.setObject(newImage, forKey: key)
      
      return newImage
  }
}


