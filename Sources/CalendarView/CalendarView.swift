import SwiftUI


public struct CalendarView<DateView: View, Annotation: View>: View {
    static var calendarColumns: [GridItem] { .init(repeating: GridItem(), count: 7) }
    @Environment(\.calendar) private var calendar
    
    @StateObject private var proxy = CalendarProxy()
    
    private let interval: Range<Date>
    private let spacing: CGFloat
    
    @ViewBuilder private let content: (Date) -> DateView
    @ViewBuilder private var annotation: () -> Annotation

    init(interval: Range<Date>, spacing: CGFloat = 20, @ViewBuilder content: @escaping (Date) -> DateView) where Annotation == EmptyView {
        self.spacing = spacing
        self.interval = interval
        self.content = content
        self.annotation = EmptyView.init
    }
    
    private init(interval: Range<Date>, spacing: CGFloat = 20, @ViewBuilder content: @escaping (Date) -> DateView, @ViewBuilder annotation: @escaping () -> Annotation) {
        self.spacing = spacing
        self.interval = interval
        self.content = content
        self.annotation = annotation
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            ZStack {
                annotation()
                LazyVGrid(columns: Self.calendarColumns, spacing: spacing) {
                    ForEach(months, id: \.self) { month in
                        header(for: month)
                        ForEach(days(for: month), id: \.self) { date in
                            dayView(date: date, month: month)
                        }
                    }
                }
            }
            .coordinateSpace(name: "calendar")
            .environmentObject(proxy)
            .onPreferenceChange(DateGeometryKey.self) { newValue in
                self.proxy.geometries = newValue
            }
        }
        .overlay(alignment: .top, content: weekdayHeader)
    }
    
    @ViewBuilder
    public func annotate<Content: View>(@ViewBuilder _ annotation: @escaping () -> Content) -> some View {
        CalendarView<DateView, Content>(interval: interval, spacing: spacing, content: content, annotation: annotation)
    }

    @ViewBuilder
    private func dayView(date: Date, month: Date) -> some View {
        if calendar.isDate(date, equalTo: month, toGranularity: .month) {
            content(date)
                .id(date)
                .foregroundColor(
                    calendar.isDateInToday(date) ? .accentColor : calendar.isDateInWeekend(date) ? .secondary : nil
                )
                .modifier(DateGometryObserver(date: date))
        } else {
            content(date).hidden()
        }
    }
    
    @ViewBuilder
    private func weekdayHeader() -> some View {
        LazyVGrid(columns: Self.calendarColumns) {
            ForEach(getDatesInWeek(), id: \.self) { date in
                Text(date, format: .dateTime.weekday(.narrow))
                    .fontWeight(.bold)
            }
        }
        .foregroundColor(.secondary)
        .frame(height: 32)
        .background(.ultraThinMaterial)
    }

    private func getDatesInWeek(date: Date = .now) -> [Date] {
        calendar.generateDates(
            inside: calendar.dateInterval(of: .weekOfMonth, for: .now)!,
            matching: DateComponents(hour: 0)
        )
    }
    
    private var months: [Date] {
        calendar.generateDates(
            inside: interval,
            matching: DateComponents(day: 1)
        )
    }

    private func header(for month: Date) -> some View {
        let isCurrentMonth = calendar.isDate(month, equalTo: Date(), toGranularity: .month)
        guard
        let monthInterval = calendar.dateInterval(of: .month, for: month),
        let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            fatalError("Date error")
        }
        let firstWeekDays = calendar.generateDates(inside: monthFirstWeek)
        let identifiableSequence: [(String, Date)] = firstWeekDays.map { date in
            (String(describing: month) + String(describing: date), date)
        }
        
        return ForEach(identifiableSequence, id: \.0) { id, date in
                Text(month, format: .dateTime.month())
                    .font(.body.weight(.medium))
                    .foregroundColor(isCurrentMonth ? .accentColor : nil)
                    .opacity(calendar.component(.day, from: date) != 1 ? 0 : 1)
            }
    }

    
    private func days(for month: Date) -> [Date] {
        guard
            let monthInterval  = calendar.dateInterval(of: .month, for: month),
            let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
            let monthLastWeek  = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end)
        else { return [] }
        return calendar.generateDates(
            inside: DateInterval(start: monthFirstWeek.start,
                                 end: monthLastWeek.end))
    }
}
