//
//  MapAnnotationItem.swift
//  IOS Assignment 3
//
//  Created by user256136 on 5/11/24.
//

import Foundation
import MapKit

struct MapAnnotationItem: Identifiable {
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
    var cityName: String
    var countryName: String
}
