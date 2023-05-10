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

public struct CalculatorSumCalculationItem: Codable, Identifiable, Equatable {
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case value
    }
    
    public let id: String
    public let text: String
    public var value: Double
    
    init(text: String, id: String = UUID().uuidString, value: Double = 0.0) {
        self.id = id
        self.text = text
        self.value = value
    }
    
    public static func calculatorSumCalculationItem(text: String, id: String = UUID().uuidString, value: Double = 0.0) -> CalculatorSumCalculationItem {
        CalculatorSumCalculationItem(
            text: text,
            id: id,
            value: value
        )
    }
}

public enum SumCalculationType: String, CaseIterable {
    case currency = "currency"
    case number = "number"

    var typeName: String {
        return self.rawValue
    }
}
 

public class SumCalculationStep: ObservableStep, BuildableStepWithMetadata, Equatable {
    public let properties: CalculatorSumCalculationMetadata
    public var type: SumCalculationType { SumCalculationType(rawValue: properties.sumCalculationType) ?? .number }
    public var allowUserToAddItems: Bool { properties.allowUserToAddItems ?? false }
    
    public static func == (lhs: SumCalculationStep, rhs: SumCalculationStep) -> Bool {
        lhs.identifier == rhs.identifier && lhs.properties.items == rhs.properties.items
    }
    
    public required init(properties: CalculatorSumCalculationMetadata, session: Session, services: StepServices) {
        self.properties = properties
        super.init(identifier: properties.id, session: session, services: services)
    }

    public override func instantiateViewController() -> StepViewController {
        SumCalculationStepViewController(step: self)
    }
}

public class SumCalculationStepViewController: MWStepViewController {
    public override var titleMode: StepViewControllerTitleMode { .largeTitle }
    var sumCalculationStep: SumCalculationStep { self.step as! SumCalculationStep }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.addCovering(childViewController: UIHostingController(
            rootView: SumCalculationStepContentView().environmentObject(self.sumCalculationStep)
        ))
    }
}

struct SumCalculationStepContentView: View {
    @EnvironmentObject var step: SumCalculationStep
    var navigator: Navigator { step.navigator }
    @State private var presentAlert = false
    @State private var nextItemText = ""
    @State private var items: [CalculatorSumCalculationItem] = []
    @State private var total: Double = 0

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
            }
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

struct SumCalculationResponse: Codable {
    let items: [CalculatorSumCalculationItem]
    let total: Double
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
    @Binding var item: CalculatorSumCalculationItem
    
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
    @Binding var item: CalculatorSumCalculationItem
    
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

// MARK: - Step properties configuration
public class CalculatorSumCalculationMetadata: StepMetadata {
    enum CodingKeys: String, CodingKey {
        case items
        case sumCalculationType = "type"
        case allowUserToAddItems
        case currencyCode
        case text
    }

    let items: [CalculatorSumCalculationItem]
    let sumCalculationType: String
    let allowUserToAddItems: Bool?
    let currencyCode: String?
    let text: String?

    init(id: String, title: String, items: [CalculatorSumCalculationItem], type: String, allowUserToAddItems: Bool?, currencyCode: String?, text: String?, next: PushLinkMetadata?, links: [LinkMetadata]) {
        self.items = items
        self.sumCalculationType = type
        self.allowUserToAddItems = allowUserToAddItems
        self.currencyCode = currencyCode
        self.text = text
        super.init(id: id, type: "io.app-rail.calculator.sum-calculation", title: title, next: next, links: links)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.items = try container.decode([CalculatorSumCalculationItem].self, forKey: .items)
        self.sumCalculationType = try container.decode(String.self, forKey: .sumCalculationType)
        self.allowUserToAddItems = try container.decodeIfPresent(Bool.self, forKey: .allowUserToAddItems)
        self.currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode)
        self.text = try container.decodeIfPresent(String.self, forKey: .text)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.items, forKey: .items)
        try container.encode(self.sumCalculationType, forKey: .sumCalculationType)
        try container.encodeIfPresent(self.allowUserToAddItems, forKey: .allowUserToAddItems)
        try container.encodeIfPresent(self.currencyCode, forKey: .currencyCode)
        try container.encodeIfPresent(self.text, forKey: .text)
        try super.encode(to: encoder)
    }
}

public extension StepMetadata {
    static func calculatorSumCalculation(id: String, title: String, items: [CalculatorSumCalculationItem], type: String, allowUserToAddItems: Bool? = nil, currencyCode: String? = nil, text: String? = nil, next: PushLinkMetadata? = nil, links: [LinkMetadata] = []) -> CalculatorSumCalculationMetadata {
        CalculatorSumCalculationMetadata(
            id: id,
            title: title,
            items: items,
            type: type,
            allowUserToAddItems: allowUserToAddItems,
            currencyCode: currencyCode,
            text: text,
            next: next,
            links: links
        )
    }
}
