//
//  SumCalculationTotalView.swift
//  CalculatorPlugin
//
//  Created by Igor Ferreira on 10/5/23.
//

import SwiftUI
import CurrencyText

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

struct SumCalculationTotalView_Previews: PreviewProvider {
    static var previews: some View {
        SumCalculationTotalView(type: .currency, total: 10.50)
    }
}
