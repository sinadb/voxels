//
//  constants.swift
//  MetalProject
//
//  Created by Sina Dashtebozorgy on 10/03/2023.
//

import Foundation

struct transformation_mode {
    static let translate_first = 0
    static let rotate_first = 1
}

struct vertexBufferIDs {
    static let vertexBuffers = 0
    static let uniformBuffers = 1
    static let instanceBuffers = 2
    static let skyMap = 3
    static let order_of_rot_tran = 4
}

struct textureIDs {
    static let cubeMap  = 0
    static let flat = 1
}

struct fragmentBufferIDs {
  static let colours = 0
}
