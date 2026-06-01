//
//  W3WAnnotation.swift
//  w3w-swift-components-map
//
//  Created by Henry Ng on 13/1/25.
//

#if !os(macOS) && !os(watchOS)

import Foundation
import MapKit
import W3WSwiftCore
import W3WSwiftThemes
import W3WSwiftComponentsMap

public class W3WAppleMapAnnotation: MKPointAnnotation {
  
  var square: W3WSquare?
  
  var type: W3WMarkerType? = .circle
  
  var color: W3WColor?
  
  var isMarker: Bool?
  
  var isMark: Bool?
  
  var isSaved: Bool?
  
  
  public init(square: W3WSquare, color: W3WColor? = nil, type: W3WMarkerType? = .circle, isMarker: Bool? = false, isMark: Bool? = false, isSaved: Bool? = false) {
    
    super.init()
    
    self.color       = color
    self.type        = type
    self.isMarker    = isMarker
    self.isMark      = isMark
    self.square      = square
    self.isSaved     = isSaved
    
    if let words = square.words {
      if W3WSettings.leftToRight {
        title = "///" + words
      } else {
        title = words + "///"
      }
    }
    
    if let coordinates = square.coordinates {
      self.coordinate = coordinates
    }
    
  }
}


#endif
