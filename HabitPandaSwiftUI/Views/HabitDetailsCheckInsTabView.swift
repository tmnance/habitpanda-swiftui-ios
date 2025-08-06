//
//  HabitDetailsCheckInsTabView.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/11/22.
//

import SwiftUI

struct HabitDetailsCheckInsTabView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var habit: Habit
    @FetchRequest var checkIns: FetchedResults<CheckIn>

    @State private var toast: FancyToast? = nil
    @State private var showActionSheet = false
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    @State private var includeSelectedDate = false


    init(habit: Habit) {
        self.habit = habit
        _checkIns = FetchRequest(
            entity: CheckIn.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \CheckIn.checkInDate, ascending: false),
                NSSortDescriptor(keyPath: \CheckIn.createdAt, ascending: false),
            ],
            predicate: NSPredicate(format: "habit == %@", habit)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if checkIns.isEmpty {
                Text("No check-ins yet").font(.title3)
                    .padding()
            } else {
                List {
                    ForEach(checkIns) { checkIn in
                        VStack(alignment: .leading) {
                            Text(getTitleText(checkIn: checkIn))
                                .font(.system(size: 17))
                            Text(getSubTitleText(checkIn: checkIn))
                                .foregroundColor(Color(Constants.Colors.subText))
                                .font(.system(size: 13))
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete(perform: delete(offsets:))
                }
                .listStyle(.plain)
                .padding(8)

                Button(action: {
                    showActionSheet = true
                }) {
                    Text("Bulk Delete Check-Ins")
                        .font(.system(size: 15))
                        .foregroundColor(Color(Constants.Colors.deleteButtonText))
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .frame(height: Constants.comfortableTappableDimension)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(Constants.Colors.deleteButtonBorder), lineWidth: 1)
                        )
                }
                .padding()//.horizontal, 16)
                .actionSheet(isPresented: $showActionSheet) {
                    ActionSheet(
                        title: Text("Select Bulk Delete Action"),
                        buttons: [
                            .destructive(Text("Delete All (\(habit.getCheckInCount(context: viewContext)))")) {
                                deleteAllCheckIns()
                            },
                            .default(Text("Delete Through Date")) {
                                selectedDate = Date().stripTime()
                                includeSelectedDate = false
                                showDatePicker = true
                            },
                            .cancel()
                        ]
                    )
                }
            }
        }
        .toastView(toast: $toast)
        .sheet(isPresented: $showDatePicker) {
            VStack(spacing: 0) {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: ...Date(), // Limit to today and earlier
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding(.horizontal)

                Toggle(isOn: $includeSelectedDate) {
                    Text(getIncludeCheckInsFromSelectedDateText())
                }
                .disabled(!hasCheckInsOnSelectedDate())
                .padding()

                Text(getCheckInsDeletedThroughDateText())
                    .italic()

                HStack {
                    Button(action: {
                        showDatePicker = false
                    }) {
                        Text("Cancel")
                            .font(.system(size: 15))
                            .foregroundColor(Color(Constants.Colors.checkInButtonText))
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .frame(height: Constants.comfortableTappableDimension)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(Constants.Colors.checkInButtonBorder), lineWidth: 1)
                            )
                    }

                    Spacer()

                    Button(action: {
                        deleteCheckIns(throughDate: selectedDate, includeDate: includeSelectedDate)
                        showDatePicker = false
                    }) {
                        Text("Confirm")
                            .font(.system(size: 15))
                            .foregroundColor(Color(Constants.Colors.deleteButtonText))
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .frame(height: Constants.comfortableTappableDimension)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(Constants.Colors.deleteButtonBorder), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical)
            }
        }
    }

    private func getTitleText(checkIn: CheckIn) -> String {
        return DateHelper.getDateString(checkIn.checkInDate!) + " — " +
        checkIn.type.descriptionWithCheckInValue(checkIn.value)
    }

    private func getSubTitleText(checkIn: CheckIn) -> String {
        guard let createdAt = checkIn.createdAt else { return "" }
        var subTitleText = createdAt.formatted(.dateTime.hour().minute())
        if checkIn.wasAddedForPriorDate() {
            let dayOffset = checkIn.getAddedVsCheckInDateDayOffset()
            subTitleText = "*\(subTitleText) (added \(dayOffset) day\(dayOffset == 1 ? "" : "s") later)"
        }
        return subTitleText
    }

    private func getIncludeCheckInsFromSelectedDateText() -> String {
        let checkInCount = habit.getCheckInsForDate(
            selectedDate.stripTime(),
            context: viewContext
        ).count
        return "Also delete the \(checkInCount) check-in\(checkInCount == 1 ? "" : "s") from this date?"
    }

    private func hasCheckInsOnSelectedDate() -> Bool {
        return habit.getCheckInsForDate(
            selectedDate.stripTime(),
            context: viewContext
        ).count > 0
    }

    private func getCheckInsDeletedThroughDateText() -> String {
        let throughDate: Date = !includeSelectedDate ?
            Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)! :
            selectedDate
        let checkInCount = habit.getCheckInCount(
            throughDate: throughDate,
            context: viewContext
        )
        return "\(checkInCount) check-in\(checkInCount == 1 ? "" : "s") will be deleted"
    }

    private func delete(offsets: IndexSet) {
        withAnimation {
            offsets.forEach { offset in
                let checkIn = checkIns[offset]
                do {
                    try PersistenceController.delete(checkIn, context: viewContext)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

    private func deleteAllCheckIns() {
        deleteCheckIns(throughDate: Date().stripTime(), includeDate: true)
    }

    private func deleteCheckIns(throughDate: Date, includeDate: Bool) {
        let adjustedThroughDate: Date = !includeDate ?
            Calendar.current.date(byAdding: .day, value: -1, to: throughDate)! :
            throughDate
        deleteCheckIns(throughDate: adjustedThroughDate)
    }

    private func deleteCheckIns(throughDate: Date) {
        let checkInCount = habit.getCheckInCount(
            throughDate: throughDate,
            context: viewContext
        )
        habit.removeCheckIns(
            throughDate: throughDate,
            context: viewContext
        ) { error in
            if let error {
                toast = FancyToast.errorMessage(error.localizedDescription)
                return
            }
            toast = FancyToast(
                type: .success,
                message: "\(checkInCount) check-in\(checkInCount == 1 ? "" : "s") deleted",
                duration: 2,
                tapToDismiss: true
            )
        }
    }
}

struct HabitCheckInsTabView_Previews: PreviewProvider {
    static var previews: some View {
        HabitDetailsCheckInsTabView(habit: Habit.example)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
