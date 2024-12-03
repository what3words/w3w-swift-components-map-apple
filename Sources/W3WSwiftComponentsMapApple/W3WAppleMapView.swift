//
//  W3WAppleMapView.swift
//
//
//  Created on 03/12/2024.
//

import MapKit
import W3WSwiftCore
import W3WSwiftComponentsMap


/// An Apple Map Kit Map
public class W3WAppleMapView: MKMapView, W3WMapViewProtocol, W3WEventSubscriberProtocol, MKMapViewDelegate {
  public var subscriptions = W3WEventsSubscriptions()

  /// The map view model to use
  public var viewModel: W3WMapViewModelProtocol
  
  /// The available map types
  public var types: [W3WMapType] { get { return [.standard, .satellite, .hybrid, "silly"] } }
  

  /// Make an Apple Map Kit Map
  /// - Parameters
  ///     - viewModel: The viewModel to use
  public init(viewModel: W3WMapViewModelProtocol) {
    self.viewModel = viewModel
    super.init(frame: .w3wWhatever)
  }
  
  
  /// Make an Apple Map Kit Map
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  /// Change the viewModel for this map. Typically used when
  /// switching maps in the map view
  /// - Parameters
  ///     - viewModel: The viewModel to use
  public func set(viewModel: W3WMapViewModelProtocol) {
    self.viewModel = viewModel
  }


  /// Change the map type, there is a convenince function in W3WMapViewProtocol
  /// that accepts a W3WMapType, and calls this.  Common map types are defined
  /// there
  /// - Parameters
  ///     - type: A string type from the array `self.types`
  public func set(type: String) {
  }
  
}
