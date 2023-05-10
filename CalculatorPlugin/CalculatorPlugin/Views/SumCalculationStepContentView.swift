//
//  SumCalculationStepContentView.swift
//  AppAuth
//
//  Created by Igor Ferreira on 10/5/23.
//

import SwiftUI
import MobileWorkflowCore
import CurrencyText

struct SumCalculationStepContentView: View {
    @EnvironmentObject var step: SumCalculationStep
    var navigator: Navigator { step.navigator }
    
    @State private var presentAlert: Bool = false
    @State private var nextItemText: String = ""
    @State private var items: [CalculatorSumCalculationItem] = []
    @State private var total: Double = 0.0
    @State private var editMode: EditMode = .inactive
    @State private var animateStateChange: Bool = false
    
    private let currencyFormatter: CurrencyFormatter
    private let numberFormatter: NumberFormatter

    init(currencyFormatter: CurrencyFormatter = .default(), numberFormatter: NumberFormatter = NumberFormatter()) {
        self.currencyFormatter = currencyFormatter
        self.numberFormatter = numberFormatter
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Form {
                if let text = step.properties.text {
                    HStack(alignment: .top) {
                        Image(systemName: "info.circle")
                            .padding(.top, 3)
                        Text(text)
                    }
                }
                Section {
                    ForEach($items) { $item in
                        if step.type == .currency {
                            SumCalculationCurrencyItemView(item: $item, currencyFormatter: currencyFormatter, stringResolution: step.resolve(_:))
                        } else {
                            SumCalculationNumberItemView(item: $item, formatter: numberFormatter, stringResolution: step.resolve(_:))
                        }
                    }
                    .onDelete { indexSet in
                        items.remove(atOffsets: indexSet)
                    }
                    if(step.allowUserToAddItems) {
                        Button {
                            nextItemText = ""
                            presentAlert = true
                        } label: {
                            HStack(alignment: .center) {
                                Spacer()
                                Image(systemName: "plus")
                                Text(step.resolve("Add Item"))
                                Spacer()
                            }
                        }
                        .alert(step.resolve("Add Item"), isPresented: $presentAlert, actions: {
                            TextField(step.resolve("Name"), text: $nextItemText)
                            Button(step.resolve("Cancel"), role: .cancel, action: { presentAlert = false })
                            Button(step.resolve("Add"), action: createNewEntry)
                        }, message: {
                            Text(step.resolve("Add a new item to the calculation."))
                        })
                    }
                }
                Section {
                    HStack {
                        Text(step.resolve("Total")).font(.headline)
                        Spacer()
                        SumCalculationTotalView(type: step.type, total: total, currencyFormatter: currencyFormatter)
                    }
                }
            }
            if navigator.hasNextStep {
                ARButton(title: step.resolve("Next"), action: self.continue).padding(.vertical)
            }
        }
        .background(Color(UIColor.quaternarySystemFill))
        .onChange(of: items, perform: calculateTotal(items:))
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.editing), perform: checkEditingNotification(notification:))
        .task { loadItems() }
        .animation(animateStateChange ? .default : nil)
        .environment(\.editMode, $editMode)
    }
    
    private func checkEditingNotification(notification: Notification) {
        animateStateChange = true
        editMode = notification.isEditing(stepId: step.identifier) ? .active : .inactive
    }
    
    private func createNewEntry() {
        animateStateChange = true
        items.append(CalculatorSumCalculationItem(text: nextItemText))
        nextItemText = ""
    }
    
    private func loadItems() {
        if items.isEmpty { items = step.properties.items }
    }
    
    private func calculateTotal(items: [CalculatorSumCalculationItem]) {
        total = items.reduce(0, { $0 + $1.value })
    }
    
    @MainActor
    @Sendable private func `continue`() async {
        await navigator.continue(result: SumCalculationResponse(identifier: step.identifier, items: items, total: total))
    }
}

struct SumCalculationStepContentViewPreviews: PreviewProvider {
    static var previews: some View {
        SumCalculationStepContentView().environmentObject(
            SumCalculationStep(
                properties: .calculatorSumCalculation(
                    id: "SumCalculationStep",
                    title: "Calculator",
                    items: [
                        CalculatorSumCalculationItem(text: "Removal Fees"),
                        CalculatorSumCalculationItem(text: "Conveyancing")
                    ],
                    sumCalculationType: SumCalculationType.currency.rawValue,
                    allowUserToAddItems: true
                ),
                session: Session.buildEmptySession(),
                services: StepServices.buildEmptyServices()
            )
        )
        
        SumCalculationStepContentView().environmentObject(
            SumCalculationStep(
                properties: .calculatorSumCalculation(
                    id: "SumCalculationStep",
                    title: "Calculator",
                    items: [
                        CalculatorSumCalculationItem(text: "Removal Fees"),
                        CalculatorSumCalculationItem(text: "Conveyancing")
                    ],
                    sumCalculationType: SumCalculationType.number.rawValue,
                    allowUserToAddItems: true
                ),
                session: Session.buildEmptySession(),
                services: StepServices.buildEmptyServices()
            )
        )
    }
}
