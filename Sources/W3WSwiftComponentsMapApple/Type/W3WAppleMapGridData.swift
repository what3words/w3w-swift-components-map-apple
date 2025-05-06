//
//  W3WAppleMapGridData.swift
//  w3w-swift-components-map-apple
//
//  Created by Henry Ng on 18/1/25.
//

#if !os(macOS) && !os(watchOS)

import Foundation
import MapKit
import W3WSwiftCore
import W3WSwiftThemes
import Combine
import W3WSwiftComponentsMap


public class W3WAppleMapGridData {
  
  private var cancellables = Set<AnyCancellable>()

   let squareColor    = W3WLive<W3WColor>(.w3wBrandBase)
  
   let mapGridColor   = W3WLive<W3WColor>(.mediumGrey)
   let mapGridLineThickness = W3WLive<W3WLineThickness>(0.7)
  
   let mapSquareColor = W3WLive<W3WColor>(.black)
   let mapSquareLineThickness = W3WLive<W3WLineThickness>(0.1)
  
//   let selectedSquareBorderColor = W3WLive<W3WColor>(.black)
//   let selectedSquareThickness = W3WLive<W3WLineThickness>(0.5)
  
   let pinWidth = CGFloat(30.0)
   let pinHeight  = CGFloat(30.0)
   let pinFrameSize   = CGFloat(30.0)
   let pinSquareSize   = CGFloat(50.0)
   let squarePinFrameSize   = CGFloat(50.0)
  
  public var onError: W3WMapErrorHandler = { _ in }

  var gridRendererPointer: W3WMapGridRenderer? = nil
  var squareRendererPointer: W3WMapSquaresRenderer? = nil
  var gridLinePointer: W3WMapGridLines? = nil

  var w3w: W3WProtocolV4?
  
  /// language to use currently
  var language: W3WLanguage = W3WSettings.defaultLanguage
  
  /// highighted individual squares on the map
  var squares = [W3WSquare]()
  
  var markers = [W3WSquare]()
  
  var savedList = W3WMarkersLists()
  
  var selectedSquare: W3WSquare? = nil
  
  var squareIsMarker: W3WSquare? = nil
  
  var currentSquare: W3WSquare? = nil
  
  var isUpdatingSquares = false
  
  var overlayColors: [Int64: W3WColor] = [:]
  
  var previousStateHash: Int? = 0

  
  var scheme: W3WScheme? = .w3w
  
  var mapZoomLevel = CGFloat(0.0)
  
  var pointsPerSquare = CGFloat(12.0)
  
  /// keep track of the zoom level so we can change pins to squares at a certain point
  var lastZoomPointsPerSquare = CGFloat(0.0)
  
  var visibleZoomPointsPerSquare = CGFloat(32.0)
  
  var gridRenderer: W3WMapGridRenderer? {
    get { return gridRendererPointer }
    set { gridRendererPointer = newValue }
  }
  
  var squareRenderer: W3WMapSquaresRenderer? {
    get { return squareRendererPointer }
    set { squareRendererPointer = newValue }
  }
  
  
  var gridLines: W3WMapGridLines? {
    get { return gridLinePointer }
    set { gridLinePointer = newValue }
  }
  
  var gridUpdateDebouncer = W3WDebouncer<Void>(delay: 0.3, closure: { _ in })
  
  public init(w3w: W3WProtocolV4, scheme: W3WScheme? = .w3w, language: W3WLanguage = W3WSettings.defaultLanguage) {
    
    self.w3w = w3w
    self.scheme = scheme
    self.language = language
    
    self.mapGridColorListener()
    self.squareColorListener()
    self.squareLineThicknessListener()
    self.gridLineThicknessListener()
  }
  
  private func mapGridColorListener() {
    mapGridColor
      .sink { [weak self] color in
        self?.gridRenderer?.strokeColor = color.uiColor
      }
      .store(in: &cancellables)
  }
  
  private func squareColorListener() {
    squareColor
      .sink { [weak self] color in
        self?.squareRendererPointer?.strokeColor = color.uiColor
      }
      .store(in: &cancellables)
  }
  
  private func squareLineThicknessListener() {
    mapSquareLineThickness
      .sink { [weak self] lineThickness in
        self?.squareRendererPointer?.lineWidth = lineThickness.value
      }
      .store(in: &cancellables)
  }
  
  private func gridLineThicknessListener() {
    mapGridLineThickness
      .sink { [weak self] lineThickness in
        self?.gridRenderer?.lineWidth = lineThickness.value
      }
      .store(in: &cancellables)
  }
  
  public func set(scheme: W3WScheme?) {
    self.scheme = scheme
  }
  
  public func set(language: W3WLanguage) {
    self.language = language
  }
  
}

public class W3WMapGridLines: MKMultiPolyline {
}

public class W3WMapGridRenderer: MKMultiPolylineRenderer {
}

public class W3WMapSquareLines: MKPolyline {

  var box: W3WBaseBox {
    let points = self.points()
    let sw = points[3].coordinate  // SW is at index 3
    let ne = points[1].coordinate  // NE is at index 1
    return W3WBaseBox(southWest: sw, northEast: ne)
  }

  convenience init? (bounds: W3WBaseBox?) {
      guard let ne = bounds?.northEast,
            let sw = bounds?.southWest else {
        return nil
      }
      
      let nw = CLLocationCoordinate2D(latitude: ne.latitude, longitude: sw.longitude)
      let se = CLLocationCoordinate2D(latitude: sw.latitude, longitude: ne.longitude)
      let coordinates = [nw, ne, se, sw, nw]
      
      self.init(coordinates: coordinates, count: 5)
    }
}

public class W3WMapSquaresRenderer: MKPolylineRenderer {
  
  private var squareW3WImage: UIImage?
     // Cache the bounding rect to avoid recalculating it
     private var cachedBoundingRect: CGRect?
     
     override public func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
         super.draw(mapRect, zoomScale: zoomScale, in: context)
         
         // Only proceed with drawing if we have an image
       guard let w3wImage = squareW3WImage else {
         return
         
       }
         // Calculate the display rect if needed
         let displayRect = cachedBoundingRect ?? {
             let rect = self.rect(for: self.polyline.boundingMapRect)
             let imageRect = rect.insetBy(dx: self.lineWidth, dy: self.lineWidth)
             cachedBoundingRect = imageRect
             return imageRect
         }()
         
         // Use more efficient drawing methods
         UIGraphicsPushContext(context)
         context.saveGState()
         w3wImage.draw(in: displayRect, blendMode: .normal, alpha: 1.0)
         context.restoreGState()
         UIGraphicsPopContext()
     }
     
     // Method to set the W3WImage
     public func setSquareImage(_ w3wImage: UIImage?) {
         self.squareW3WImage = w3wImage
         self.cachedBoundingRect = nil // Invalidate cached rect
         self.setNeedsDisplay()
     }
}

#endif
