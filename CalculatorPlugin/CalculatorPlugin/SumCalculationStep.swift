//
//  SumCalculationStep.swift
//  CalculatorPlugin
//
//

import Foundation
import MobileWorkflowCore
import SwiftUI

public struct SumCalculationItem: Codable, Identifiable {
    public let id: String
    public let label: String
    public var value: Int = 0
}
 

public class SumCalculationStep: ObservableStep {
    let type: String?
    let items: [SumCalculationItem]
    let allowUserToAddItems: Bool?

    public init(identifier: String, type: String?, items: [SumCalculationItem], allowUserToAddItems: Bool?, session: Session, services: StepServices) {
        self.type = type
        self.items = items
        self.allowUserToAddItems = allowUserToAddItems
        super.init(identifier: identifier, session: session, services: services)
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
        let type = stepInfo.data.content["type"] as? String
        guard let items = stepInfo.data.content["items"] as? Any else {
            throw ParseError.invalidStepData(cause: "Mandatory items property not found")
        }
        let allowUserToAddItems = stepInfo.data.content["allowUserToAddItems"] as? Bool
        return SumCalculationStep(identifier: stepInfo.data.identifier, type: type, items: [], allowUserToAddItems: allowUserToAddItems, session: stepInfo.session, services: services)
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
    @State private var nextItemLabel = ""
    private var total: Int {
        items.reduce(0, { $0 + $1.value })
    }

    var body: some View {
        Form {
            Section {
                ForEach(items) { item in
                    SumCalculationItemView(item: item) { newValue in
                        mutate(item: item.id, value: newValue)
                    }
                }
                Button("Add Item") {
                    nextItemLabel = ""
                    presentAlert = true
                }
                .alert("Login", isPresented: $presentAlert, actions: {
                    TextField("Name", text: $nextItemLabel)
                    
                    Button("Cancel", role: .cancel, action: {})
                    Button("Add", action: {
                        items.append(SumCalculationItem(id: UUID().uuidString, label: nextItemLabel))
                    })
                }, message: {
                    Text("Add a new item.")
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
    
    private func mutate(item id: String, value: Int) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        var item = items[index]
        item.value = value
        items[index] = item
    }

    @MainActor
    @Sendable private func select(item: SumCalculationItem) async {
        navigator.continue(selecting: item)
    }
}

struct SumCalculationItemView: View {
    @State var text: String = ""

    let formatter: NumberFormatter = NumberFormatter()
    let item: SumCalculationItem
    let onValueChange: (Int) -> Void
    
    var body: some View {
        HStack {
            Text(item.label)
                .font(.headline)
            TextField("Tap to enter", text: $text)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .onChange(of: text) { newValue in
                    onValueChange(formatter.number(from: newValue)?.intValue ?? 0)
                }
        }
    }
}

struct SumCalculationStepContentViewPreviews: PreviewProvider {
    static var previews: some View {
        SumCalculationStepContentView(
            items: [
                SumCalculationItem(id: "1", label: "Removal Fees"),
                SumCalculationItem(id: "2", label: "Conveyancing")
            ]
        ).environmentObject(SumCalculationStep(
            identifier: "",
            type: "Lorum ipsum",
            items: [],
            allowUserToAddItems: false,
            session: Session.buildEmptySession(),
            services: StepServices.buildEmptyServices()
        ))
    }
}

