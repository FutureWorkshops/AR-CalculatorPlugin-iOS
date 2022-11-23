//
//  SumCalculationStep.swift
//  CalculatorPlugin
//
//

import Foundation
import MobileWorkflowCore
import SwiftUI

public struct SumCalculationItem: Codable, Identifiable, Equatable {
    public let id: String
    public let text: String
    public var value: Int = 0
}
 

public class SumCalculationStep: ObservableStep {
    let type: String
    let items: [SumCalculationItem]
    let allowUserToAddItems: Bool?

    public init(identifier: String, type: String, text: String?, items: [SumCalculationItem], allowUserToAddItems: Bool?, session: Session, services: StepServices) {
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
        
        let text = stepInfo.data.content["text"] as? String
        
        guard let items = stepInfo.data.content["items"] as? [[String: Any]] else {
            throw ParseError.invalidStepData(cause: "Mandatory items property not found")
        }
        
        let calculatorItems: [SumCalculationItem] = try items.map {
            return try makeSumCalculatorItem(with: $0)
        }
        
        let allowUserToAddItems = stepInfo.data.content["allowUserToAddItems"] as? Bool
        return SumCalculationStep(identifier: stepInfo.data.identifier, type: type, text: text, items: calculatorItems, allowUserToAddItems: allowUserToAddItems, session: stepInfo.session, services: services)
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
    private var total: Int {
        items.reduce(0, { $0 + $1.value })
    }

    var body: some View {
        Form {
            Section(header: Text(step.text ?? "")) {
                ForEach($items) { $item in
                    SumCalculationItemView(item: $item)
                }
                Button("Add Item") {
                    nextItemText = ""
                    presentAlert = true
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
            Section {
                HStack {
                    Text("Total").font(.headline)
                    Spacer()
                    Text("\(total)")
                }
            }
        }
    }

    @MainActor
    @Sendable private func select(item: SumCalculationItem) async {
        navigator.continue(selecting: item)
    }
}

struct SumCalculationItemView: View {
    private let formatter: NumberFormatter = NumberFormatter()
    @State private var val: String = ""
    @Binding var item: SumCalculationItem
    
    var body: some View {
        HStack {
            Text(item.text)
                .font(.headline)
            TextField("Tap to enter", text: $val)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .onChange(of: val) { newValue in
                    item.value = formatter.number(from: newValue)?.intValue ?? 0
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
            type: "currency",
            text: "Lorum ipsum",
            items: [],
            allowUserToAddItems: false,
            session: Session.buildEmptySession(),
            services: StepServices.buildEmptyServices()
        ))
    }
}

