import SwiftUI
import Foundation

// MARK: - Custom Shape for Specific Corner Radius
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Extension to View for convenience
//extension View {
//    func clipShapeWithRoundedCorners(_ radius: CGFloat, corners: UIRectCorner) -> some View {
//        clipShape(RoundedCorner(radius: radius, corners: corners))
//    }
//}

// MARK: - Reminder Struct (Updated for Medicine Type and Detailed Completion Tracking)
struct Reminder: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var type: ReminderType
    var times: [Date]
    var startDate: Date
    var endDate: Date
    var active: Bool
    var nextDue: Date
    // New: To track completion status for each specific time slot for the current day
    var completedTimes: [Date] // Stores the exact Date (time + current day) when a slot was completed
    var lastModifiedDate: Date
    // New: To track the last time completedTimes were reset (for daily reset logic)
    var lastResetDate: Date?


    var iconName: String {
        switch type {
        case .checkup: return "stethoscope"
        case .medicine: return "pill.fill" // Icon for medicine
        }
    }

    enum ReminderType: String, CaseIterable, Identifiable, Codable {
        case checkup
        case medicine // Re-introduced medicine type

        var id: String { self.rawValue }
        var displayName: String {
            switch self {
            case .checkup: return "Health Checkup"
            case .medicine: return "Medicine Intake"
            }
        }
    }

    // New: Check if a specific time slot for today is completed
    func isTimeSlotCompleted(time: Date) -> Bool {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        // Normalize the completedTimes to only compare hour and minute for the current day
        return completedTimes.contains { completedDate in
            let completedComponents = calendar.dateComponents([.hour, .minute], from: completedDate)
            return completedComponents.hour == timeComponents.hour &&
                   completedComponents.minute == timeComponents.minute &&
                   calendar.isDate(completedDate, inSameDayAs: Date()) // Must be completed TODAY
        }
    }
    
    // New: Check if a specific time slot for today is overdue
    func isTimeSlotOverdue(time: Date) -> Bool {
        guard active && !hasPeriodEnded && !isFutureReminder else { return false } // Reminder must be active and valid
        
        let calendar = Calendar.current
        let now = Date()
        
        // Create a date for the specific time slot on today's date
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        guard let scheduledTimeToday = calendar.date(bySettingHour: timeComponents.hour!, minute: timeComponents.minute!, second: 0, of: now) else { return false }
        
        // A time slot is overdue if it has passed and it's not marked as completed for today
        return scheduledTimeToday < now && !isTimeSlotCompleted(time: time)
    }

    // Helper to determine if the *entire reminder* is overdue (any active time slot is overdue)
    var isOverdue: Bool {
        guard active && !hasPeriodEnded && !isFutureReminder else { return false }
        return times.contains(where: { isTimeSlotOverdue(time: $0) })
    }
    
    // Helper to determine if the *entire reminder* is completed (all active time slots are completed for today)
    var isCompletedForAllTimesToday: Bool {
        guard active && !times.isEmpty else { return false }
        // A reminder is "completed for today" if all its scheduled times for today are in completedTimes
        return times.allSatisfy { time in
            isTimeSlotCompleted(time: time)
        }
    }

    var hasPeriodEnded: Bool {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let normalizedEndDate = calendar.startOfDay(for: endDate)
        return normalizedEndDate < startOfToday
    }

    var isFutureReminder: Bool {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        return normalizedStartDate > startOfToday
    }

    static func == (lhs: Reminder, rhs: Reminder) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.type == rhs.type &&
        lhs.times == rhs.times &&
        lhs.startDate == rhs.startDate &&
        lhs.endDate == rhs.endDate &&
        lhs.active == rhs.active &&
        lhs.nextDue == rhs.nextDue &&
        lhs.completedTimes == rhs.completedTimes && // Compare completedTimes
        lhs.lastModifiedDate == rhs.lastModifiedDate &&
        lhs.lastResetDate == rhs.lastResetDate
    }

    init(id: UUID = UUID(), title: String, type: ReminderType, times: [Date], startDate: Date, endDate: Date, active: Bool, nextDue: Date, completedTimes: [Date] = [], lastModifiedDate: Date = Date(), lastResetDate: Date? = nil) {
        self.id = id
        self.title = title
        self.type = type
        self.times = times.sorted { $0 < $1 }
        self.startDate = startDate
        self.endDate = endDate
        self.active = active
        self.nextDue = nextDue
        self.completedTimes = completedTimes
        self.lastModifiedDate = lastModifiedDate
        self.lastResetDate = lastResetDate
    }
}
// MARK: - ReminderDetailRow View (Redesigned to match React Card Style)
struct ReminderDetailRow: View {
    @Binding var reminder: Reminder // Changed to Binding for direct modification
    var onToggleActive: (UUID) -> Void // Renamed to avoid confusion with time slot toggle
    var onDelete: (UUID) -> Void
    var onEdit: (Reminder) -> Void
    // New: Callback when a specific time slot is marked OK/Reopened
    var onToggleTimeSlotCompletion: (UUID, Date) -> Void

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundTint)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)

            Rectangle()
                .fill(borderTint)
                .frame(width: 4)
                .clipShapeWithRoundedCorners(12, corners: [.topLeft, .bottomLeft])

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: reminder.iconName)
                        .font(.body)
                        .foregroundColor(iconColor)
                        .frame(width: 36, height: 36)
                        .background(iconBackgroundColor)
                        .clipShape(Circle())

                    VStack(alignment: .leading) {
                        Text(reminder.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(reminder.type.displayName)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)


                        // Display all times and their individual statuses
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(reminder.times.sorted(), id: \.self) { time in
                                HStack {
                                    Text(Self.timeFormatter.string(from: time))
                                        .font(.subheadline)
                                        .foregroundColor(textColorForTimeSlot(time))
                                    
                                    Spacer()
                                    
                                    // Status Badge for individual time slot
                                    if reminder.isTimeSlotOverdue(time: time) {
                                        Text("Overdue")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.15))
                                            .foregroundColor(.red.opacity(0.9))
                                            .cornerRadius(4)
                                    } else if reminder.isTimeSlotCompleted(time: time) {
                                        Text("Done")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.15))
                                            .foregroundColor(.green.opacity(0.9))
                                            .cornerRadius(4)
                                    } else {
                                        Text("Pending")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.15))
                                            .foregroundColor(.orange.opacity(0.9))
                                            .cornerRadius(4)
                                    }
                                    
                                    // OK/Reopen button for individual time slot
                                    Button(action: {
                                        onToggleTimeSlotCompletion(reminder.id, time)
                                    }) {
                                        Image(systemName: reminder.isTimeSlotCompleted(time: time) ? "arrow.counterclockwise.circle.fill" : "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(reminder.isTimeSlotCompleted(time: time) ? .gray : .green)
                                    }
                                    .buttonStyle(.plain) // Prevent default button styling
                                    // Validation: Can only check if overdue, or uncheck if already completed
                                    .disabled(!reminder.active || reminder.hasPeriodEnded || reminder.isFutureReminder || (!reminder.isTimeSlotOverdue(time: time) && !reminder.isTimeSlotCompleted(time: time)))
                                }
                            }
                        }
                    }
                    Spacer()
                    
                    // Toggle for reminder active state
                    Toggle(isOn: $reminder.active) {
                        EmptyView()
                    }
                    .labelsHidden()
                    .onChange(of: reminder.active) { _, newValue in
                        onToggleActive(reminder.id)
                    }
                }

                Divider()

                HStack {
                    VStack(alignment: .leading) {
                        Text("Period:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Self.dateFormatter.string(from: reminder.startDate)) - \(Self.dateFormatter.string(from: reminder.endDate))")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    
                    // Edit Button (only for Health Checkup reminders)
                    if reminder.type == .checkup {
                        Button(action: {
                            onEdit(reminder)
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Delete Button
                    Button(action: {
                        onDelete(reminder.id)
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .padding(.leading, 4) // Offset for the side border
        }
        .padding(.horizontal)
        .padding(.vertical,10)
    }

    private var backgroundTint: Color {
        reminder.active ? Color.white : Color.gray.opacity(0.1)
    }

    private var borderTint: Color {
        if !reminder.active {
            return .gray.opacity(0.5)
        } else if reminder.hasPeriodEnded {
            return .gray
        } else if reminder.isOverdue {
            return .red
        } else if reminder.isCompletedForAllTimesToday {
            return .green
        } else if reminder.isFutureReminder {
            return .blue.opacity(0.6)
        } else {
            return .blue
        }
    }

    private var iconColor: Color {
        if !reminder.active || reminder.hasPeriodEnded {
            return .gray
        } else if reminder.isOverdue {
            return .red
        } else if reminder.isCompletedForAllTimesToday {
            return .green
        } else {
            return .blue
        }
    }

    private var iconBackgroundColor: Color {
        if !reminder.active || reminder.hasPeriodEnded {
            return .gray.opacity(0.1)
        } else if reminder.isOverdue {
            return .red.opacity(0.1)
        } else if reminder.isCompletedForAllTimesToday {
            return .green.opacity(0.1)
        } else {
            return .blue.opacity(0.1)
        }
    }
    
    private func textColorForTimeSlot(_ time: Date) -> Color {
        if !reminder.active || reminder.hasPeriodEnded || reminder.isFutureReminder {
            return .gray
        } else if reminder.isTimeSlotCompleted(time: time) {
            return .green
        } else if reminder.isTimeSlotOverdue(time: time) {
            return .red
        } else {
            return .primary
        }
    }
}


// MARK: - ReminderSummaryCard (New View for the top summary cards)
struct ReminderSummaryCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let tintColor: Color
    let gradientStart: Color
    let gradientEnd: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [gradientStart, gradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tintColor.opacity(0.2), lineWidth: 1) // Subtle border
            )
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2) // Consistent shadow
            .frame(maxWidth: .infinity) // Ensures card expands horizontally
            .aspectRatio(4/1, contentMode: .fit) // Adjusted aspect ratio for smaller cards
            .overlay( // Content goes inside the overlay
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(tintColor.opacity(0.8))
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(tintColor.opacity(0.6))
                    }
                    Spacer()
                    Image(systemName: iconName)
                        .font(.title2)
                        .padding(8)
                        .background(tintColor.opacity(0.2)) // Icon background tint
                        .clipShape(Circle())
                        .foregroundColor(tintColor.opacity(0.7))
                }
                .padding(10) // Slightly reduced padding inside the card content
            )
    }
}

// MARK: - AddNewReminderSheetView (New View for the Add Reminder Dialog/Sheet)
struct AddNewReminderSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var reminderToEdit: Reminder? // New binding for editing
    var onSave: (Reminder) -> Void

    @State private var title: String = ""
    @State private var type: Reminder.ReminderType = .checkup // Fixed to .checkup for new additions
    @State private var selectedTimes: [Date] = [Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!] // For multiple times
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
    
    // Internal state to manage individual time inputs (for UX)
    @State private var newTime: Date = Date()

    var isEditMode: Bool { reminderToEdit != nil }

    var body: some View {
        NavigationView {
            Form {
                Section("Reminder Details") {
                    TextField("Reminder Title (e.g., Blood Pressure Check)", text: $title)
                    // Picker for Type is fixed to .checkup and disabled
                    Picker("Reminder Type", selection: $type) {
                        Text(Reminder.ReminderType.checkup.displayName).tag(Reminder.ReminderType.checkup)
                    }
                    .disabled(true) // Disable selection as it's fixed to Health Checkup
                }

                Section("Schedule Times (Daily)") {
                    ForEach(selectedTimes.sorted(), id: \.self) { time in
                        HStack {
                            Text(time, formatter: ReminderDetailRow.timeFormatter)
                            Spacer()
                            Button(role: .destructive) {
                                selectedTimes.removeAll(where: { $0 == time })
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        DatePicker("Add New Time", selection: $newTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                        Button("Add") {
                            if !selectedTimes.contains(where: { Calendar.current.isDate($0, equalTo: newTime, toGranularity: .minute) }) {
                                selectedTimes.append(newTime)
                                selectedTimes.sort() // Keep times sorted
                            }
                            newTime = Date() // Reset for next input
                        }
                        .disabled(selectedTimes.count >= 5) // Limit number of times if desired
                    }
                }

                Section("Reminder Period") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
            }
            .navigationTitle(isEditMode ? "Edit Reminder" : "Add New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let calendar = Calendar.current
                        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
                        // For nextDue, we can pick the first time today, or simply the earliest time from 'times'
                        // If times are empty, nextDue won't be meaningful, so we enforce at least one time.
                        let nextDueTime = selectedTimes.first ?? Date() // Use first time for nextDue calculation
                        let selectedTimeComponents = calendar.dateComponents([.hour, .minute], from: nextDueTime)
                        
                        components.hour = selectedTimeComponents.hour
                        components.minute = selectedTimeComponents.minute
                        
                        let calculatedNextDue = calendar.date(from: components) ?? Date()
                        
                        // Ensure at least one time is selected for a new reminder
                        guard !title.isEmpty && !selectedTimes.isEmpty else { return }

                        let savedReminder = Reminder(
                            id: reminderToEdit?.id ?? UUID(),
                            title: title,
                            type: type, // Will always be .checkup for new additions
                            times: selectedTimes,
                            startDate: Calendar.current.startOfDay(for: startDate), // Normalize dates to start of day
                            endDate: Calendar.current.startOfDay(for: endDate),
                            active: reminderToEdit?.active ?? true, // Preserve active state if editing
                            nextDue: calculatedNextDue,
                            completedTimes: reminderToEdit?.completedTimes ?? [], // Preserve completed times if editing, else empty
                            lastModifiedDate: Date(), // Update last modified date
                            lastResetDate: reminderToEdit?.lastResetDate // Preserve last reset date if editing
                        )
                        onSave(savedReminder)
                        dismiss()
                    }
                    .disabled(title.isEmpty || selectedTimes.isEmpty) // Disable save if title or times are empty
                }
            }
            .onAppear {
                if let reminder = reminderToEdit {
                    // Only allow editing for .checkup type
                    if reminder.type == .checkup {
                        title = reminder.title
                        type = reminder.type
                        selectedTimes = reminder.times // Load existing times
                        startDate = reminder.startDate
                        endDate = reminder.endDate
                    } else {
                        // If it's a medicine type, we shouldn't be here, but just in case, dismiss.
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - NoRemindersPlaceholderView (New View for when no reminders exist)
struct NoRemindersPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.fill") // A bell with a slash, indicating no reminders
                .font(.largeTitle)
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 4) {
                Text("No reminders set up yet")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("Add your first reminder to get started")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

// MARK: - RemindersScreen (Second Tab Content)
struct RemindersScreen: View {
    let medicinesCount: Int // This property is passed from MedicineTracker
    @Binding var reminders: [Reminder]
    @State private var showingAddReminderSheet = false
    @State private var reminderToEdit: Reminder? // For editing existing reminders
    @State private var refreshID = UUID() // To force redraws if SwiftUI misses something

    private var activeRemindersCount: Int {
        reminders.filter { $0.active && !$0.hasPeriodEnded && !$0.isFutureReminder }.count
    }

    private var overdueRemindersCount: Int {
        reminders.filter { $0.active && $0.isOverdue && !$0.isCompletedForAllTimesToday }.count
    }

    private var onTrackPercentage: Int {
        guard activeRemindersCount > 0 else { return 100 }
        // On track means not overdue for any time slot
        let completedOrNotOverdueCount = reminders.filter {
            $0.active && !$0.hasPeriodEnded && !$0.isFutureReminder && !$0.isOverdue
        }.count
        
        return Int(round(Double(completedOrNotOverdueCount) / Double(activeRemindersCount) * 100))
    }

    var body: some View {
        NavigationStack { // Provides its own navigation bar and full screen behavior
            GeometryReader { geometry in // Use GeometryReader to get safe area insets
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Reminders-specific subheading
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Manage your health checkup and medicine reminders") // Updated subheading
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        
                        // SMAMedicineTrackerStats is a generic header, keep it here
                        // For the purpose of the Reminder Screen, we might want custom stats
                        // but keeping the shared one for now as per previous structure.
                        // You can replace this with Reminder-specific stats if needed.
                        SMAMedicineTrackerStats(medicinesCount: medicinesCount)
                        
                        // Reminders Summary Stats Cards
                        VStack(spacing: 12) { // Arranged vertically
                            ReminderSummaryCard(
                                title: "\(activeRemindersCount)", subtitle: "Active Reminders",
                                iconName: "bell.fill", tintColor: .blue,
                                gradientStart: .blue.opacity(0.05), gradientEnd: .blue.opacity(0.1)
                            )
                            ReminderSummaryCard(
                                title: "\(overdueRemindersCount)", subtitle: "Overdue",
                                iconName: "exclamationmark.triangle.fill", tintColor: .red,
                                gradientStart: .red.opacity(0.05), gradientEnd: .red.opacity(0.1)
                            )
                            ReminderSummaryCard(
                                title: "\(onTrackPercentage)%", subtitle: "On Track",
                                iconName: "checkmark.circle.fill", tintColor: .green,
                                gradientStart: .green.opacity(0.05), gradientEnd: .green.opacity(0.1)
                            )
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 5)

                        // All Reminders Section
                        Text("All Reminders") // Updated section title
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top, 10)
                            .padding(.horizontal)

                        LazyVStack(spacing: 8) {
                            if reminders.isEmpty {
                                NoRemindersPlaceholderView()
                                    .padding(.horizontal)
                            } else {
                                // Filter out ended reminders for display here
                                ForEach(reminders.filter { !$0.hasPeriodEnded }.sorted(by: { $0.nextDue < $1.nextDue })) { reminder in // Iterate over value, not binding
                                    // Find the binding for this specific reminder
                                    if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
                                        ReminderDetailRow(
                                            reminder: $reminders[index], // Pass the specific binding
                                            onToggleActive: { id in
                                                if let reminderIndex = reminders.firstIndex(where: { $0.id == id }) {
                                                    reminders[reminderIndex].active.toggle()
                                                    reminders[reminderIndex].lastModifiedDate = Date()
                                                    print("Toggled reminder \(reminders[reminderIndex].title) to active: \(reminders[reminderIndex].active)")
                                                }
                                            },
                                            onDelete: { id in
                                                // Perform the deletion with an animation block
                                                withAnimation {
                                                    reminders.removeAll(where: { $0.id == id })
                                                    print("Deleted reminder: \(reminder.title)")
                                                }
                                                // No need for refreshID here; `withAnimation` and SwiftUI's diffing should handle it.
                                            },
                                            onEdit: { reminderToEdit in
                                                if reminderToEdit.type == .checkup {
                                                    self.reminderToEdit = reminderToEdit
                                                    showingAddReminderSheet = true
                                                } else {
                                                    print("Editing not allowed for this reminder type.")
                                                }
                                            },
                                            onToggleTimeSlotCompletion: { id, timeSlot in
                                                if let reminderIndex = reminders.firstIndex(where: { $0.id == id }) {
                                                    if reminders[reminderIndex].isTimeSlotCompleted(time: timeSlot) {
                                                        reminders[reminderIndex].completedTimes.removeAll { completedDate in
                                                            Calendar.current.isDate(completedDate, equalTo: timeSlot, toGranularity: .minute) &&
                                                            Calendar.current.isDate(completedDate, inSameDayAs: Date())
                                                        }
                                                        print("Reopened time slot \(ReminderDetailRow.timeFormatter.string(from: timeSlot)) for reminder: \(reminders[reminderIndex].title)")
                                                    } else {
                                                        reminders[reminderIndex].completedTimes.append(timeSlot)
                                                        print("Completed time slot \(ReminderDetailRow.timeFormatter.string(from: timeSlot)) for reminder: \(reminders[reminderIndex].title)")
                                                    }
                                                    reminders[reminderIndex].lastModifiedDate = Date()
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                        // Removed .id(refreshID) from LazyVStack, it's typically for when you change the *entire* list structure,
                        // not for individual item additions/deletions/updates handled by ForEach's ID.
                        // Let ForEach handle its own identity.
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 60)
                }
            }
            .navigationTitle("Smart Reminders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        reminderToEdit = nil
                        showingAddReminderSheet = true
                    }) {
                        Label("Add Reminder", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddReminderSheet, onDismiss: {
                // Ensure cleanup and reset logic runs after sheet dismissal
                removeExpiredReminders()
                resetCompletedRemindersForNewDay()
                // Keep refreshID here, as adding/editing might change the order or count,
                // and a full refresh might be desirable for the main list.
                refreshID = UUID()
            }) {
                AddNewReminderSheetView(reminderToEdit: $reminderToEdit) { savedReminder in
                    if let index = reminders.firstIndex(where: { $0.id == savedReminder.id }) {
                        reminders[index] = savedReminder
                        print("Updated existing reminder: \(savedReminder.title)")
                    } else {
                        reminders.append(savedReminder)
                        print("Added new reminder: \(savedReminder.title)")
                    }
                    reminders.sort { $0.nextDue < $1.nextDue }
                }
            }
            .onAppear(perform: {
                // Initial cleanup and reset when the view appears
                removeExpiredReminders()
                resetCompletedRemindersForNewDay()
                // Keep refreshID here for the initial load
                refreshID = UUID()
            })
        }
    }
    
    // Function to remove reminders whose end date has passed
    private func removeExpiredReminders() {
        let initialCount = reminders.count
        reminders.removeAll { reminder in
            let shouldRemove = reminder.hasPeriodEnded
            if shouldRemove {
                print("Removed expired reminder: \(reminder.title)")
            }
            return shouldRemove
        }
        if reminders.count != initialCount {
            // A change in count means a visual change, so a refresh here is appropriate.
            refreshID = UUID()
            print("Expired reminders cleaned up. Count changed from \(initialCount) to \(reminders.count)")
        }
    }

    // New function to reset completed times for reminders at the start of a new day
    private func resetCompletedRemindersForNewDay() {
        let calendar = Calendar.current
        var changed = false
        for i in reminders.indices {
            if let lastReset = reminders[i].lastResetDate, calendar.isDateInToday(lastReset) {
                continue
            }
            
            if !reminders[i].completedTimes.isEmpty {
                 reminders[i].completedTimes = []
                 reminders[i].lastModifiedDate = Date()
                 changed = true
                 print("Reset completed times for reminder: \(reminders[i].title) for a new day.")
            }
            reminders[i].lastResetDate = Date()
        }
        if changed {
            // A change means a visual change, so a refresh here is appropriate.
            refreshID = UUID()
        }
    }
}
