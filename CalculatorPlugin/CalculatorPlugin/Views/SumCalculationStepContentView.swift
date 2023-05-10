//
//  SumCalculationStepContentView.swift
//  AppAuth
//
//  Created by Igor Ferreira on 10/5/23.
//

import SwiftUI
import MobileWorkflowCore

struct SumCalculationStepContentView: View {
    @EnvironmentObject var step: SumCalculationStep
    var navigator: Navigator { step.navigator }
    @State private var presentAlert = false
    @State private var nextItemText = ""
    @State private var items: [CalculatorSumCalculationItem] = []
    @State private var total: Double = 0
    @State var editMode: EditMode = .inactive

    var body: some View {
        VStack(alignment: .leading) {
            Form {
                if let text = step.text {
                    HStack(alignment: .top) {
                        Image(systemName: "info.circle")
                            .padding(.top, 3)
                        Text(text)
                    }
                }
                Section {
                    ForEach($items) { $item in
                        SumCalculationCurrencyItemView(item: $item)
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
                                Text("Add Item")
                                Spacer()
                            }
                        }
                        .alert("Add Item", isPresented: $presentAlert, actions: {
                            TextField("Name", text: $nextItemText)
                            Button("Cancel", role: .cancel, action: {
                                presentAlert = false
                            })
                            Button("Add", action: {
                                items.append(CalculatorSumCalculationItem(text: nextItemText))
                            })
                        }, message: {
                            Text("Add a new item to the calculation.")
                        })
                    }
                }
                Section {
                    HStack {
                        Text(step.resolve("Total")).font(.headline)
                        Spacer()
                        SumCalculationTotalView(type: step.type, total: total)
                    }
                }
            }.environment(\.editMode, $editMode)
        }
        .background(Color(UIColor.quaternarySystemFill))
        .task { loadItems() }
        .onChange(of: items, perform: calculateTotal(items:))
    }
    
    private func loadItems() {
        items = step.properties.items
    }
    
    private func calculateTotal(items: [CalculatorSumCalculationItem]) {
        total = items.reduce(0, { $0 + $1.value })
    }
    
    @MainActor
    @Sendable private func select(item: CalculatorSumCalculationItem) async {
        await navigator.continue(encoding: SumCalculationResponse(items: items, total: total))
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
                    type: SumCalculationType.currency.rawValue,
                    allowUserToAddItems: true
                ),
                session: Session.buildEmptySession(),
                services: StepServices.buildEmptyServices()
            )
        )
    }
}
