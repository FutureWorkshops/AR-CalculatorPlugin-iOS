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

public struct CalculatorSumCalculationItem: Codable, Identifiable, Equatable, CustomStringConvertible {
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case value
    }
    
    public let id: String
    public let text: String
    public var value: Double
    
    public var description: String {
        "\(text): \(value)"
    }
    
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
    public var editMode: EditMode = .inactive
    
    public static func == (lhs: SumCalculationStep, rhs: SumCalculationStep) -> Bool {
        lhs.identifier == rhs.identifier && lhs.properties.items == rhs.properties.items && lhs.editMode == rhs.editMode
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
    
    public override func updateBarButtonItems() {
        super.updateBarButtonItems()
        guard self.sumCalculationStep.allowUserToAddItems else { return }
        
        var items = self.navigationItem.rightBarButtonItems
        items?.append(self.editButtonItem)
        self.navigationItem.rightBarButtonItems = items
    }
    
    public override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        NotificationCenter.default.post(Notification(
            name: .editing,
            object: nil,
            userInfo: Notification.editingInfo(editing: editing, step: self.sumCalculationStep)
        ))
    }
}

internal extension Notification.Name {
    static let editing = Notification.Name("SumCalculationStepViewController.setEditing")
}

internal extension Notification {
    static let editingLabel = "editing"
    static let stepIdLabel = "stepId"
    
    static func editingInfo(editing: Bool, step: ObservableStep) -> [AnyHashable: Any] {
        [Notification.editingLabel: editing, Notification.stepIdLabel: step.identifier]
    }
    
    func isEditing(stepId: String) -> Bool {
        guard userInfo?[Notification.stepIdLabel] as? String == stepId else { return false }
        return userInfo?[Notification.editingLabel] as? Bool ?? false
    }
}

internal extension CurrencyFormatter {
    static var `default`: CurrencyFormatter {
        CurrencyFormatter {
            $0.currency = .poundSterling
            $0.hasDecimals = false
        }
    }
}

struct SumCalculationResponse: Codable {
    let items: [CalculatorSumCalculationItem]
    let total: Double
}

// MARK: - Step properties configuration
public class CalculatorSumCalculationMetadata: StepMetadata {
    enum CodingKeys: String, CodingKey {
        case items
        case sumCalculationType
        case allowUserToAddItems
        case currencyCode
        case text
    }

    let items: [CalculatorSumCalculationItem]
    let sumCalculationType: String
    let allowUserToAddItems: Bool?
    let currencyCode: String?
    let text: String?

    init(id: String, title: String, items: [CalculatorSumCalculationItem], sumCalculationType: String, allowUserToAddItems: Bool?, currencyCode: String?, text: String?, next: PushLinkMetadata?, links: [LinkMetadata]) {
        self.items = items
        self.sumCalculationType = sumCalculationType
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
    static func calculatorSumCalculation(id: String, title: String, items: [CalculatorSumCalculationItem], sumCalculationType: String, allowUserToAddItems: Bool? = nil, currencyCode: String? = nil, text: String? = nil, next: PushLinkMetadata? = nil, links: [LinkMetadata] = []) -> CalculatorSumCalculationMetadata {
        CalculatorSumCalculationMetadata(
            id: id,
            title: title,
            items: items,
            sumCalculationType: sumCalculationType,
            allowUserToAddItems: allowUserToAddItems,
            currencyCode: currencyCode,
            text: text,
            next: next,
            links: links
        )
    }
}
