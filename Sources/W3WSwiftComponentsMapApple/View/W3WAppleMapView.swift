//
//  W3WAppleMapView.swift
//
//
//  Created on 03/12/2024.
//

import MapKit
import W3WSwiftCore
import W3WSwiftComponentsMap
import W3WSwiftCore
import W3WSwiftApi
import W3WSwiftDesign


/// An Apple Map Kit Map
public class W3WAppleMapView: MKMapView, UIGestureRecognizerDelegate, W3WMapViewProtocol, W3WEventSubscriberProtocol {
  
  
  public var transitionScale = W3WMapScale(pointsPerMeter: CGFloat(4.0))
  
  // public var transitionScaleConversion = transitionScale.value
  
  public var subscriptions = W3WEventsSubscriptions()
  
  /// The map view model to use
  public var viewModel: W3WMapViewModelProtocol
  
  var helper: W3WAppleMapGridDrawingProtocol!
  
  typealias W3WHelper  = W3WAppleMapHelper
  
  private var w3wHelper: W3WHelper { helper as! W3WHelper }
  
  private var onError: W3WMapErrorHandler = { _ in }
  
  var zoomLevel: Double {
      let zoomScale = self.visibleMapRect.size.width / Double(self.frame.size.width)
      let zoomExponent = log2(zoomScale)
      return 20 - zoomExponent
  }
  
  // var output: W3WEvent<W3WAppMapOutputEvent>
  
 // var mapView: MKMapView?
  
  /// The available map types
  public var types: [W3WMapType] { get { return [.standard, .satellite, .hybrid] } }
  
  /// Make an Apple Map Kit Map
  /// - Parameters
  ///     - viewModel: The viewModel to use
  public init(viewModel: W3WMapViewModelProtocol) {
    
    self.viewModel = viewModel
    super.init(frame: .w3wWhatever)
    self.helper = W3WAppleMapHelper(mapView: self, viewModel.w3w) as! any W3WAppleMapGridDrawingProtocol

    configure()
  }
  
  func configure() {
    
    delegate = self
    
    set(viewModel: self.viewModel)
    
    set(type: .hybrid)
    
    bind()
    
    tesFuncs()

  }
  
  func tesFuncs() {
    
    addTestMarkers()
    attachTapRecognizer()
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
  
  public func set(type: String) {
    w3wHelper.set(type: type)
  }
  
  public func getType() -> W3WMapType {
    
    let type = w3wHelper.getType()
    switch type {
    case .standard: return "standard"
    case .satellite: return "satellite"
    case .hybrid: return "hybrid"
      
    default: return "hybridFlyover"
    }
  }
  
  public func getCameraState() -> W3WMapCamera {
    let mapView = w3wHelper.mapView
    
    return W3WMapCamera(center: mapView?.region.center, scale: W3WMapScale(span: mapView!.region.span  , mapSize: mapView!.frame.size ))
  }
  
  public func set(scheme: W3WScheme?) {
    
    w3wHelper.set(scheme: scheme)
    
    //   w3wHelper.gridData?.gridRenderer?.lineWidth = scheme?.styles?.lineThickness?.value ?? CGFloat(0.5)
    //   w3wHelper.gridData!.gridRenderer?.strokeColor = scheme?.colors?.line?.current.uiColor
    
  }
  
  public func updateSavedLists(markers: W3WMarkersLists) {
    viewModel.input.markers.send(markers)
  }
  
  func bind() {
    
    subscribe(to: self.viewModel.input.markers) { [weak self] markers in
      guard let self = self else { return }
      
      w3wHelper.updateMarkers(markers: markers)
    }
    
    subscribe(to: self.viewModel.input.camera) { [weak self] camera in
      guard let self = self else { return }
      
      w3wHelper.updateCamera(camera: camera)
    }
    
    subscribe(to: self.viewModel.input.selected) { [weak self] square in
      guard let self = self else { return }
      
      w3wHelper.updateSquare(square: square)
    }
    
    subscribe(to: self.viewModel.gps) { [weak self] gps in
      guard let self = self else { return }
    }
    
  }
  
  func addTestMarkers(){
    
    w3wHelper.addMarker(at: "intervene.cities.bachelor", color: .w3wBrandBase, type: .circle)//
    w3wHelper.addMarker(at: "outgrown.onions.marathon", color: .brown, type: .circle)//
    w3wHelper.addMarker(at: "gums.tulip.impulsive", color: .cranberry, type: .circle)//
    w3wHelper.addMarker(at: "dugouts.flaking.pleasing", color: .brightGreen, type: .circle)//
    w3wHelper.addMarker(at: "humans.stags.insulated", color: .darkGreen, type: .circle) //
    w3wHelper.addMarker(at: "melts.luggage.cuter", color: .systemPurple, type: .circle) ////
    w3wHelper.addMarker(at: "described.enforced.prude", color: .red , type: .circle)
    w3wHelper.addMarker(at: "bleaching.urgent.heartache", color: .aqua, type: .circle)//
   w3wHelper.addMarker(at: "allowable.realm.crafted", color: .lightCyan, type: .circle)//
    w3wHelper.addMarker(at: "admire.couch.celebrate", color: .aqua, type: .circle)//
    w3wHelper.addMarker(at: "listen.searching.reviews", color: .charcoal, type: .circle)//
    w3wHelper.addMarker(at: "vaulting.lasts.birthing", color: .dullRed, type: .circle)//
    w3wHelper.addMarker(at: "sleeping.beanbag.contour", color: .darkBlue , type: .circle)//
    w3wHelper.addMarker(at: "described.enforced.prude", color: .red , type: .circle)//
    w3wHelper.addMarker(at: "often.opts.blushes", color: .darkBlueAlpha60, type: .circle)//
    w3wHelper.addMarker(at: "skinny.bound.reclusive", color: .w3wSuccessLabelDark, type: .circle)//
    w3wHelper.addMarker(at: "segregate.unwraps.majors", color: .mustard, type: .circle)//
    w3wHelper.addMarker(at: "losses.pheasants.eagle", color: .systemYellow, type: .circle)
    w3wHelper.addMarker(at: "protected.nylon.will", color: .w3wErrorBase, type: .circle)//
    w3wHelper.addMarker(at: "majors.supplier.playing", color: .brown, type: .circle)//
    w3wHelper.addMarker(at: "legend.milkman.upholding", color: .blue, type: .circle)//
    w3wHelper.addMarker(at: "unsecured.slugs.unveils", color: .secondary, type: .circle)//
    w3wHelper.addMarker(at: "towers.oiled.dentures", color: .yellow, type: .circle)//
    w3wHelper.addMarker(at: "intervene.cities.bachelor", color: .purple, type: .circle)//
    w3wHelper.addMarker(at: "gladiators.surface.eyeliner", color: .purple, type: .circle)//
    w3wHelper.addMarker(at: "attaching.things.global", color: .purple, type: .circle)//
    
    w3wHelper.addMarker(at: "nipped.concluded.fabric", color: .w3wErrorBase, type: .circle)//
    w3wHelper.addMarker(at: "slept.beakers.amuses", color: .brown, type: .circle)//
    
    w3wHelper.addMarker(at: "deflation.dollar.purple", color: .darkBlue , type: .circle)//
    w3wHelper.addMarker(at: "croutons.approve.drew", color: .red , type: .circle)//
    w3wHelper.addMarker(at: "musically.storms.smirks", color: .darkBlueAlpha60, type: .circle)//
    w3wHelper.addMarker(at: "dissolves.discloses.voting", color: .w3wSuccessLabelDark, type: .circle)//
    w3wHelper.addMarker(at: "trading.yachting.wrong", color: .mustard, type: .circle)//
    
    w3wHelper.addMarker(at: "convert.universal.subject", color: .mustard, type: .circle)//
    let coordinate = CLLocationCoordinate2D(
      latitude: 10.780468,
      longitude: 106.705438
    )
    
    let span = MKCoordinateSpan(
      latitudeDelta: 0.0002,
      longitudeDelta: 0.0002
    )
    
    let region = MKCoordinateRegion(
      center: coordinate,
      span: span
    )
  //  self.setCenter(coordinate, animated: true)
  //  self.setRegion(region, animated: true)
    w3wHelper.setRegion(region, animated: true)
  }
  
  func attachTapRecognizer() {

    let mapView = w3wHelper.mapView
    
    let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
    tap.numberOfTapsRequired = 1
    tap.numberOfTouchesRequired = 1
    
    let doubleTap = UITapGestureRecognizer(target: self, action:nil)
    doubleTap.numberOfTapsRequired = 2
    mapView?.addGestureRecognizer(doubleTap)
    tap.require(toFail: doubleTap)
    

    tap.delegate = self
    
    mapView?.addGestureRecognizer(tap)
  }
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if isNotPartofTheMap(view: touch.view) {
      return false
    } else {
      return true
    }
  }
  
  
  func isNotPartofTheMap(view: UIView?) -> Bool {
    if view == nil {
      return false
    } else if view is MKAnnotationView || view is UIButton {
      return true
    } else {
      return isNotPartofTheMap(view: view?.superview)
    }
  }
  
  @objc func tapped(_ gestureRecognizer : UITapGestureRecognizer) {
    let mapView = w3wHelper.mapView
    let location = gestureRecognizer.location(in: mapView)

    if let coordinates = mapView?.convert(location, toCoordinateFrom: mapView) {
      self.w3wHelper.select(at: coordinates) { [weak self] result in
        
        guard let self = self else { return }
        
        switch result {
          
        case .success(let square):
          
          //build the list
          let markersList = W3WMarkersLists(defaultColor: .w3wBrandBase)
          markersList.add(listName: "favorites", color: .w3wBrandBase)
          markersList.add(square: square, listName: "favorites")
         // self.viewModel.mapState.markers.send(markersList)
          
       //   self.viewModel.mapState.selected.send(square)
          self.viewModel.output.send(.selected(square))
        case .failure(let error):
           print("Show Error")

        default: break
          
        }
        
      }
      
    }
  }

}

extension W3WAppleMapView: MKMapViewDelegate {
  
  // MARK: UIMapViewDelegates
  public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
    let currentMapScale = W3WMapScale(span: mapView.region.span, mapSize: mapView.frame.size)

    if currentMapScale.value > transitionScale.value {
      //update map
    }
    w3wHelper.mapViewDidChangeVisibleRegion(mapView)
    viewModel.output.send(.camera(getCameraState()))

  }

  public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
 
    if let w3wOverlay = w3wHelper.mapRenderer(overlay: overlay) {
      return w3wOverlay
    }
    return MKOverlayRenderer()
    
  }
  
  /// delegate callback to provide a cusomt annotation view
  public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    return w3wHelper.mapView(mapView, viewFor: annotation, with: self.transitionScale.value)
  }
  
  public func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer]) {
    w3wHelper.mapView(mapView, didAdd: renderers)
  }
  
  public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
    w3wHelper.mapView(mapView, didAdd: views)
  }
  
  public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
    w3wHelper.mapView(mapView, regionWillChangeAnimated: animated)
  }
  
  public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {

    //test for zoomslevel
    let mapRect = mapView.visibleMapRect
    let mapWidthInPoints = mapView.frame.size.width
    let zoomScale = mapRect.size.width / Double(mapWidthInPoints)
    
    
    w3wHelper.mapView(mapView, regionDidChangeAnimated: animated)
    
  }
  
  public func mapView(_ mapView: MKMapView, mapTypeChanged type: MKMapType) {
    
  }
  
  //when marker is being selected
  public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    if let markerView =  view.annotation as? W3WAppleMapAnnotation {
      
    }

    w3wHelper.mapView(mapView, didSelect: view)
  }
  
}

extension W3WAppleMapView {

}

