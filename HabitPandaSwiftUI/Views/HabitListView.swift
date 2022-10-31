//
//  HabitListView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/7/22.
//

import SwiftUI

struct HabitListView: View {
    typealias CheckInGridOffsetMap = [Int: Int]
    @Environment(\.managedObjectContext) private var viewContext
    static let numDates = 30

    @State private var isAddHabitViewPresented = false
    @State private var isReorderHabitsViewPresented = false
    @State private var habitCheckInGridOffsetMap: [UUID: CheckInGridOffsetMap] = [:]
    @State private var habitCreatedAtOffsetMap: [UUID: Int] = [:]
    @State private var habitFirstCheckInOffsetMap: [UUID: Int?] = [:]
    @State private var currentDate = Date().stripTime()
    @State private var startDate = Calendar.current.date(
        byAdding: .day,
        value: -1 * (HabitListView.numDates - 1),
        to: Date().stripTime()
    )!
    @State private var dateListSaturdayOffset = 0
    @State private var scrollViewContentOffset = CGFloat(0)

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.order, ascending: true)],
        animation: .none)
    private var habits: FetchedResults<Habit>

    var body: some View {
        VStack {
            if habits.isEmpty {
                Text("🥺")
                Text("No habits found").font(.title2)
                Text("Tap the + button above to create your first habit!").font(.footnote)
                Spacer()
            } else {
                checkInGrid()
                    .navigationDestination(for: Habit.self) { habit in
                        HabitDetailsView(habit: habit)
                    }
            }
        }
        .onAppear {
            // TODO: unnecessary?
            reloadData()
        }
        .onChange(of: currentDate) { _ in
            reloadData()
        }
        .toolbar {
            #if DEBUG
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                }) {
                    NavigationLink(destination: AdminView()) {
                        Text("Admin")
                            .frame(minWidth: Constants.minTappableDimension)
                            .frame(height: Constants.minTappableDimension)
                    }
                }
            }
            #endif

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    isReorderHabitsViewPresented.toggle()
                }) {
                    Label("Reorder Habits", systemImage: "arrow.up.arrow.down")
                }
                .frame(minWidth: Constants.minTappableDimension)
                .frame(height: Constants.minTappableDimension)
                Button(action: {
                    isAddHabitViewPresented.toggle()
                }) {
                    Label("Add Habit", systemImage: "plus")
                }
                .frame(minWidth: Constants.minTappableDimension)
                .frame(height: Constants.minTappableDimension)
            }
        }
        .navigationTitle("HabitPanda 🐼")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isAddHabitViewPresented) {
            AddEditHabitView()
        }
        .fullScreenCover(isPresented: $isReorderHabitsViewPresented) {
            ReorderHabitsView()
        }
    }
}


// MARK: - Load Data Methods
extension HabitListView {
    func reloadData() {
        print("reloadData()")
        if currentDate != Date().stripTime() {
            // only update when changed
            currentDate = Date().stripTime()
        }
        startDate = Calendar.current.date(
            byAdding: .day,
            value: -1 * (HabitListView.numDates - 1),
            to: currentDate
        )!
        dateListSaturdayOffset = Calendar.current.component(.weekday, from: startDate) % 7

        buildHabitCheckInMaps()
        habits.forEach { (habit) in
            habitCreatedAtOffsetMap[habit.uuid!] =
                (Calendar.current.dateComponents(
                    [.day],
                    from: startDate,
                    to: habit.createdAt!
                ).day ?? 0) - 1

            if let firstCheckInDate = habit.getFirstCheckInDate() {
                habitFirstCheckInOffsetMap[habit.uuid!] =
                    (Calendar.current.dateComponents(
                        [.day],
                        from: startDate,
                        to: firstCheckInDate
                    ).day ?? 0) - 1
            } else {
                habitFirstCheckInOffsetMap[habit.uuid!] = nil
            }
        }
    }
}


// MARK: - Check-In Grid Helper Methods
extension HabitListView {
    func buildHabitCheckInMaps() {
        habitCheckInGridOffsetMap = [:]

        let checkIns = CheckIn.getAll(
            forHabitUUIDs: habits.map { $0.uuid! },
            fromStartDate: startDate,
            context: viewContext
        )

        checkIns.forEach { (checkIn) in
            let habitUUID = checkIn.habit!.uuid!
            let date = checkIn.checkInDate!.stripTime()
            let dateOffset = Calendar.current.dateComponents(
                [.day],
                from: startDate,
                to: date
            ).day ?? 0

            habitCheckInGridOffsetMap[habitUUID] =
                habitCheckInGridOffsetMap[habitUUID] ?? [:]
            habitCheckInGridOffsetMap[habitUUID]![dateOffset] =
                (habitCheckInGridOffsetMap[habitUUID]![dateOffset] ?? 0) + 1
        }
    }

    func getCheckInCount(forHabit habit: Habit, forDateOffset dateOffset: Int) -> Int {
        let uuid = habit.uuid!
        guard (habitFirstCheckInOffsetMap[uuid] ?? 0) ?? 0 < dateOffset else {
            return 0
        }
        return habitCheckInGridOffsetMap[uuid]?[dateOffset] ?? 0
    }

    func getCreatedAtOffset(forHabit habit: Habit) -> Int {
        let uuid = habit.uuid!
        return habitCreatedAtOffsetMap[uuid]!
    }

    func getFirstCheckInOffset(forHabit habit: Habit) -> Int {
        let uuid = habit.uuid!
        // if no check ins, represent today's offset
        return (habitFirstCheckInOffsetMap[uuid] ?? nil) ?? (HabitListView.numDates - 2)
    }
}


// MARK: - Check-In Grid Views
extension HabitListView {
    @ViewBuilder func checkInGrid() -> some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical]) {
                    //                ScrollView(.vertical) {
                    ZStack(alignment: .topLeading) {
                        LazyVGrid(
                            columns: [GridItem(.flexible())],
                            spacing: 0,
                            pinnedViews: [.sectionHeaders]
                        ) {
                            Section(header: checkInHeaderRow()) {
                                ForEach(Array(habits.enumerated()), id: \.element) { i, habit in
                                    LazyVGrid(
                                        columns: Array(repeating: GridItem(.fixed(50), spacing: 0, alignment: .center), count: HabitListView.numDates),
                                        spacing: 0
                                    ) {
                                        ForEach(0 ..< HabitListView.numDates, id: \.self) { dateOffset in
                                            checkInContentCell(
                                                checkInCount: getCheckInCount(forHabit: habit, forDateOffset: dateOffset)
                                            )
                                            .id("checkInContentCell-\(i)-\(dateOffset)")
                                            .frame(width: 50, height: 88, alignment: .bottom)
                                            .background(Color(getCellBgColor(forIndex: dateOffset)))
                                        }
                                    }
                                    .overlay(
                                        Divider()
                                            .frame(maxWidth: .infinity, maxHeight:1)
                                            .background(Color(Constants.Colors.listBorder)),
                                        alignment: .bottom
                                    )
                                    .overlay(
                                        GeometryReader { geometryInner in
                                            VStack {
                                                checkInGridRowTitleCell(habit: habit)
                                                    .id("checkInGridRowTitleCell-\(i)")
                                                    .frame(width: geometry.size.width)
                                                    .offset(x: getTitleRowOffset(
                                                        scrollGeo: geometryInner.frame(in: .named("ScrollViewSpace")),
                                                        scrollWindowWidth: geometry.size.width
                                                    ))
                                            }
                                        },
                                        alignment: .topTrailing
                                    )
                                }
                            }
                        }
                        .frame(minHeight: geometry.size.height, alignment: .top)
                    }
                    .id("checkInGrid")
                }
                .coordinateSpace(name: "ScrollViewSpace")
                .onAppear {
                    // grid should initially appear scrolled all the way to the right to show the current date
                    // TODO: move somewhere else?
                    proxy.scrollTo("checkInGrid", anchor: .topTrailing)
                }
            }
        }
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

    @ViewBuilder func checkInGridRowTitleCell(habit: Habit) -> some View {
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
            Text("🎯\n\(habit.frequencyPerWeek)x/wk")
                .font(.system(size: 13, weight: .thin))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
        .background(Color(Constants.Colors.listRowOverlayBg))
    }

    @ViewBuilder func checkInHeaderRow() -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(50), spacing: 0, alignment: .center), count: HabitListView.numDates),
            spacing: 0
        ) {
            ForEach(0 ..< HabitListView.numDates, id: \.self) {
                checkInHeaderCell(
                    date:
                        Calendar.current.date(byAdding: .day, value: (-1 * HabitListView.numDates) + $0 + 1, to: Date().stripTime())!
                )
                .frame(width: 50, height: 50)
                .background(Color(getCellBgColor(forIndex: $0)))
            }
            .overlay(
                Divider()
                    .frame(maxWidth: .infinity, maxHeight:1)
                    .background(Color(Constants.Colors.listBorder)),
                alignment: .bottom
            )
        }
    }

    @ViewBuilder func checkInHeaderCell(date: Date) -> some View {
        Text(getHeaderDisplayDate(date))
            .font(.system(size: 15))
            .multilineTextAlignment(.center)
    }

    @ViewBuilder func checkInContentCell(checkInCount: Int) -> some View {
        if checkInCount > 0 {
            ZStack {
                Image("checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 33.5)
                    .padding(.bottom, 5)
                Text(checkInCount > 1 ? "\(checkInCount)" : "")
                    .foregroundColor(Color(Constants.Colors.listCheckmark))
                    .font(.system(size: 10))
                    .frame(width: 25, height: 33.5, alignment: .bottomTrailing)
                    .padding(.bottom, 5)
            }
        } else {
            Text("")
        }
    }

    private func getHeaderDisplayDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE'\n'M'/'d"
        return df.string(from: date)
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


struct HabitListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HabitListView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
