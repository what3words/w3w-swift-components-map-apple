//
//  W3WMapError.swift
//  w3w-swift-components-map
//
//  Created by Henry Ng on 2/1/25.
//


import W3WSwiftCore

/// error response code block definition
public typealias W3WMapErrorHandler = (W3WError) -> ()

public typealias MarkerCompletion = (W3WSquare?, W3WError?) -> ()
