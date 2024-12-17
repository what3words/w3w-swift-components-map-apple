//
//  File.swift
//  
//
//  Created by Dave Duprey on 17/12/2024.
//

import MapKit



public class W3WAppleMapHelper: NSObject, W3WAppleMapHelperProtocol, MKMapViewDelegate {
  
  
  init(mapView: MKMapView, w3w: What3WordsV4) {
    
  }
  

  
  // MARK: UIMapViewDelegates

  
  /// hijack this delegate call and update the grid, then pass control to the external delegate
  @available(iOS 11, *)
  public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
    //updateMap()
  }

  /// hijack this delegate call and update the grid, then pass control to the external delegate
  public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
    //updateMap()
  }
  
  
  /// hijack this delegate call and update the grid, then pass control to the external delegate
  public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    //updateMap()
  }


  /// ALLOW GRID TO BE DRAWN
  public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    //if let w3wOverlay = mapRenderer(overlay: overlay) {
    //  return w3wOverlay
    //}
    //return MKOverlayRenderer()
  }


  /// ALLOW W3W PINS TO BE DRAWN
  public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    //if let a = getMapAnnotationView(annotation: annotation) {
    //  return a
    //}
    //
    //return nil
  }

  
  public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    //if let markerView = view.annotation as? W3WAnnotation {
    //  if let square = markerView.square {
    //    onMarkerSelected(square)
    //  }
    //}
  }

}

