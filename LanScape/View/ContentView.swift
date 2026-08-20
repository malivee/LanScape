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
            LinearGradient(colors: [Color.background, .lightPurple], startPoint: .top, endPoint: .bottom)
            
            VStack {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 540)
                    .padding(.bottom, 40)
                
                
                
                Button {
                    
                } label: {
                    Text("Mulai")
                        .font(.largeTitle.bold())
                        .frame(width: 650)
                        .frame(height: 100)
                        .foregroundStyle(.white)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 50))
                        .padding(.bottom, 8)
                }
                
                Button {
                    
                } label: {
                    Text("Gallery")
                        .font(.largeTitle.bold())
                        .frame(width: 450)
                        .frame(height: 80)
                        .foregroundStyle(.white)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 50))
                }
            }
        }

        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
