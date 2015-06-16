//
//  main.swift
//  swiftrest
//
//  Created by Steffen Neubauer on 16/06/15.
//  Copyright © 2015 Steffen Neubauer. All rights reserved.
//

// hah! we don't need this.
//import Foundation


let con = HttpConnection(type: .Request)
let con2 = HttpConnection(type: .Request)

try con2.receive(return_test_data(), len: return_test_length())
try con.receive(return_test_data(), len: return_test_length())
