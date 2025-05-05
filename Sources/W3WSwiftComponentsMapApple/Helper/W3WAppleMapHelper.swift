//
//  W3WAppleMapHelper.swift
//  w3w-swift-components-map-apple
//
//  Created by Henry Ng on 16/12/24.
//

import MapKit
import Foundation
import W3WSwiftThemes
import W3WSwiftCore
import W3WSwiftComponentsMap
import W3WSwiftDesign

public class W3WAppleMapHelper: NSObject, W3WAppleMapDrawerProtocol, W3WAppleMapHelperProtocol {

  public weak var mapView: MKMapView?
  
  public var mapGridData: W3WAppleMapGridData?
  
  public var scheme: W3WScheme? = .w3w

  public var region: MKCoordinateRegion {
    return mapView?.region ?? MKCoordinateRegion()
  }
  
  public var annotations: [MKAnnotation] {
    return  mapView?.annotations ??  [MKAnnotation]()
  }
  
  public var overlays: [MKOverlay] {
    get {
      return mapView?.overlays ?? [MKOverlay]()
    }
  }
  
  public var mapType: MKMapType {
    get {
      return mapView?.mapType as! MKMapType
    }
    set {
      mapView?.mapType = newValue
      self.redrawAll()
      setGridColor()
    }
  }

  public var language: W3WLanguage = W3WSettings.defaultLanguage

 
  /// called when the user taps a square in the map
  public var onSquareSelected: (W3WSquare) -> () = { _ in }
  
  /// called when the user taps a square that has a marker added to it
  public var onMarkerSelected: (W3WSquare) -> () = { _ in }
  
  private var w3w: W3WProtocolV4

  public private(set) var markers: [W3WSquare] = []
  
  public init(mapView: MKMapView, _ w3w: W3WProtocolV4, language: W3WLanguage = W3WSettings.defaultLanguage ) {
    self.mapView = mapView
    self.w3w = w3w
    super.init()

    self.mapGridData = W3WAppleMapGridData(w3w: w3w, scheme: scheme, language: language)
    self.language = language

  }
  
  func setGridColor() {
    if let gridData = mapGridData {
      gridData.mapGridColor.send(mapType == .standard ? .mediumGrey : .white)
    }
  }
  
  func setGridLine() {
    if let gridData = mapGridData {
      gridData.mapGridLineThickness.send(4.0)
    }
  }
  
  func configure () {
    self.mapView?.showsUserLocation = true
  }

  public func set(language: W3WLanguage) {
    self.language = language
  }
  
  public func set(type: String) {
    switch type {
    case "standard":         self.mapType = .standard
    case "hybrid":           self.mapType = .hybrid
    case "satellite":        self.mapType = .satellite

    default:                  self.mapType = .standard
    }
  }
  
  public func set(scheme: W3WScheme?) {
    self.mapGridData?.set(scheme: scheme)
  }
  
  public func getType() -> W3WMapType {
    switch  self.mapType {
      case .standard: return "standard"
      case .satellite: return "hybridFlyover"
      case .hybrid: return "hybrid"

      default: return "standard"
    }
  }
  
  private func calculateZoomLevel(_ span: MKCoordinateSpan) -> Double {
      return log2(360.0 / span.latitudeDelta)
  }
  
  public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
    updateMap()
  }

  /// hijack this delegate call and update the grid, then pass control to the external delegate
  public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
    updateMap()
  }
  
  /// hijack this delegate call and update the grid, then pass control to the external delegate
  public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {

    updateMap()
  }

  public func mapView(_ mapView: MKMapView, mapTypeChanged type: MKMapType) {
    updateMap()
  }
  
  public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation, with transitionScale: CGFloat) -> MKAnnotationView? {
    if let a = getMapAnnotationView(annotation: annotation, transitionScale: transitionScale) {
      return a
    }
    
    return nil
  }

  public func addAnnotation(_ annotation: MKAnnotation) {
    mapView?.addAnnotation(annotation)
  }
  
  public func removeAnnotation(_ annotation: MKAnnotation) {
    mapView?.removeAnnotation(annotation)
    
  }
  
  public func removeOverlay(_ overlay: MKOverlay) {
    mapView?.removeOverlay(overlay)
  }
  
  public func removeOverlays(_ overlays: [MKOverlay]) {
    mapView?.removeOverlays(overlays)
  }
  
  public func addOverlay(_ overlay: MKOverlay) {
    mapView?.addOverlay(overlay)
  }
  
  public func addOverlays(_ overlays: [MKOverlay]) {
    mapView?.addOverlays(overlays)
  }
  
  public func addOverlays(_ overlays: [MKOverlay], _ color: W3WColor?) {
    mapView?.addOverlays(overlays)
  }
  
  public func addOverlay(_ overlay: MKOverlay, _ color: W3WColor? = nil) {
    
    if let color = color, let square = overlay as? W3WMapSquareLines {
       mapGridData?.overlayColors[square.box.id] = color
    }
    mapView?.addOverlay(overlay)
    
}
  
  public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    if let markerView =  view.annotation as? W3WAppleMapAnnotation {
    }
  }
  
  public func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer]) {
   
  }
  
  public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
      // Maintain a dictionary of positions by section
      var positionsBySection = [String: [CGPoint]]()
      
      // Minimum distance between pins in points
      let minDistance: CGFloat = 5.0
      
      for view in views {
          guard let annotation = view.annotation as? W3WAppleMapAnnotation else { continue }
          
          // Create a section key based on annotation's location
          // Round to nearest grid to group nearby pins
        let gridSize: Double = 0.0001 // Adjust based on your needs
        let latValue: Double = annotation.square?.coordinates?.latitude ?? annotation.coordinate.latitude
        let lngValue: Double = annotation.square?.coordinates?.longitude ?? annotation.coordinate.longitude

        let latSection = Int(latValue / gridSize)
        let lngSection = Int(lngValue / gridSize)
        let sectionKey = "\(latSection)_\(lngSection)"
          
          // Get current center point for this view
          let center = view.center
          
          // Get existing positions in this section
          var positions = positionsBySection[sectionKey] ?? []
          
          // Check if this position is too close to existing ones
          var needsAdjustment = false
          for existingPos in positions {
              let distance = hypot(center.x - existingPos.x, center.y - existingPos.y)
              if distance < minDistance {
                  needsAdjustment = true
                  break
              }
          }
          
          // If too close, apply a small offset
          if needsAdjustment {
              // Calculate offset direction (try to avoid overlaps)
              let offsetX = CGFloat(arc4random_uniform(2) == 0 ? -1 : 1) * minDistance * 0.7
              let offsetY = CGFloat(arc4random_uniform(2) == 0 ? -1 : 1) * minDistance * 0.7
              
              // Apply offset
              view.centerOffset = CGPoint(
                  x: view.centerOffset.x + offsetX,
                  y: view.centerOffset.y + offsetY
              )
          }
          
          // Add this position to our tracking dictionary
          positions.append(view.center)
          positionsBySection[sectionKey] = positions
      }
  }
  
}

public extension W3WAppleMapHelper {
  
  func select(at coordinates: CLLocationCoordinate2D, completion: @escaping (Result<W3WSquare, W3WError>) -> Void) {
    
    self.convertTo3wa(coordinates: coordinates, language: self.language)  { [weak self] square, error in
      
      guard let self = self else { return }
      
      if let e = error {
        W3WThread.runOnMain {
          self.mapGridData?.onError(e)
          completion(.failure(e))
        }
      }
      if let s = square {
        W3WThread.runOnMain {
         // self.select(at: s)
          completion(.success(s))
        }
      } else {
        W3WThread.runOnMain {
          let e = W3WError.message("No Square Found")
          completion(.failure(e))
         }
      }
    }
  }
  
  func select(at: W3WSquare) {
    createMarkerForConditions(at)
  }
  
  func createMarkerForConditions(_ at: W3WSquare) {
    
    let squares = self.mapGridData?.squares
    
    let selectedSquare = self.mapGridData?.selectedSquare
    
    let  isMarkerinList =  squares?.contains(where: { $0.bounds?.id ==  at.bounds?.id })
    
    let  isPrevMarkerinList =  squares?.contains(where: { $0.bounds?.id ==  selectedSquare?.bounds?.id })
    
    let annotation = findAnnotation(selectedSquare)
    
    let markers =  self.mapGridData?.markers
    
    let squareSize = getPointsPerSquare()

    if let selectedSquare = selectedSquare {
      if squareSize < self.mapGridData?.pointsPerSquare ?? CGFloat(12.0) {
        if (annotation?.isMarker == true && annotation?.isMark == false ) { //check the previous annotation is square
          let previousBoxId = selectedSquare.bounds?.id
          
          if let previousColor = self.mapGridData?.overlayColors[previousBoxId ?? 0] {
            removeSelectedSquare(at: selectedSquare)
            addMarkerAsCircle(at: selectedSquare, color: previousColor)
          }
          else{
            if markers != nil {
              removeSelectedSquare(at: selectedSquare)
              addMarkerAsCircle(at: selectedSquare, color: annotation?.color)
            }
          }
        }
        else{
          removeSelectedSquare(at: selectedSquare)
        }

        addSelectedMarker(at: at, color: .darkBlue, type: .square, isMarker: true, isMark: true)
        self.mapGridData?.selectedSquare = at
        
        return
      }
      removeSelectedSquare(at: selectedSquare)
    }

    //squares
    if isMarkerinList == true {
      removeSelectedSquare(at: selectedSquare)
      
      let currentBoxId = at.bounds?.id
      let previousBoxId = selectedSquare?.bounds?.id
      if isPrevMarkerinList == true {
        if let previousColor = self.mapGridData?.overlayColors[previousBoxId ?? 0] {
          addMarker(at: selectedSquare, color: previousColor, type: .circle)
        }
      }
      if let color = self.mapGridData?.overlayColors[currentBoxId ?? 0] {
        addSelectedMarker(at: at, color: color, type: .square, isMarker: true, isMark: false)
      }
      self.mapGridData?.squareIsMarker = at
      
    } else {
      let previousBoxId = selectedSquare?.bounds?.id
      if isPrevMarkerinList == true {
        if let previousColor = self.mapGridData?.overlayColors[previousBoxId ?? 0] {
         addMarkerAsCircle(at: selectedSquare, color: previousColor)
        }
      }
      addSelectedMarker(at: at, color: .darkBlue, type: .square, isMarker: true, isMark: true)
    }
    
    self.mapGridData?.selectedSquare = at
  }
 
  /// put a what3words annotation on the map showing the address
  func addMarker(at square: W3WSquare?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion) {
    addMarker(at: square, color: color, type: type, completion: completion)
  }
  
   func addMarker(at suggestion: W3WSuggestion?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion) {
     addMarker(at: suggestion, color: color, type: type, completion: completion)
  }
  
  func addMarker(at word: String?, color: W3WSwiftThemes.W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion) {
    
    addMarker(at: word, color: color, type: type, completion: completion)
  }
  
   func addMarker(at words: [String]?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion) {
    addMarker(at: words, color: color, type: type, completion: completion)
  }
  
   func addMarker(at coordinate: CLLocationCoordinate2D?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion) {
     addMarker(at: coordinate, color: color, type: type, completion: completion)
  }
  
   func addMarker(at squares: [W3WSquare]?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion) {
     addMarker(at: squares, color: color, type: type, completion: completion)
  }
  
   func addMarker(at suggestions: [W3WSuggestion]?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion) {
    addMarker(at: suggestions, color: color, type: type, completion: completion)
  }

   func addMarker(at coordinates: [CLLocationCoordinate2D]?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion) {
     addMarker(at: coordinates, color: color, type: type, completion: completion)
  }
  
   func removeMarker(at suggestion: W3WSuggestion?) {
    
  }
  
   func removeMarker(at words: String?) {
    
  }
  
   func removeMarker(at squares: [W3WSquare]?) {

  }
  
   func removeMarker(at suggestions: [W3WSuggestion]?) {
    
  }
  
   func removeMarker(at words: [String]?) {
    
  }
  
   func removeMarker(at square: W3WSquare?) {
    // removeMarker(at: square)
  }
  
   func removeMarker(group: String) {
    
  }
  
   func unselect() {
    
  }
  
   func hover(at: CLLocationCoordinate2D) {
    
  }
  
   func unhover() {
    
  }
  
   func set(zoomInPointsPerSquare: CGFloat) {
    
  }
  
  func getAllMarkers() -> [W3WSquare] {
    return [W3WSquare]()
  }
  
  func removeAllMarkers() {
    self.markers.removeAll()
    
    if let gridData = self.mapGridData {
      gridData.squares.removeAll()
      gridData.markers.removeAll()
      gridData.selectedSquare = nil
      gridData.squareIsMarker = nil
      gridData.currentSquare = nil
    }
  }
  func findMarker(by coordinates: CLLocationCoordinate2D) -> W3WSquare? {
    return nil
  }
}

extension W3WAppleMapHelper {
  
  public func updateCamera(camera: W3WMapCamera?) {
   
    W3WThread.runOnMain { [weak self] in
      if let self = self {
        if let center = camera?.center, let scale = camera?.scale {
          let region = MKCoordinateRegion(center: center, span: scale.asSpan(mapSize: mapView!.frame.size , latitude: center.latitude ))
          mapView?.setRegion(region, animated: true)
          
        } else if let center = camera?.center {
          mapView?.setCenter(center, animated: true)
          
        } else if let scale = camera?.scale {
          let region = MKCoordinateRegion(center: mapView!.centerCoordinate, span: scale.asSpan(mapSize: mapView!.frame.size, latitude: camera?.center?.latitude ?? 0.0))
          mapView?.setRegion(region, animated: true)
        }
      }
    }
  }
  
  public func updateSquare(square: W3WSquare?) {
    if let square = square {
      self.mapGridData?.currentSquare = square
      self.select(at: square)
    }
  }

  private func getNewMarkers(markersLists: W3WMarkersLists) -> W3WMarkersLists {
      guard let gridData = self.mapGridData else {
          return W3WMarkersLists()
      }
      
      // Create a new markers list to return
      let newMarkersLists = W3WMarkersLists()
      
      // Clear the automatically created default list
      newMarkersLists.lists.removeAll()
      
      // Process each list in the input
      for (listName, list) in markersLists.getLists() {
          // Skip empty lists or default list with no color
          if list.markers.isEmpty || (listName == "default" && list.color == nil) {
              continue
          }
          
          // Create a new list for this color
          let newList = W3WMarkerList()
          newList.color = list.color
          newList.type = list.type
          
          // Track already processed squares for this specific list
          var listProcessedIds = Set<Int64>()
          
          for marker in list.markers {
              if let bounds = marker.bounds {
                  let squareId = bounds.id
                  
                  // Skip if we've already processed this ID in this list
                  if listProcessedIds.contains(squareId) {
                      continue
                  }
                  
                  // Check if this square exists in overlay colors
                  if let existingColor = gridData.overlayColors[squareId] {
                      // Only include if the color is different
                      if let listColor = list.color, !colorComponentsMatch(existingColor.cgColor, listColor.cgColor) {
                          newList.markers.append(marker)
                      }
                  } else {
                      // Square doesn't exist in overlay colors, so include it
                      newList.markers.append(marker)
                  }
                  
                  // Mark this ID as processed for this list
                  listProcessedIds.insert(squareId)
              } else {
                  // No bounds, include it
                  newList.markers.append(marker)
              }
          }
          
          // Only add lists with markers
          if !newList.markers.isEmpty {
              newMarkersLists.add(listName: listName, list: newList)
          }
      }
      
      return newMarkersLists
  }
  // Helper function to compare color components
  private func colorComponentsMatch(_ color1: CGColor, _ color2: CGColor) -> Bool {
      // Check if color spaces match
      guard color1.colorSpace?.model == color2.colorSpace?.model else {
          return false
      }
      
      // Get components
      let components1 = color1.components ?? []
      let components2 = color2.components ?? []
      
      // Check if component counts match
      guard components1.count == components2.count else {
          return false
      }
      
      // Compare components with a small tolerance
      let tolerance: CGFloat = 0.001
      for i in 0..<components1.count {
          if abs(components1[i] - components2[i]) > tolerance {
              return false
          }
      }
      
      return true
  }
  
  public func updateMarkers(markersLists: W3WMarkersLists) {
      if !markersLists.getLists().isEmpty {
          for (_, list) in markersLists.getLists() {
              for marker in list.markers {
                  addMarker(at: marker, color: list.color, type: list.type ?? .circle)
              }
          }
      }
  }
  
  
  public func convertTo3wa(coordinates: CLLocationCoordinate2D, language: W3WLanguage = W3WBaseLanguage.english, completion: @escaping W3WSquareResponse ) {
    
    self.w3w.convertTo3wa(coordinates: coordinates, language: language) { [weak self]  square, error in
      guard self != nil else { return }
      
      if let error = error {
        W3WThread.runOnMain {
          completion(nil, error)
        }
      } else if let s = square {
        W3WThread.runOnMain {
          completion(s, nil)
        }
      }
    }
  }
}

extension W3WAppleMapHelper {
  
  public func setRegion(_ region: MKCoordinateRegion, animated: Bool) {
      mapView?.setRegion(region, animated: false)
  }

  public func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool) {
    mapView?.setCenter(coordinate, animated: animated)
  }

}
