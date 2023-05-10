//
//  SumCalculationCurrencyItemView.swift
//  CalculatorPlugin
//
//  Created by Igor Ferreira on 10/5/23.
//

import SwiftUI
import CurrencyText

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

struct SumCalculationCurrencyItemView_Previews: PreviewProvider {
    static var previews: some View {
        SumCalculationCurrencyItemView(
            item: .constant(CalculatorSumCalculationItem(text: "Mocked item"))
        )
    }
}
