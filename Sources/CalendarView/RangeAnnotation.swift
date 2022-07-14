//
//  RangeAnnotation.swift
//  CalendarView
//
//  Created by Zac Cranko on 14/7/2022.
//

import SwiftUI

public struct CalendarAnnotation: View {
    @Environment(\.calendar) var calendar
    
    private var title: String?
    private var calledInterval: ClosedRange<Date>
    private var interval: ClosedRange<Date> {
        calendar.startOfDay(for: calledInterval.lowerBound)...calendar.startOfDay(for: calledInterval.upperBound)
    }
    
    private let spacing: CGFloat
    @EnvironmentObject private var proxy: CalendarProxy
    
    public init(_ title: String? = nil, interval: ClosedRange<Date>, spacing: CGFloat = 5) {
        self.title = title
        self.calledInterval = interval
        self.spacing = spacing
    }
    
    public init(_ title: String? = nil, date: Date, spacing: CGFloat = 5) {
        self.title = title
        self.calledInterval = date...date
        self.spacing = spacing
    }
    
    public var body: some View {
        ForEach(Array(weekIntervals.enumerated()), id: \.offset) { offset, interval in
            formatAcrossDates(interval: interval, spacing: 5) {
                Capsule()
                    .overlay(alignment: .topLeading) {
                        if offset == 0 || calendar.date(interval.lowerBound, matchesComponents: .init(day: 1)), let title = title  {
                            Text(offset == 0  ? title : "(\(title))")
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .padding(.bottom)
                                .offset(x: 5, y: -15)
                        }
                    }
                
            }
        }
    }

    var weekIntervals: [ClosedRange<Date>] {
        var days: [Date] = []
        calendar.enumerateDates(startingAfter: interval.lowerBound,
                                matching: DateComponents(hour: 0),
                                matchingPolicy: .nextTime) { date, match, stop in
            if let date = date {
                if date < interval.upperBound {
                    days.append(date)
                } else { stop = true }
            }
        }
        days.append(interval.upperBound)

        guard var previous: Date  = days.first else { return [] }
        var first: Date = interval.lowerBound
        
        var intervals: [ClosedRange<Date>] = days.reduce(into: []) { partialResult, date in
            let isFirstWeekDay = calendar.date(date, matchesComponents: .init(weekday: calendar.firstWeekday))
            let isFirstOfMonth = calendar.date(date, matchesComponents: .init(day: 1))
            
            if isFirstWeekDay || isFirstOfMonth { // break week
                partialResult.append(first...previous)
                first = date
            }
            previous = date
        }
        intervals.append(first...interval.upperBound)
        
        return intervals
    }
    

    @ViewBuilder
    func formatAcrossDates<Content: View>(interval: ClosedRange<Date>,
                                          spacing: CGFloat,
                                          @ViewBuilder content someContent: () -> Content) -> some View {
        if let startRect = proxy.frame(interval.lowerBound, in: calendar), let endRect = proxy.frame(interval.upperBound, in: calendar) {
            let rect = startRect.union(endRect)
            someContent()
                .frame(width: rect.width + spacing, height: rect.height + spacing)
                .position(x: rect.midX, y: rect.midY)
        }
    }
}

struct Previews_CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(interval: Calendar.current.date(byAdding: .month, value: -1, to: .now)!..<Calendar.current.date(byAdding: .month, value: 2, to: .now)!) { date in
            Text(date.formatted(.dateTime.day()))
                .frame(width: 30, height: 30)
                .padding(4)
                .overlay {
                    Circle()
                        .fill(.clear)
                        .opacity(0.1)
                }
                
        }
        .annotate {
            let calendar = Calendar.current
            CalendarAnnotation("Some Range",
                                    interval: calendar.date(byAdding: .day, value: -16, to: .now)!...calendar.date(byAdding: .day, value: -13, to: .now)!)
                .foregroundColor(Color.accentColor.opacity(0.1))
            
            CalendarAnnotation("Single Day Range", interval: Date.now...Date.now)
                .foregroundColor(Color.accentColor.opacity(0.1))
        }
    }
}
