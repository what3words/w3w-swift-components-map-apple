//
//  W3WColor+.swift
//  w3w-swift-components-map-apple
//
//  Created by Henry Ng on 25/4/25.
//
import W3WSwiftThemes
import W3WSwiftCore

extension W3WColor: Equatable {
  
  public static func  == (lhs: W3WColor, rhs: W3WColor) -> Bool {
    
    guard lhs.colors.count == rhs.colors.count else { return false }
    
    for(mode, color) in lhs.colors {
      guard let rhsColor = rhs.colors[mode], rhsColor == color else { return false }
    }
    return true
  }
}
