//
//  W3WAppleMapHelperProtocol.swift
//  w3w-swift-components-map-apple
//
//  Created by Henry Ng on 17/12/24.
//
import Foundation
import CoreLocation
import W3WSwiftCore
import W3WSwiftThemes
import W3WSwiftComponentsMap

public protocol W3WAppleMapHelperProtocol {
  
  // put a what3words annotation on the map showing the address
  func addMarker(at square: W3WSquare?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion)
  
   func addMarker(at suggestion: W3WSuggestion?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion)
   func addMarker(at words: String?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion)
   func addMarker(at coordinate: CLLocationCoordinate2D?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion)
   func addMarker(at squares: [W3WSquare]?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion)
   func addMarker(at suggestions: [W3WSuggestion]?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion)
   func addMarker(at words: [String]?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion)
   func addMarker(at coordinates: [CLLocationCoordinate2D]?, color: W3WColor?, type: W3WMarkerType, completion: @escaping MarkerCompletion)
   
   // remove what3words annotations from the map if they are present
   func removeMarker(at suggestion: W3WSuggestion?)
   func removeMarker(at words: String?)
   func removeMarker(at squares: [W3WSquare]?)
   func removeMarker(at suggestions: [W3WSuggestion]?)
   func removeMarker(at words: [String]?)
   func removeMarker(at square: W3WSquare?)
   func removeMarker(group: String)

   // show the "selected" outline around a square
  func select(at: W3WSquare)

   // remove the selection from the selected square
   func unselect()
   
   // show the "hover" outline around a square
   func hover(at: CLLocationCoordinate2D)
   
   // hide the "hover" outline around a square
   func unhover()
   
   // get the list of added squares
   func getAllMarkers() -> [W3WSquare]
   
   // remove what3words annotations from the map if they are present
   func removeAllMarkers()
   
   // find a marker by it's coordinates and return it if it exists in the map
   func findMarker(by coordinates: CLLocationCoordinate2D) -> W3WSquare?
  
  // sets the size of a square after .zoom is used in a show() call
  func set(zoomInPointsPerSquare: CGFloat)

}
