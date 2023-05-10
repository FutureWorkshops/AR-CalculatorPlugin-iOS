//
//  SumCalculationNumberItemView.swift
//  CalculatorPlugin
//
//  Created by Igor Ferreira on 10/5/23.
//

import SwiftUI

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


struct SumCalculationNumberItemView_Previews: PreviewProvider {
    
    static var previews: some View {
        SumCalculationNumberItemView(
            item: .constant(CalculatorSumCalculationItem(text: "Mocked entry"))
        )
    }
}
