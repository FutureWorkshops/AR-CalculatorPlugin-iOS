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
    let currencyFormatter: CurrencyFormatter
    
    init(type: SumCalculationType, total: Double, currencyFormatter: CurrencyFormatter = .default) {
        self.type = type
        self.total = total
        self.currencyFormatter = currencyFormatter
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
