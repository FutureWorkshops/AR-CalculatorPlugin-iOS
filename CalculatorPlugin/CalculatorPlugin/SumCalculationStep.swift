//
//  SumCalculationStep.swift
//  CalculatorPlugin
//
//

import Foundation
import MobileWorkflowCore
import SwiftUI
import UIKit
import CurrencyText

public struct SumCalculationItem: Codable, Identifiable, Equatable {
    public let id: String
    public let text: String
    public var value: Double = 0
}

public enum SumCalculationType: String, CaseIterable {
    case currency = "currency"
    case number = "number"

    var typeName: String {
        return self.rawValue
    }
}
 

public class SumCalculationStep: ObservableStep {
    let type: SumCalculationType
    let items: [SumCalculationItem]
    let allowUserToAddItems: Bool

    public init(identifier: String, type: SumCalculationType, text: String?, items: [SumCalculationItem], allowUserToAddItems: Bool, session: Session, services: StepServices) {
        self.type = type
        self.items = items
        self.allowUserToAddItems = allowUserToAddItems
        super.init(identifier: identifier, session: session, services: services)
        self.text = text
    }

    public override func instantiateViewController() -> StepViewController {
        SumCalculationStepViewController(step: self)
    }
}

extension SumCalculationStep: BuildableStep {

    public static var mandatoryCodingPaths: [CodingKey] {
        ["items"]
    }

    public static func build(stepInfo: StepInfo, services: StepServices) throws -> Step {
        guard let type = stepInfo.data.content["type"] as? String else {
            throw ParseError.invalidStepData(cause: "Mandatory type property not found")
        }
        guard let sumCalculationType = SumCalculationType(rawValue: type) else {
            throw ParseError.invalidStepData(cause: "Invalid type property: \(type)")
        }
        
        let text = stepInfo.data.content["text"] as? String
        
        guard let items = stepInfo.data.content["items"] as? [[String: Any]] else {
            throw ParseError.invalidStepData(cause: "Mandatory items property not found")
        }
        
        let calculatorItems: [SumCalculationItem] = try items.map {
            return try makeSumCalculatorItem(with: $0)
        }
        
        let allowUserToAddItems = stepInfo.data.content["allowUserToAddItems"] as? Bool ?? false
        
        return SumCalculationStep(identifier: stepInfo.data.identifier, type: sumCalculationType, text: text, items: calculatorItems, allowUserToAddItems: allowUserToAddItems, session: stepInfo.session, services: services)
    }
    
    private static func makeSumCalculatorItem(with item: [String: Any]) throws -> SumCalculationItem {
        guard let id = item.getString(key: "id") else {
            throw ParseError.invalidStepData(cause: "Invalid id for step")
        }
        
        guard let text = item["text"] as? String else {
            throw ParseError.invalidStepData(cause: "Invalid text for step")
        }
        
        return SumCalculationItem(id: id, text: text)
    }
}

public class SumCalculationStepViewController: MWStepViewController {
    public override var titleMode: StepViewControllerTitleMode { .largeTitle }
    var sumCalculationStep: SumCalculationStep { self.step as! SumCalculationStep }
    
        public override func viewDidLoad() {
        super.viewDidLoad()
        self.addCovering(childViewController: UIHostingController(
            rootView: SumCalculationStepContentView(items: self.sumCalculationStep.items).environmentObject(self.sumCalculationStep)
        ))
    }
    
}

struct SumCalculationStepContentView: View {
    @EnvironmentObject var step: SumCalculationStep
    var navigator: Navigator { step.navigator }
    @State var items: [SumCalculationItem]
    @State private var presentAlert = false
    @State private var nextItemText = ""
    private var total: Double {
        items.reduce(0, { $0 + $1.value })
    }

    var body: some View {
        VStack(alignment: .leading) {
            Form() {
                if let text = step.text {
                    HStack(alignment: .top) {
                        Image(systemName: "info.circle")
                            .padding(.top, 3)
                        Text(text)
                    }
                }
                Section() {
                    ForEach($items) { $item in
                        SumCalculationCurrencyItemView(item: $item)
                    }
                    if(step.allowUserToAddItems) {
                        Button {
                            nextItemText = ""
                            presentAlert.toggle()
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
                            
                            Button("Cancel", role: .cancel, action: {})
                            Button("Add", action: {
                                items.append(SumCalculationItem(id: UUID().uuidString, text: nextItemText))
                            })
                        }, message: {
                            Text("Add a new item to the calculation.")
                        })
                    }
                }
                Section {
                    HStack {
                        Text("Total").font(.headline)
                        Spacer()
                        SumCalculationTotalView(type: step.type, total: total)
                    }
                }
            }
        }
        .background(Color(UIColor.quaternarySystemFill))
    }

    @MainActor
    @Sendable private func select(item: SumCalculationItem) async {
        navigator.continue(selecting: item)
    }
}

struct SumCalculationTotalView: View {
    let type: SumCalculationType
    let total: Double
    private var currencyFormatter: CurrencyFormatter {
        CurrencyFormatter {
            $0.currency = .poundSterling
            $0.hasDecimals = false
        }
    }
    
    var body: some View {
        switch type {
        case .currency:
            Text(currencyFormatter.string(from: total) ?? "")
        case .number:
            Text("\(total)")
        }
    }
}

struct SumCalculationCurrencyItemView: View {
    private let formatter: NumberFormatter = NumberFormatter()
    @State private var val: String = ""
    @State private var unformattedVal: String?
    @Binding var item: SumCalculationItem
    
    var body: some View {
        
        let ccyFormatter = CurrencyFormatter {
            $0.currency = .poundSterling
            $0.hasDecimals = false
        }
        
        HStack {
            Text(item.text)
                .font(.headline)
            CurrencyTextField(
                configuration: .init(
                    placeholder: "Tap to enter",
                    text: $val,
                    unformattedText: $unformattedVal,
                    formatter: ccyFormatter,
                    textFieldConfiguration: { textField in
                        textField.keyboardType = .numberPad
                        textField.textAlignment = .right
                    }
                )
            )
            .multilineTextAlignment(.trailing)
            .onChange(of: val) { newVal in
                item.value = formatter.number(from: unformattedVal ?? "0")?.doubleValue ?? 0
            }

        }
    }
}

struct SumCalculationNumberItemView: View {
    private let formatter: NumberFormatter = NumberFormatter()
    @State private var val: String = ""
    @Binding var item: SumCalculationItem
    
    var body: some View {
        HStack {
            Text(item.text)
                .font(.headline)
            TextField("Tap to enter", text: $val)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .onChange(of: val) { newValue in
                    item.value = formatter.number(from: newValue)?.doubleValue ?? 0
                }
        }.task {
            if(item.value == 0) {
                val = ""
            } else {
                val = "\(item.value)"
            }
        }
    }
}

struct SumCalculationStepContentViewPreviews: PreviewProvider {
    static var previews: some View {
        SumCalculationStepContentView(
            items: [
                SumCalculationItem(id: "1", text: "Removal Fees"),
                SumCalculationItem(id: "2", text: "Conveyancing")
            ]
        ).environmentObject(SumCalculationStep(
            identifier: "",
            type: .currency,
            text: "Use this calculator to work out how much cash you need to buy your house.",
            items: [],
            allowUserToAddItems: true,
            session: Session.buildEmptySession(),
            services: StepServices.buildEmptyServices()
        ))
    }
}

