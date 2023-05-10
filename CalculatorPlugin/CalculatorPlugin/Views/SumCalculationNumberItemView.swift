//
//  SumCalculationNumberItemView.swift
//  CalculatorPlugin
//
//  Created by Igor Ferreira on 10/5/23.
//

import SwiftUI

struct SumCalculationNumberItemView: View {
    private let formatter: NumberFormatter
    private let stringResolution: (String) -> String
    @State private var val: String = ""
    @Binding var item: CalculatorSumCalculationItem
    
    init(
        item: Binding<CalculatorSumCalculationItem>,
        formatter: NumberFormatter = NumberFormatter(),
        stringResolution: @escaping (String) -> String = { $0 }
    ) {
        self._item = item
        self.formatter = formatter
        self.stringResolution = stringResolution
    }
    
    var body: some View {
        HStack {
            Text(stringResolution(item.text))
                .font(.headline)
            TextField(stringResolution("Tap to enter"), text: $val)
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


struct SumCalculationNumberItemView_Previews: PreviewProvider {
    
    static var previews: some View {
        SumCalculationNumberItemView(
            item: .constant(CalculatorSumCalculationItem(text: "Mocked entry"))
        )
    }
}
