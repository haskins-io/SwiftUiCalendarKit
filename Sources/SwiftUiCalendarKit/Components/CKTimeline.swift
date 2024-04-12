//
//  SwiftUIView.swift
//  
//
//  Created by Mark Haskins on 12/04/2024.
//

import SwiftUI

struct CKTimeline: View {

    static let hourHeight = 60.0

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            ForEach(0..<24) { hour in

                HStack {
                    Text(String(format: "%02d:00", hour))
                        .font(.caption)
                        .frame(width: 40, alignment: .trailing)
                    Color.gray
                        .padding(.trailing, 10)
                        .frame(height: 1)
                }
                .frame(height: CKTimeline.hourHeight)
            }
        }
    }
}

#Preview {
    CKTimeline()
}
