//
//  CalculatorPlugin.swift
//  CalculatorPlugin
//
//

import Foundation
import MobileWorkflowCore

public struct CalculatorPluginStruct: Plugin {
    public static var allStepsTypes: [StepType] {
        return CalculatorStepType.allCases
    }
}

enum CalculatorStepType: String, StepType, CaseIterable {
    case step1 = "io.app-rail.calculator.sum-calculation"
    
    var typeName: String {
        return self.rawValue
    }
    
    var stepClass: BuildableStep.Type {
        switch self {
        case .step1: return SumCalculationStep.self
        }
    }
}

