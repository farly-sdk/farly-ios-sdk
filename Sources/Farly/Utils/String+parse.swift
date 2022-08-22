//
//  String+parse.swift
//  Farly
//
//  Created by Philippe Auriach on 31/01/2022.
//

import Foundation

extension String {
    var asOfferDate: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return dateFormatter.date(from: self)
    }
    
    var asInt: Int? {
        return Int(self)
    }
    
    var asDouble: Double? {
        return Double(self)
    }
}
