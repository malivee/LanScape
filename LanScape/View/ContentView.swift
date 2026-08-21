//
//  ContentView.swift
//  LanScape
//
//  Created by Muhammad Alief Rahman Fardillah on 20/08/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Image("backgroundStart")
                .resizable()
                .aspectRatio(contentMode: .fill)
            
            VStack {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 328)
                    .padding(.bottom, 40)
                
                
                
                Button {
                    
                } label: {
                    Text("Mulai")
                        .font(.largeTitle.bold())
                        .frame(width: 450)
                        .frame(height: 85)
                        .foregroundStyle(.white)
                        .background(.darkBlue)
                        .glassEffect()
                        .clipShape(RoundedRectangle(cornerRadius: 50))
                        .padding(.bottom, 8)
                }
                
                Button {
                    
                } label: {
                    Text("Gallery")
                        .font(.largeTitle.bold())
                        .frame(width: 450)
                        .frame(height: 85)
                        .foregroundStyle(.darkBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 50))
                        .background(.clear)
                        .overlay(RoundedRectangle(cornerRadius: 50).stroke(.darkBlue, lineWidth: 5))
                }
            }
        }

        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
