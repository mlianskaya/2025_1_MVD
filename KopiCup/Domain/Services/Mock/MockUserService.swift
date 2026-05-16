//
//  MockUserService.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

class MockUserService: UserService {
    func fetchUser(completion: @escaping (User) -> Void) {
        completion(User(id: "1", name: "Павел", photoURL: nil))
    }
}

