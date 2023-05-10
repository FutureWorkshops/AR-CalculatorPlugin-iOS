//
//  SumCalculationCurrencyItemView.swift
//  CalculatorPlugin
//
//  Created by Igor Ferreira on 10/5/23.
//

import SwiftUI
import CurrencyText

struct SumCalculationCurrencyItemView: View {
    private let numberFormatter: NumberFormatter
    private let currencyFormatter: CurrencyFormatter
    private let stringResolution: (String) -> String
    @State private var val: String = ""
    @State private var unformattedVal: String? = nil
    @Binding var item: CalculatorSumCalculationItem
    
    
    init(
        item: Binding<CalculatorSumCalculationItem>,
        currencyFormatter: CurrencyFormatter = .default,
        numberFormatter: NumberFormatter = NumberFormatter(),
        stringResolution: @escaping (String) -> String = { $0 }
    ) {
        self._item = item
        self.currencyFormatter = currencyFormatter
        self.numberFormatter = numberFormatter
        self.stringResolution = stringResolution
    }
    
    var body: some View {
        HStack {
            Text(stringResolution(item.text))
                .font(.headline)
            CurrencyTextField(
                configuration: .init(
                    placeholder: stringResolution("Tap to enter"),
                    text: $val,
                    unformattedText: $unformattedVal,
                    formatter: currencyFormatter,
                    textFieldConfiguration: { textField in
                        textField.keyboardType = .numberPad
                        textField.textAlignment = .right
                    }
                )
            )
            .multilineTextAlignment(.trailing)
            .onChange(of: val) { newVal in
                item.value = numberFormatter.number(from: unformattedVal ?? "0")?.doubleValue ?? 0
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
