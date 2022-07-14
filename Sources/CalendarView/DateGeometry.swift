//
//  DateGeometry.swift
//  
//
//  Created by Zac Cranko on 14/7/2022.
//

import SwiftUI

struct DateGeometryKey: PreferenceKey {
    static var defaultValue: [Date: CGRect] = [:]
    static func reduce(value dictionary: inout [Date: CGRect], nextValue: () -> [Date: CGRect]) {
        for (key, value) in nextValue() {
            dictionary[key] = value
        }
    }
}

struct DateGometryObserver: ViewModifier {
    var date: Date
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: DateGeometryKey.self,
                                   value: [date: geometry.frame(in: .named("calendar"))])
        }
    }
    func body(content: Content) -> some View {
        content.background(sizeView)
    }
}

class CalendarProxy: ObservableObject {
    @Published var geometries: [Date: CGRect] = [:]
    
    func frame( _ date: Date, in: Calendar) -> CGRect? {
        guard let date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date)
            else { return nil }
        return geometries[date]
    }
}
