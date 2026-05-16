//
//  Optional+Bool.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

extension Optional where Wrapped == Bool {
    var orFalse: Bool { self ?? false }
}

