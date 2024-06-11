//
//  HabitListCheckInGridView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 11/2/22.
//

import SwiftUI

struct HabitListCheckInGridView: View {
    typealias DateOffset = Int
    typealias HabitDayReport = [CheckInResultType: [String?]]
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var toast: FancyToast? = nil
    @State private var habitDailyReportMap: [UUID: [DateOffset: HabitDayReport]] = [:]
    @State private var habitFirstCheckInOffsetMap: [UUID: Int] = [:]
    @State private var isFirstLoad = true

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.order, ascending: true)],
        animation: .none)
    private var habits: FetchedResults<Habit>

    let startDate: Date
    let endDate: Date
    let dateCount: Int
    let dateListSaturdayOffset: Int
    let checkInDateOptions: [Date]

    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
        self.dateCount = DateHelper.getDaysBetween(startDate: startDate, endDate: endDate) + 1
        self.dateListSaturdayOffset = Calendar.current.component(.weekday, from: startDate) % 7
        let today = Date().stripTime()
        self.checkInDateOptions = Array(0...1).map {
            Calendar.current.date(byAdding: .day, value: (-1 * $0), to: today)!
        }
    }

    var body: some View {
        VStack {
            if habits.isEmpty {
                Text("🥺")
                Text("No habits found").font(.title2)
                Text("Tap the + button above to create your first habit!").font(.footnote)
                Spacer()
            } else {
                GeometryReader { geometry in
                    ScrollViewReader { proxy in
                        ScrollView([.horizontal, .vertical]) {
                            LazyVStack(
                                alignment: .leading,
                                spacing: 0,
                                pinnedViews: [.sectionHeaders]
                            ) {
                                Section(header: checkInHeaderRow()) {
                                    ForEach(habits, id: \.self) { habit in
                                        habitRow(
                                            habit: habit,
                                            scrollWindowWidth: geometry.size.width
                                        )
                                    }
                                }
                            }
                            .frame(minHeight: geometry.size.height, alignment: .top)
                            .id("checkInGrid")
                        }
                        .coordinateSpace(name: "ScrollViewSpace")
                        .onAppear {
                            // grid should initially appear scrolled all the way to the right to show the current date
                            if isFirstLoad {
                                isFirstLoad = false
                                proxy.scrollTo("checkInGrid", anchor: .topTrailing)
                            }
                        }
                    }
                }
                .navigationDestination(for: Habit.self) { habit in
                    HabitDetailsView(habit: habit)
                }
                .onAppear {
                    buildHabitCheckInMaps()
                }
            }
        }
        .toastView(toast: $toast)
    }
}


// MARK: - Grid Shared
extension HabitListCheckInGridView {
    @ViewBuilder func rowDivider() -> some View {
        Divider()
            .frame(maxWidth: .infinity, maxHeight:1)
            .background(Color(Constants.Colors.listBorder))
    }

    func addCheckInResultToHabitDayReport(
        resultType: CheckInResultType,
        resultValue: String? = nil,
        habitDayReport: inout HabitDayReport // pass by reference
    ) {
        habitDayReport[resultType, default: []].append(resultValue)
    }

    func buildHabitCheckInMaps() {
        habitDailyReportMap = [:]
        habitFirstCheckInOffsetMap = [:]
        var habitLastCheckInOffsetMap: [UUID: Int] = [:]

        let checkIns = CheckIn.getAll(
            sortedBy: [("checkInDate", .desc)],
            forHabitUUIDs: habits.map { $0.uuid! },
            fromStartDate: startDate,
            context: viewContext
        )

        checkIns.forEach { checkIn in
            let habitUUID = checkIn.habit!.uuid!
            let checkInDate = checkIn.checkInDate!.stripTime()
            let checkInDateOffset = Calendar.current.dateComponents([.day], from: startDate, to: checkInDate).day ?? 0
            // works because we are looping in descending checkInDate order
            if checkIn.resultType != .dayOff && habitLastCheckInOffsetMap[habitUUID] == nil {
                habitLastCheckInOffsetMap[habitUUID] = checkInDateOffset
            }
            addCheckInResultToHabitDayReport(
                resultType: checkIn.resultType,
                resultValue: checkIn.resultValue,
                habitDayReport: &habitDailyReportMap[habitUUID, default: [:]][checkInDateOffset, default: [:]]
            )
        }

        habitFirstCheckInOffsetMap = CheckIn.getHabitFirstCheckInMap(context: viewContext).mapValues { firstCheckInDate in
            Calendar.current.dateComponents(
                [.day],
                from: startDate,
                to: firstCheckInDate
            ).day ?? 0
        }

        habits.forEach { habit in
            if let habitUUID = habit.uuid, let firstCheckInOffset = getHabitFirstCheckIn(habit: habit) {
                // add inactive days (after first check in) to daily report
                if habit.hasInactiveDaysOfWeek() {
                    let inactiveDaysOfWeek = Set((habit.inactiveDaysOfWeek ?? [])
                        .compactMap { $0.intValue })
                    for dateOffset in ((firstCheckInOffset + 1) ..< dateCount) {
                        let sundayOffset = (dateOffset + dateListSaturdayOffset - 1) % 7
                        if inactiveDaysOfWeek.contains(sundayOffset) {
                            addCheckInResultToHabitDayReport(
                                resultType: .dayOff,
                                habitDayReport: &habitDailyReportMap[habitUUID, default: [:]][dateOffset, default: [:]]
                            )
                        }
                    }
                }
                // add cooldown days after most recent check in to daily report
                if habit.checkInCooldownDays > 0, let lastCheckInOffset = habitLastCheckInOffsetMap[habitUUID] {
                    let firstCooldownOffset = lastCheckInOffset + 1
                    let lastCooldownOffset = min(lastCheckInOffset + 1 + Int(habit.checkInCooldownDays), dateCount)
                    for dateOffset in (firstCooldownOffset ..< lastCooldownOffset) {
                        addCheckInResultToHabitDayReport(
                            resultType: .dayOff,
                            habitDayReport: &habitDailyReportMap[habitUUID, default: [:]][dateOffset, default: [:]]
                        )
                    }
                }
            }
        }
    }

    func getHabitFirstCheckIn(habit: Habit) -> Int? {
        guard let habitUUID = habit.uuid else { return nil }
        return habitFirstCheckInOffsetMap[habitUUID]
    }

    func getHabitDayReport(habit: Habit, dateOffset: DateOffset) -> HabitDayReport {
        guard let habitUUID = habit.uuid else { return [:] }
        return habitDailyReportMap[habitUUID]?[dateOffset] ?? [:]
    }

    func getIsBeforeHabitFirstCheckIn(habit: Habit, dateOffset: DateOffset) -> Bool {
        guard let firstCheckInOffset = getHabitFirstCheckIn(habit: habit) else { return true }
        return dateOffset < firstCheckInOffset
    }

    func anyCheckInsToday(habit: Habit) -> Bool {
        return getHabitDayReport(habit: habit, dateOffset: dateCount - 1).count > 0
    }

    func getCellBgColor(forIndex index: Int) -> UIColor {
        let saturdayOffset = (index + dateListSaturdayOffset) % 7
        let isWeekend = saturdayOffset <= 1

        if isWeekend {
            return Constants.Colors.listWeekendBg
        }

        return saturdayOffset % 2 == 1 ?
            Constants.Colors.listWeekdayBg1 :
            Constants.Colors.listWeekdayBg2
    }
}


// MARK: - Grid Header
extension HabitListCheckInGridView {
    @ViewBuilder func checkInHeaderRow() -> some View {
        HStack(spacing: 0) {
            ForEach(0 ..< dateCount, id: \.self) { dateOffset in
                checkInHeaderCell(
                    date: Calendar.current.date(byAdding: .day, value: dateOffset, to: startDate)!,
                    dateOffset: dateOffset
                )
            }
            .overlay(rowDivider(), alignment: .bottom)
        }
    }

    @ViewBuilder func checkInHeaderCell(date: Date, dateOffset: DateOffset) -> some View {
        Text(getHeaderDisplayDate(date))
            .font(.system(size: 15))
            .multilineTextAlignment(.center)
            .frame(width: 50, height: 50)
            .background(Color(getCellBgColor(forIndex: dateOffset)))
    }

    private func getHeaderDisplayDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE'\n'M'/'d"
        return df.string(from: date)
    }
}


// MARK: - Grid Content
extension HabitListCheckInGridView {
    @ViewBuilder func habitRow(habit: Habit, scrollWindowWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(0 ..< dateCount, id: \.self) { dateOffset in
                habitDayContentCell(
                    habitDayReport: getHabitDayReport(habit: habit, dateOffset: dateOffset),
                    isBeforeHabitFirstCheckIn: getIsBeforeHabitFirstCheckIn(habit: habit, dateOffset: dateOffset),
                    dateOffset: dateOffset
                )
            }
        }
        .overlay(rowDivider(), alignment: .bottom)
        .overlay(
            GeometryReader { geometryInner in
                VStack {
                    habitRowTitle(habit: habit)
                        .frame(width: scrollWindowWidth)
                        .offset(x: getTitleRowOffset(
                            scrollGeo: geometryInner.frame(in: .named("ScrollViewSpace")),
                            scrollWindowWidth: scrollWindowWidth
                        ))
                }
            },
            alignment: .topTrailing
        )
    }

    @ViewBuilder func habitRowTitle(habit: Habit) -> some View {
        HStack(spacing: 0) {
            NavigationLink(value: habit) {
                Text(habit.name ?? "")
                    .font(.system(size: 15))
                    .lineLimit(2)
                    .frame(height: Constants.minTappableDimension)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 10)
            }
            .contextMenu {
                // TODO: refactor this into a cleaner place?
                ForEach(Array(checkInDateOptions.enumerated()), id: \.element) { i, date in
                    Button(action: {
                        withAnimation {
                            habit.addCheckIn(forDate: date, context: viewContext) { error in
                                if let error {
                                    toast = FancyToast.errorMessage(error.localizedDescription)
                                    return
                                }
                                buildHabitCheckInMaps()
                                toast = FancyToast(
                                    type: .success,
                                    message: "Check-in added",
                                    duration: 2,
                                    tapToDismiss: true
                                )
                            }
                        }
                    }) {
                        Label(
                            "Check in \(DateHelper.getDateString(date))",
                            systemImage: i == 0 ? "calendar" : "calendar.badge.clock"
                        )
                    }
                }
                if !anyCheckInsToday(habit: habit) {
                    Button(action: {
                        withAnimation {
                            habit.addCheckIn(
                                forDate: checkInDateOptions[0],
                                resultType: .dayOff,
                                context: viewContext
                            ) { error in
                                if let error {
                                    toast = FancyToast.errorMessage(error.localizedDescription)
                                    return
                                }
                                buildHabitCheckInMaps()
                                toast = FancyToast(
                                    type: .success,
                                    message: "Snoozed habit for today",
                                    duration: 2,
                                    tapToDismiss: true
                                )
                            }
                        }
                    }) {
                        Label(
                            "Snooze for today",
                            systemImage: "zzz"
                        )
                    }
                }
            }
            Text("🎯\n\(habit.frequencyPerWeek)x/wk")
                .font(.system(size: 13, weight: .thin))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
        .background(Color(Constants.Colors.listRowOverlayBg))
    }

    @ViewBuilder func habitDayContentCell(
        habitDayReport: HabitDayReport,
        isBeforeHabitFirstCheckIn: Bool,
        dateOffset: DateOffset
    ) -> some View {
        ZStack {
            if let checkInSuccesses = habitDayReport[.success], checkInSuccesses.count > 0 {
                Image("checkmark-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 33.5)
                    .padding(.bottom, 5)
                Text(checkInSuccesses.count > 1 ? "\(checkInSuccesses.count)" : "")
                    .foregroundColor(Color(Constants.Colors.listCheckmark))
                    .font(.system(size: 10))
                    .frame(width: 25, height: 33.5, alignment: .bottomTrailing)
                    .padding(.bottom, 5)
            } else if habitDayReport[.dayOff] != nil {
                // TODO: convert this to an asset?
                Text("💤")
                    .brightness(colorScheme == .dark ? 0.4 : 0.0)
                    .frame(width: 50, height: 44)
                    .scaledToFill()
                    .minimumScaleFactor(0.5)
                    .opacity(0.5)
            } else {
                Text("")
                    .background(alignment: .bottom) {
                        Image("disabled-diag-stripe")
                            .resizable(resizingMode: .tile)
                            .frame(width: 50, height: 44)
                            .opacity(isBeforeHabitFirstCheckIn ? 0.05 : 0)
                    }
            }
        }
        .frame(width: 50, height: 88, alignment: .bottom)
        .background(Color(getCellBgColor(forIndex: dateOffset)))
    }

    func getTitleRowOffset(scrollGeo: CGRect, scrollWindowWidth: CGFloat) -> CGFloat {
        if scrollGeo.minX > 0 { // fix leading overflow scrolling
            return 0
        }
        if scrollGeo.maxX < scrollWindowWidth { // fix trailing overflow scrolling
            return scrollGeo.width - scrollWindowWidth
        }
        return -1 * scrollGeo.minX
    }
}


struct HabitListCheckInGridView_Previews: PreviewProvider {
    static var previews: some View {
        let currentDate = Date().stripTime()
        let startDate = Calendar.current.date(
            byAdding: .day,
            value: -1 * (HabitListView.daysToDisplay - 1),
            to: currentDate
        )!
        let endDate = currentDate
        NavigationStack {
            HabitListCheckInGridView(startDate: startDate, endDate: endDate)
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
