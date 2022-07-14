//
//  Calendar.swift
//  CalendarView
//
//  Created by Zac Cranko on 14/7/2022.
//

import Foundation

extension Calendar {
    func generateDates(inside interval: DateInterval,
                       matching components: DateComponents = .init(hour: 0, minute: 0, second: 0)) -> [Date] {
        return generateDates(inside: interval.start..<interval.end, matching: components)
    }
    func generateDates(inside interval: Range<Date>,
                       matching components: DateComponents = .init(hour: 0, minute: 0, second: 0)) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.lowerBound)

        enumerateDates(startingAfter: interval.lowerBound,
                       matching: components,
                       matchingPolicy: .nextTime) { date, _, stop in
            guard let date = date else { return }
            guard date < interval.upperBound else {
                stop = true
                return
            }
            dates.append(date)
        }

        return dates
    }
}
