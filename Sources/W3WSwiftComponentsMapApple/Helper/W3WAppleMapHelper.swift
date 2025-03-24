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

public class W3WAppleMapHelper: NSObject, W3WAppleMapGridDrawingProtocol, W3WAppleMapHelperProtocol {

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
  
 // typealias MarkerCompletion = (W3WSquare?, W3WError?) -> ()
  

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
      gridData.mapGridLineThickness.send(2.0)
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
  
  public func removeOverlays(_ overlay: [MKOverlay]) {
    mapView?.removeOverlays(overlays)
  }
  
  public func addOverlay(_ overlay: MKOverlay) {
    mapView?.addOverlay(overlay)
  }
  
  public func addOverlays(_ overlays: MKOverlay) {
    mapView?.addOverlay(overlays)
  }
  
  public func addOverlays(_ overlays: [MKOverlay], _ color: W3WColor?) {
    mapView?.addOverlays(overlays)
  }
  
  public func addOverlay(_ overlay: MKOverlay, _ color: W3WColor? = nil) {

    if let color = color, let square = overlay as? W3WMapSquareLines {
           
       let coloredPolyline = ColoredPolyline(polyline: square, color: color)
          mapGridData?.coloredPolylines.append(coloredPolyline)
    }

    mapView?.addOverlay(overlay)
  }

  
  public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    if let markerView =  view.annotation as? W3WAppleMapAnnotation {
      if let square = markerView.square {
      }
    }
  }
  
  public func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer]) {
   
  }
  
  public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
    
  }
  
}


public extension W3WAppleMapHelper {
  
  func select(at coordinates: CLLocationCoordinate2D, completion: @escaping (Result<W3WSquare, W3WError>) -> Void) {
    
    self.convertTo3wa(coordinates: coordinates ??  CLLocationCoordinate2D(), language: self.language)  { [weak self] square, error in
      
      guard let self = self else { return }
      
      if let e = error {
        W3WThread.runOnMain {
          self.mapGridData?.onError(e)
          completion(.failure(e))
        }
      }
      if let s = square {
        W3WThread.runOnMain {
          self.select(at: s)
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
    createMarkerForCondition(at: at)
  
    //sample code to update markers
   // let markersList = W3WMarkersLists(defaultColor: .w3wBrandBase)
  //  markersList.add(listName: "favorites", color: .w3wBrandBase)
  //  markersList.add(square: at, listName: "favorites")
    
  //  self.mapGridData?.savedList = markersList
    
   // completion(markersList)
    ///Sample code to add
    
//    var randomColors: [W3WColor] = []
//    
//    for _ in 0..<10 {
//        let red = CGFloat.random(in: 0...1)
//        let green = CGFloat.random(in: 0...1)
//        let blue = CGFloat.random(in: 0...1)
//        let uiColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
//        let randomColor = W3WColor(uiColor: uiColor)
//      
//      randomColors.append(randomColor)
//    }
//    
//    let randomIndex = Int.random(in: 0..<randomColors.count)
//    
//    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
//      
//      guard let self = self else { return }
//      removeMarker(at: selectedSquare)
//      addSelectedMarker(at: at, color: randomColors[randomIndex], type: .square, isMarker: false, isMark: false)
//    }

 }
  
  func createMarkerForCondition(at: W3WSquare) {
    
    var squares = self.mapGridData?.squares
    
    let selectedSquare = self.mapGridData?.selectedSquare
    
    let  isMarkerinList =  squares?.contains(where: { $0.bounds?.id ==  at.bounds?.id })
    
    let  isPrevMarkerinList =  squares?.contains(where: { $0.bounds?.id ==  selectedSquare?.bounds?.id })
    
    let annotation = self.findAnnotation(selectedSquare)
    
    let markers =  self.mapGridData?.markers
    
    let squareSize = getPointsPerSquare()

    if let selectedSquare = selectedSquare {
   //   if(annotations.count != 0 && squares?.count == 0) {
      if squareSize < self.mapGridData?.pointsPerSquare ?? CGFloat(12.0) {
        if (annotation?.isMarker == true && annotation?.isMark == false ) { //check the previous annotation is square
          let previousBoxId = selectedSquare.bounds?.id
          
          if let previousColor = self.mapGridData?.overlayColors[previousBoxId ?? 0] {
            removeSelectedSquare(at: selectedSquare)
            addMarkerAsCircle(at: selectedSquare, color: previousColor)
          }
        }
        else{
          removeSelectedSquare(at: selectedSquare)
        }
        let previousBoxId = selectedSquare.bounds?.id
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
      //    addSelectedMarker(at: selectedSquare, color: previousColor, type: .circle, isMarker: true, isMark: true)
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
  
  public func getAllMarkers() -> [W3WSquare] {
    return [W3WSquare]()
  }
  
  public func removeAllMarkers() {
    self.markers.removeAll()
    
    if var gridData = self.mapGridData {
      gridData.squares.removeAll()
      gridData.markers.removeAll()
      gridData.selectedSquare = nil
      gridData.squareIsMarker = nil
      gridData.currentSquare = nil
    }
  }
  public func findMarker(by coordinates: CLLocationCoordinate2D) -> W3WSquare? {
    return nil
  }


}

extension W3WAppleMapHelper {
  
  public func updateCamera(camera: W3WMapCamera?) {
   
//    W3WThread.runOnMain { [weak self] in
//      if let self = self {
//        if let center = camera?.center, let scale = camera?.scale {
//          let region = MKCoordinateRegion(center: center, span: scale.asSpan(mapSize: mapView!.frame.size , latitude: center.latitude ))
//          mapView?.setRegion(region, animated: true)
//          
//        } else if let center = camera?.center {
//          mapView?.setCenter(center, animated: true)
//          
//        } else if let scale = camera?.scale {
//          let region = MKCoordinateRegion(center: mapView!.centerCoordinate, span: scale.asSpan(mapSize: mapView!.frame.size, latitude: camera?.center?.latitude ?? 0.0))
//          mapView?.setRegion(region, animated: true)
//        }
//      }
//    }
  }
  
  public func updateSquare(square: W3WSquare?) {
    
  }
  
  public func updateMarkers(markers: W3WMarkersLists) {
    removeAllMarkers()
    for (_, list) in markers.getLists() {
      for marker in list.markers {
       // addMarker(at: marker, color: list.color, type: .circle)
        print(marker.words, list.color)
      }
    }
  }
  
  public func convertTo3wa(coordinates: CLLocationCoordinate2D, language: W3WLanguage = W3WBaseLanguage.english, completion: @escaping W3WSquareResponse ) {
    
    self.w3w.convertTo3wa(coordinates: coordinates, language: language) { [weak self]  square, error in
      guard let self = self else { return }
      
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
  
  func findSquare(_ square: W3WSquare) -> W3WSquare? {
    return (self.mapGridData?.squares ?? []).first { s in
      let idMatch = s.bounds?.id == square.bounds?.id
        return idMatch
      }
    return nil
  }
}

extension W3WAppleMapHelper {
  
  public func setRegion(_ region: MKCoordinateRegion, animated: Bool) {
      mapView?.setRegion(region, animated: false)
  }

  public func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool) {
    mapView?.setCenter(coordinate, animated: animated)
  }
  
  public func updateZoomLevel() {
    
  }
  
}


extension W3WAppleMapHelper {
  
  func findAnnotation(_ square: W3WSquare?) -> W3WAppleMapAnnotation? {
    for annotation in annotations {
      if let a = annotation as? W3WAppleMapAnnotation {
        if (a.square?.bounds?.id == square?.bounds?.id) {
          return a
        }
      }
    }
    
    return nil
  }
}
