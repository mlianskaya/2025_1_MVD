//
//  UserService.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

protocol UserService {
    func fetchUser(completion: @escaping (User) -> Void)
}


