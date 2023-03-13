//
//  Helper.swift
//  Metal Template
//
//  Created by Sina Dashtebozorgy on 04/03/2023.
//

import Foundation
import Metal
import MetalKit
import AppKit

struct Attribute {
    let format : MTLVertexFormat;
    let offset : Int;
    let bufferIndex : Int
}




func createVertexDescriptor(attributes : Int...){
    
    
    
    for (index,attribute) in attributes.enumerated(){
        print(index,attribute)
    }
    
}


