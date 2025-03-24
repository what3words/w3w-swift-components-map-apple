//
//  W3WApplemapViewProtocol.swift
//  w3w-swift-components-map-apple
//
//  Created by Henry Ng on 17/1/25.
//

#if !os(macOS) && !os(watchOS)

import Foundation
import MapKit
import W3WSwiftCore
import W3WSwiftThemes
import W3WSwiftComponentsMap
import Combine


public protocol W3WAppleMapGridDrawingProtocol {
  
  var mapView: MKMapView? { get }
  var region: MKCoordinateRegion { get }
  var overlays: [MKOverlay] { get }
  var annotations: [MKAnnotation] { get }
  var mapGridData: W3WAppleMapGridData? { get set }
  
  func addOverlay(_ overlay: MKOverlay)
  func addOverlay(_ overlay: MKOverlay, _ color: W3WColor?)
  func removeOverlay(_ overlay: MKOverlay)
  func removeOverlays(_ overlays: [MKOverlay])
  func addAnnotation(_ annotation: MKAnnotation)
  func removeAnnotation(_ annotation: MKAnnotation)
  
  func setRegion(_ region: MKCoordinateRegion, animated: Bool)
  func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool)
}

extension W3WAppleMapGridDrawingProtocol {
  
  public func updateMap() {
    
    updateGrid()
    
    if let lastZoomPointsPerSquare = mapGridData?.lastZoomPointsPerSquare {
      let squareSize = getPointsPerSquare()
      if (squareSize < CGFloat(12.0) && lastZoomPointsPerSquare > CGFloat(12.0)) || (squareSize > CGFloat(12.0) && lastZoomPointsPerSquare < CGFloat(12.0)) {
        
        redrawPins()
      }
      
      mapGridData?.lastZoomPointsPerSquare = squareSize
    }
  }
  
  func updateGrid() {
    updateGridAlpha()
    
    mapGridData?.gridUpdateDebouncer.closure = { _ in self.makeGrid() }
    mapGridData?.gridUpdateDebouncer.execute(())
  }
  
  func makeGrid() {
    
    let sw = CLLocationCoordinate2D(latitude: region.center.latitude - region.span.latitudeDelta * 3.0, longitude: region.center.longitude - region.span.longitudeDelta * 3.0)
    let ne = CLLocationCoordinate2D(latitude: region.center.latitude + region.span.latitudeDelta * 3.0, longitude: region.center.longitude + region.span.longitudeDelta * 3.0)
    
    // call w3w api for lines, if the area is not too great
    if let distance = mapGridData?.w3w?.distance(from: sw, to: ne) {
      if distance < W3WSettings.maxMetersDiagonalForGrid {
        
        mapGridData?.w3w?.gridSection(southWest:sw, northEast:ne) { lines, error in
          self.makeNewGrid(lines: lines)
        }
      }
    }
  }
  
  func makeNewGrid(lines: [W3WLine]?) {
    DispatchQueue.main.async {
      self.makePolygons(lines: lines)
      // replace the overlay with a new one with the new lines
      if let overlay = mapGridData?.gridLines {
        self.removeGrid()
        addOverlay(overlay)
      }
    }
  }
  
  func makePolygons(lines: [W3WLine]?) {
    
    var multiLine = [MKPolyline]()
    
    for line in lines ?? [] {
      multiLine.append(MKPolyline(coordinates: [line.start, line.end], count: 2))
    }
    mapGridData?.gridLines = W3WMapGridLines(multiLine)
  }
  
  public func mapRenderer(overlay: MKOverlay) -> MKOverlayRenderer? {
    
    if let o = overlay as? W3WMapGridLines {
      return getMapGridRenderer(overlay: o)
    }
    
    if let o = overlay as? W3WMapSquareLines {
      return getMapSquaresRenderer(overlay: o)
    }
    
    return MKOverlayRenderer()
  }
  
  func getMapGridRenderer(overlay: MKOverlay) -> MKOverlayRenderer? {
    
    if let gridLines = overlay as? W3WMapGridLines {
      mapGridData?.gridRenderer = W3WMapGridRenderer(multiPolyline: gridLines)
      mapGridData?.gridRenderer?.strokeColor = mapGridData?.mapGridColor.value.uiColor
      mapGridData?.gridRenderer?.lineWidth =  mapGridData?.mapGridLineThickness.value.value ?? CGFloat(0.5) //mapGridData?.scheme?.styles?.lineThickness?.value ?? CGFloat(0.5)
      updateGridAlpha()
      return mapGridData?.gridRenderer
    }
    
    return nil
  }
  
   func getMapSquaresRenderer(overlay: MKOverlay) -> MKOverlayRenderer? {
    
     guard let mapGridData = self.mapGridData else { return nil }
     
    if let square = overlay as? W3WMapSquareLines {
      let squareRenderer = W3WMapSquaresRenderer(overlay: square)

      let boxId = square.box.id //current square renderer
      let isSelectedSquare = mapGridData.selectedSquare?.bounds?.id == boxId
      
      let  isMarker = mapGridData.markers.contains(where: { $0.bounds?.id == square.box.id })
      
      let  isSquare = mapGridData.squares.contains(where: { $0.bounds?.id == square.box.id })
      
      var bgSquareColor: W3WColor?  = .w3wBrandBase

      if let coloredSquare = mapGridData.coloredPolylines.first(where: { $0.polyline === square }) {
        bgSquareColor = coloredSquare.color
      }
      else {
          if let color = mapGridData.overlayColors[boxId] {
            bgSquareColor = color

              let coloredPolyline = ColoredPolyline(polyline: square, color: color)
            mapGridData.coloredPolylines.append(coloredPolyline)
          }
      }

      let w3wImage: UIImage?
      w3wImage = W3WImageCache.shared.getImage(for: bgSquareColor ?? .w3wBrandBase, size: CGSize(width: 25, height: 25)) ?? W3WImageCache.shared.getImage(for: .w3wBrandBase, size: CGSize(width: 25, height: 25))

     if (isSelectedSquare) {
       if (isMarker == true) {
         squareRenderer.lineWidth = 1.0
         squareRenderer.strokeColor = .black
     //    squareRenderer.setSquareImage(w3wImage1)
         
         if (isSquare == true) { // in list
           squareRenderer.setSquareImage(w3wImage)
         }
       }
       else {
         squareRenderer.strokeColor = W3WColor.mediumGrey.uiColor
         squareRenderer.lineWidth = 0.1
         squareRenderer.setSquareImage(w3wImage)
       }

     } else {
        squareRenderer.strokeColor = W3WColor.mediumGrey.uiColor
        squareRenderer.lineWidth = 0.1
        squareRenderer.setSquareImage(w3wImage)
      }
      
      mapGridData.squareRenderer = squareRenderer
      return squareRenderer
      
      }
    return nil
  }

  /// remove the grid overlay
  func removeGrid() {
    for overlay in overlays {
      if let gridOverlay = overlay as? W3WMapGridLines {
        self.removeOverlay(gridOverlay)
      }
    }
    
  }
  
  func getPointsPerSquare() -> CGFloat {
    let threeMeterMapSquare = MKCoordinateRegion(center: mapView!.centerCoordinate, latitudinalMeters: 3, longitudinalMeters: 3);
    let threeMeterViewSquare = mapView!.convert(threeMeterMapSquare, toRectTo: nil)
    
    return threeMeterViewSquare.size.height
  }
  
  func redrawAll() {
    redrawPins()
    redrawGrid()
    redrawSquares()
  }
  
  /// force a redrawing of all grid lines
  func redrawGrid() {
    makeGrid()
  }
  
  /// force a redrawing of all annotations
  func redrawPins() {
    
  //  print("redrawPins: \(annotations.count)")
    for annotation in annotations {
      removeAnnotation(annotation)
      addAnnotation(annotation)
    }
  }
  
  func redrawSquares() {
    self.updateSquares()
  }
  
  func updateGridAlpha() {
    
    var alpha = CGFloat(0.0)
    
    let pointsPerSquare = self.getPointsPerSquare()
    if pointsPerSquare > CGFloat(11.0) {
      alpha = (pointsPerSquare - CGFloat(11.0)) / CGFloat(11.001)
    }
    
    if alpha > 1.0 {
      alpha = 1.0
      
    } else if alpha < 0.0 {
      alpha = 0.0
    }
    mapGridData?.gridRenderer?.alpha = alpha
    
  }
  
}

extension W3WAppleMapGridDrawingProtocol {

  // MARK: Pins / Annotations
  
  func getMapAnnotationView(annotation: MKAnnotation, transitionScale: CGFloat) -> MKAnnotationView? {
    
    if let a = annotation as? W3WAppleMapAnnotation {
      let squareSize = getPointsPerSquare()
      if squareSize > CGFloat(12.0) {
        if let square = a.square {
          showOutline(square, a)
        }
        //return an empty box
        let box = MKAnnotationView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0))
        return box
      } else {
        if let square = a.square {
          hideOutline(square)
        }
        return getMapPinView(annotation: a)
      }
    }
    return nil
  }
  
  
  func showOutline(_ square: W3WSquare, _ annotation: W3WAppleMapAnnotation? = nil) {
      W3WThread.runInBackground {
        if let s = self.ensureSquareHasCoordinates(square: square),
           let bounds = s.bounds,
           let gridData = self.mapGridData {
         W3WThread.runOnMain {

           if (annotation?.isMarker == true ) {
             if let m = annotation?.square {
               gridData.markers.removeAll()
               gridData.markers.append(m)
             }
             if (annotation?.isSaved == true) {
               self.addUniqueSquare(s)
             }
           }
           else{
             self.addUniqueSquare(s)
           }
           
           if let squareIsMarker = gridData.squareIsMarker {
             self.addUniqueSquare(squareIsMarker)
           }

          let boundsId = bounds.id
           gridData.overlayColors[boundsId] = annotation?.color
           
         }
          DispatchQueue.main.sync(flags: .barrier) { }
          
          self.updateSquares()
          self.updateSelectedSquare()
        }
      }
  }
  
  /// makes overlays from the squares

  func updateSquares() {
      guard let gridData = self.mapGridData else { return }
      
      // Create a dispatch group to coordinate synchronization
      let group = DispatchGroup()
      
      var colorsCopy = [Int64: W3WColor]()
      
      // Enter the group before starting work
      group.enter()
      
      // Get colors from main thread
      W3WThread.runOnMain {
          colorsCopy = gridData.overlayColors
          group.leave() // Signal that colors are ready
      }
      
      // Wait for colors to be copied
      group.wait()
      
      // Initialize the hash tracking variable if needed
      if gridData.previousStateHash == nil {
          gridData.previousStateHash = 0
      }
      
      // Create a comprehensive hash of the entire rendering state
      var stateHasher = Hasher()
      
      // Hash the square IDs
      for square in gridData.squares ?? [] {
          if let id = square.bounds?.id {
              stateHasher.combine(id)
          }
      }
      
      // Hash the colors
      for (id, color) in colorsCopy {
          stateHasher.combine(id)
          stateHasher.combine(color.description)
      }

      // Hash the selected square
      if let selectedId = gridData.selectedSquare?.bounds?.id {
          stateHasher.combine(selectedId)
      }
      
      // Hash the markers commented out in your implementation
      // for marker in gridData.markers {
      //     if let id = marker.bounds?.id {
      //         stateHasher.combine(id)
      //     }
      // }

      let currentStateHash = stateHasher.finalize()
      
      // If nothing has changed, skip the update
      if currentStateHash == gridData.previousStateHash && gridData.previousStateHash != 0 {
          return
      }
      
      // Update hash for next comparison
      gridData.previousStateHash = currentStateHash
      
      var boxes = [(polyline: W3WMapSquareLines, color: W3WColor?)]()
      
      for square in gridData.squares ?? [] {
          if let ne = square.bounds?.northEast,
             let sw = square.bounds?.southWest {
              
              let nw = CLLocationCoordinate2D(latitude: ne.latitude, longitude: sw.longitude)
              let se = CLLocationCoordinate2D(latitude: sw.latitude, longitude: ne.longitude)
              let polyline = W3WMapSquareLines(coordinates: [nw, ne, se, sw, nw], count: 5)

              polyline.associatedSquare = square
              
              let boxId = polyline.box.id ?? 0
              let color = colorsCopy[boxId]
          
              boxes.append((polyline: polyline, color: color))
          }
      }
    
      if !gridData.coloredPolylines.isEmpty {
          gridData.coloredPolylines.removeAll()
      }
      
      // Create a local copy of boxes to ensure thread safety
      let boxesCopy = boxes

      W3WThread.runOnMain {
          self.removeSquareOverlays()
          // Use boxesCopy instead of the original boxes array
          for box in boxesCopy {
              self.addOverlay(box.polyline, box.color)
          }
      }
  }
  
  func updateSelectedSquare() {
    guard let gridData = self.mapGridData else { return }
    
    let markers = gridData.markers
      self.makeMarkers(markers)
  }
  
  func makeMarkers(_ markers: [W3WSquare]?) {
 
      var boxes1 = [MKPolyline]()
      
      for (index, marker) in (markers ?? []).enumerated() {

          if let ne1 = marker.bounds?.northEast,
             let sw1 = marker.bounds?.southWest {
            
              let nw1 = CLLocationCoordinate2D(latitude: ne1.latitude, longitude: sw1.longitude)
              let se1 = CLLocationCoordinate2D(latitude: sw1.latitude, longitude: ne1.longitude)
              boxes1.append(W3WMapSquareLines(coordinates: [nw1, ne1, se1, sw1, nw1], count: 5))
          }
      }

      W3WThread.runOnMain {

        for bx in boxes1 {
          addOverlay(bx)
        }
      }
  }
  
  func findSquare(_ square: W3WSquare) -> W3WSquare? {
    for s in self.mapGridData?.squares ?? [] {
      if s.bounds?.id == square.bounds?.id  {
        return s
      }
    }
    return nil
  }
  
  func findMarker(_ square: W3WSquare) -> W3WSquare? {
    for m in self.mapGridData?.markers ?? [] {
      if m.bounds?.id == square.bounds?.id  {
        return m
      }
    }
    return nil
  }
  
  /// remove the grid overlay
  func removeSquareOverlays() {
    for overlay in overlays {
      if let squareOverlay = overlay as? W3WMapSquareLines {
        removeOverlay(squareOverlay)
      }
    }
  }
  
  func hideOutline(_ words: String) {
    self.mapGridData?.squares.removeAll(where: { s in
      return s.words == words
    })
    self.updateSquares()
  }

  func getMapPinView(annotation: W3WAppleMapAnnotation) -> MKAnnotationView? {
    return pinView(annotation: annotation)
  }
  
  /// make a custom annotation view
  func pinView(annotation: W3WAppleMapAnnotation) -> MKAnnotationView? {
    
    let identifier = "w3wPin"
    let color : W3WColor? =  annotation.color
    var pinImage: UIImage?
    let pinSize = CGFloat(40.0) 
    var centerOffset: CGPoint = .zero
    let s = annotation.square
    let w  = s?.words

    if case .circle = annotation.type {
      pinImage = W3WImage(drawing: .mapCircle, colors: .standardMaps.with(background: color)).get(size: W3WIconSize(value: CGSize(width: mapGridData?.pinWidth ?? CGFloat(30.0) , height: mapGridData?.pinHeight ?? CGFloat(30.0))))
      centerOffset = CGPoint(x: 0.0, y: 0.0)
    }
    
    if case .square = annotation.type {
      pinImage = W3WImage(drawing: .mapPin, colors: .standardMaps.with(background: color))
        .get(size: W3WIconSize(value: CGSize(width: (mapGridData?.pinSize ??  CGFloat(40.0)) / 2.0  , height: (mapGridData?.pinSize ?? CGFloat(40.0)) / 2.0)))
      centerOffset = CGPoint(x: 0.0, y: (-10))
    }
    
    
    let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
    annotationView.image = pinImage
    annotationView.frame.size = CGSize(width:mapGridData?.pinWidth ?? CGFloat(35), height: mapGridData?.pinHeight ?? CGFloat(35))
     annotationView.centerOffset = centerOffset
   
    return annotationView
  }
}

extension W3WAppleMapGridDrawingProtocol {
  
  // MARK: SQUARES CHECK
  
  func ensureSquareHasCoordinates(square: W3WSquare) -> W3WSquare? {
    let s = ensureSquaresHaveCoordinates(squares: [square])
    return s.first
  }
  
  func ensureSquaresHaveCoordinates(squares: [W3WSquare]) -> [W3WSquare] {
    //checkConfiguration()
    if W3WThread.isMain() {
      print(#function, " must NOT be called on main thread")
      abort()
    }
    
    var goodSquares = [W3WSquare]()
    
    let tasks = DispatchGroup()
    
    // for each square, make sure it is complete with coordinates and words
    for square in squares {
      tasks.enter()
      complete(square: square) { completeSquare in
        if let s = completeSquare {
          goodSquares.append(s)
        }
        tasks.leave()
      }
    }
    
    // wait for all the squares to be completed
    tasks.wait()
    
    return goodSquares
  }
  
  func completeSquareWithCoordinates(square: W3WSquare) -> W3WSquare? {
    let completedSquares = completeSquaresWithCoordinates(squares: [square])
    return completedSquares.first
  }
  
  func convertToSquaresWithCoordinates(words: [String]) -> [W3WSquare] {
    var squares = [W3WSquare]()
    
    for word in words {
      squares.append(W3WBaseSquare(words: word))
    }
    
    return ensureSquaresHaveCoordinates(squares: squares)
  }
  
  func convertToSquaresWithCoordinates(suggestions: [W3WSuggestion]) -> [W3WSquare] {
    var squares = [W3WSquare]()
    
    for suggestion in suggestions {
      squares.append(W3WBaseSquare(words: suggestion.words))
    }
    
    return ensureSquaresHaveCoordinates(squares: squares)
  }
  
  func convertToSquares(coordinates: [CLLocationCoordinate2D]) -> [W3WSquare] {
    var squares = [W3WSquare]()
    
    for coordinate in coordinates {
      squares.append(W3WBaseSquare(coordinates: coordinate))
    }
    
    return ensureSquaresHaveCoordinates(squares: squares)
  }
 
  func completeSquaresWithCoordinates(squares: [W3WSquare]) -> [W3WSquare] {
    
    if W3WThread.isMain() {
      
      let error = W3WError.message("must NOT be called on main thread")
      //   self.errorHandler(error: error)
      print(#function, " must NOT be called on main thread")
      abort()
    }
    
    var completedSquares = [W3WSquare]()
    let tasks = DispatchGroup()
    
    // for each square, make sure it is complete with coordinates and words
    for square in squares {
      tasks.enter()
      complete(square: square) { completeSquare in
        if let s = completeSquare {
          completedSquares.append(s)
        }
        tasks.leave()
      }
    }
    
    // wait for all the squares to be completed
    tasks.wait()
    
    return completedSquares
  }
  
  /// check a square and fill out it's words or coordinates as needed, then return a completed square via completion block
  func complete(square: W3WSquare, completion: @escaping (W3WSquare?) -> ()) {
    
    // if the square has words but no coordinates
    if square.coordinates == nil {
      if let words = square.words {
        self.mapGridData?.w3w?.convertToCoordinates(words: words) { result, error in
          //  self.errorHandler(error: error)
          completion(result)
        }
        
        // else if the square has no words and no coordinates then it is useless and we omit it
      } else {
        completion(nil)
      }
      
      // else if the square has coordinates but no words
    } else if square.words == nil {
      if let coordinates = square.coordinates {
        self.mapGridData?.w3w?.convertTo3wa(coordinates: coordinates, language:   self.mapGridData?.language ?? W3WSettings.defaultLanguage ) { result, error in
          //  self.errorHandler(error: error)
          completion(result)
        }
        
        // else if the square has no words and no coordinates then it is useless and we omit it
      } else {
        completion(nil)
      }
      
      // else the square already has coordinates and words
    } else {
      completion(square)
    }
  }
  
  /// put a what3words annotation on the map showing the address
  func addMarker(at words: String?, color: W3WColor? = nil, type: W3WMarkerType, completion: @escaping MarkerCompletion = { _,_ in }) {
    W3WThread.runOnMain {
      if let w = words {
        self.mapGridData?.w3w?.convertToCoordinates(words: w) { square, error in
          //  self.errorHandler(error: error)
          if let s = square {
            self.addMarker(at: s, color: color, type: type)
          }
        }
      }
    }
  }
  
  /// put a what3words annotation on the map showing the address
  public func addMarker(at words: [String]?, color: W3WColor? = nil, type: W3WMarkerType, completion: @escaping MarkerCompletion = { _,_ in }) {
    W3WThread.runOnMain {
      if let w = words {
        W3WThread.runInBackground {
          let squaresWithCoords = self.convertToSquaresWithCoordinates(words: w)
          
          // if there's a bad square then error out
          if squaresWithCoords.count != words?.count {
            completion(nil, W3WError.message("Invalid three word address, or coordinates passed into map function"))
            
            // otherwise go for it
          } else {
            self.addMarker(at: squaresWithCoords, color: color, type: type)
          }
        }
      }
    }
  }
  
  
  /// put a what3words annotation on the map showing the address, and optionally center the map around it
  func addMarker(at square: W3WSquare?, color:  W3WColor? = nil, type: W3WMarkerType, completion: @escaping MarkerCompletion = { _,_ in }) {
    W3WThread.runOnMain {
      if let sq = square {
        W3WThread.runInBackground {
          if let s = self.completeSquareWithCoordinates(square: sq) {
            self.addAnnotation(square: s, color: color, type: type)
            completion(s , nil)
          }
        }
      }
    }
  }
  
  /////////////
  ///
  func addSelectedMarker(at square: W3WSquare?, color:  W3WColor? = nil, type: W3WMarkerType, isMarker: Bool? = false, isMark: Bool? = false, isSaved: Bool? = false, completion: @escaping MarkerCompletion = { _,_ in }) {
    W3WThread.runOnMain {
      if let sq = square {
        W3WThread.runInBackground {
          if let s = self.completeSquareWithCoordinates(square: sq) {
            self.addAnnotation(square: s, color: color, type: type, isMarker: isMarker, isMark: isMark, isSaved: isSaved)
            completion(s , nil)
          }
        }
      }
    }
  }
  
  
  
  /// add an annotation to the map given a square this compensates for missing words or missing
  /// coordiantes, and does nothing if neither is present
  /// this is the one that actually does the work.  The other addAnnotations calls end up calling this one.
  func addAnnotation(square: W3WSquare, color: W3WColor? = nil, type: W3WMarkerType, isMarker: Bool? = false, isMark: Bool? = false, isSaved: Bool? = false) {
    W3WThread.runOnMain {
      W3WThread.runInBackground {
        if let s = self.completeSquareWithCoordinates(square: square) {
          W3WThread.runOnMain {
            self.removeMarker(at: square)
            addAnnotation(W3WAppleMapAnnotation(square: s, color: color, type: type, isMarker: isMarker, isMark: isMark, isSaved: isSaved))
          }
        }
      }
    } 
  }
  
  func addCirclePin(square: W3WSquare, color: W3WColor? = nil) {
    W3WThread.runOnMain {
    //  W3WThread.runInBackground {
      addAnnotation(W3WAppleMapAnnotation(square: square, color: color, type: .circle, isMarker: false, isMark: false ))
 //    }
    }
  }
  
  func addMarkerAsCircle(at square: W3WSquare?, color:  W3WColor? = nil, completion: @escaping MarkerCompletion = { _,_ in }) {
    W3WThread.runOnMain {
      //  W3WThread.runInBackground {
          if let s = square {
            self.addCirclePin(square: s, color: color)
              completion(s , nil)
          }
     //   }
    }
  }
  
  /// put a what3words annotation on the map showing the address
  func addMarker(at suggestion: W3WSuggestion?,  color: W3WColor? = nil, type: W3WMarkerType, completion: @escaping MarkerCompletion = { _,_ in }) {
    if let words = suggestion?.words {
      addMarker(at: words, color: color, type: type, completion: completion)
    }
  }
  
  /// put a what3words annotation on the map showing the address
  public func addMarker(at suggestions: [W3WSuggestion]?, color: W3WColor? = nil, type: W3WMarkerType, completion: @escaping MarkerCompletion = { _,_ in }) {
    W3WThread.runOnMain {
      if let s = suggestions {
        W3WThread.runInBackground {
          let squaresWithCoords = self.convertToSquaresWithCoordinates(suggestions: s)
          
          // if there's a bad square then error out
          if squaresWithCoords.count != suggestions?.count {
            completion(nil, W3WError.message("Invalid three word address, or coordinates passed into map function"))
            
            // otherwise go for it
          } else {
            self.addMarker(at: squaresWithCoords, color: color, type: type, completion: completion)
          }
        }
      }
    }
  }
  
  
  /// put a what3words annotation on the map showing the address
  func addMarker(at coordinates: CLLocationCoordinate2D?, color: W3WColor? = nil, type: W3WMarkerType, completion: @escaping MarkerCompletion = { _,_ in }) {
    W3WThread.runOnMain {
      if let c = coordinates {
        // self.checkConfiguration()
        self.mapGridData?.w3w?.convertTo3wa(coordinates: c, language: self.mapGridData?.language ?? W3WSettings.defaultLanguage) { square, error in
          //  self.dealWithAnyApiError(error: error)
          if let s = square {
            self.addMarker(at: s, color: color, type: type, completion: completion)
          }
        }
      }
    }
  }
  
  /// put a what3words annotation on the map showing the address
  public func addMarker(at coordinates: [CLLocationCoordinate2D]?, color: W3WColor? = nil, type: W3WMarkerType, completion: @escaping MarkerCompletion = { _,_ in })  {
    W3WThread.runOnMain {
      if let c = coordinates {
        W3WThread.runInBackground {
          let squaresWithCoords = self.convertToSquares(coordinates: c)
          
          // if there's a bad square then error out
          if squaresWithCoords.count != coordinates?.count {
            completion(nil, W3WError.message("Invalid three word address, or coordinates passed into map function"))
            
            // otherwise go for it
          } else {
            self.addMarker(at: squaresWithCoords, color: color, type: type, completion: completion)
          }
        }
      }
    }
  }
  
  
  
  /// put a what3words annotation on the map showing the address
  func addMarker(at squares: [W3WSquare]?, color: W3WColor? = nil, type: W3WMarkerType, completion: @escaping MarkerCompletion = { _,_ in }) {
    
    W3WThread.runOnMain {
      if let s = squares {
        W3WThread.runInBackground {
          let goodSquares = self.ensureSquaresHaveCoordinates(squares: s)
          
          // error out if not all squares are valid
          if goodSquares.count != s.count {
            completion(nil, W3WError.message("Invalid three word address, or coordinates passed into map function"))
            
            // good squares, proceed to place on map
          } else {
            completion(goodSquares as! W3WSquare, nil)
          }
        }
      }
    }
  }
}


extension W3WAppleMapGridDrawingProtocol {
  
  /// remove a what3words annotation from the map if it is present
  public func removeMarker(at suggestion: W3WSuggestion?) {
    if let words = suggestion?.words {
      removeMarker(at: words)
    }
  }
  
    public func removeMarker(at words: String?) {
      if let w = words {
        for annotation in annotations {
          if let a = annotation as? W3WAppleMapAnnotation {
            if let square = a.square {
              if square.words == w {
                self.removeAnnotation(a)
                self.hideOutline(w)
              }
            }
          }
        }
      }
    }
  
  /// remove what3words annotations from the map if they are present
  public func removeMarker(at suggestions: [W3WSuggestion]?) {
    for suggestion in suggestions ?? [] {
      removeMarker(at: suggestion)
    }
  }
  
  /// remove what3words annotations from the map if they are present
  public func removeMarker(at squares: [W3WSquare]?) {
    for square in squares ?? [] {
      removeMarker(at: square)
    }
  }
  
  /// remove what3words annotations from the map if they are present
  public func removeMarker(at words: [String]?) {
    for word in words ?? [] {
      removeMarker(at: word)
    }
  }
  
  /// remove a what3words annotation from the map if it is present
  /// this is the one that actually does the work.  The other remove calls
  /// end up calling this one.
  public func removeMarker(at square: W3WSquare?) {
    if let s = square {
      if let annotation = findAnnotation(s) {
        removeAnnotation(annotation)
        hideOutline(s)
      }
    }
  }
  
  func hideOutline(_ square: W3WSquare) {
    W3WThread.runInBackground {
      if var squares =  self.mapGridData?.squares {
        squares.removeAll(where: { s in
          return s.bounds?.id == square.bounds?.id
        })
      }

//      for anno in annotations {
//        if let a = anno as? W3WAppleMapAnnotation {
//          print(a.square?.words)
//          print(annotations.count)
//        }
//      }
      
      self.updateSquares()
    }

  }
  
  func hideOutlineMarker(_ square: W3WSquare) {
    
    W3WThread.runInBackground {
      if let s =  self.mapGridData?.markers {
        if s.count != 0 {
          self.mapGridData?.markers.removeAll(where: { m in
            return m.bounds?.id == square.bounds?.id
          })
        }//  self.mapGridData?.markers

      }
      self.updateSelectedSquare()
     // self.updateSquares()
    }

  }
  
  public func removeSelectedSquare(at square: W3WSquare?) {
    if let s = square {
      if let annotation = findAnnotation(s) {
        removeAnnotation(annotation)
        hideOutlineMarker(s)
      }
    }
  }
  
  
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

  /// remove what3words annotations from the map if they are present
  public func removeAllMarkers() {
    for annotation in annotations {
      if let w3wAnnotation = annotation as? W3WAppleMapAnnotation {
        removeAnnotation(w3wAnnotation)
        if let square = w3wAnnotation.square {
          hideOutline(square)
        }
      }
    }
  }
  
  public func getAllMarkers() -> [W3WSquare] {
    var squares = [W3WSquare]()
    
    for annotation in annotations {
      if let a = annotation as? W3WAppleMapAnnotation {
        if let square = a.square {
          squares.append(square)
        }
      }
    }
    
    return squares
  }
  
}

extension W3WAppleMapGridDrawingProtocol {
  
  /// set the map center to a coordinate, and set the minimum visible area
  func set(center: CLLocationCoordinate2D) {
    W3WThread.runOnMain {
      self.setCenter(center, animated: true)
    }
  }
  
  
  /// set the map center to a coordinate, and set the minimum visible area
  func set(center: CLLocationCoordinate2D, latitudeSpanDegrees: Double, longitudeSpanDegrees: Double) {
    W3WThread.runOnMain {
      let coordinateRegion = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latitudeSpanDegrees, longitudeDelta: longitudeSpanDegrees))
      self.setRegion(coordinateRegion, animated: true)
    }
  }
  
  
  /// set the map center to a coordinate, and set the minimum visible area
  func set(center: CLLocationCoordinate2D, latitudeSpanMeters: Double, longitudeSpanMeters: Double) {
    W3WThread.runOnMain {
      let coordinateRegion = MKCoordinateRegion(center: center, latitudinalMeters: latitudeSpanMeters, longitudinalMeters: longitudeSpanMeters)
      self.setRegion(coordinateRegion, animated: true)
    }
  }
  
  func addUniqueSquare(_ square: any W3WSquare) {
     
    if let gridData = self.mapGridData {
      
      let exists = gridData.squares.contains { existingSquare in
        return existingSquare.bounds?.id == square.bounds?.id
      }
      
      // Only add if it doesn't exist
      if !exists {
        gridData.squares.append(square)
      }
    }
  }
  
  func removeAllSquares() {
    if var gridData = self.mapGridData {
      gridData.squares.removeAll()
      gridData.markers.removeAll()
      gridData.selectedSquare = nil
      gridData.squareIsMarker = nil
      gridData.currentSquare = nil
    }
  }
}


#endif
