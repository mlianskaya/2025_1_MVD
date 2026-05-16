//
//  FirebaseUserService.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI
import FirebaseFirestore

final class FirebaseUserService: UserService {

    func fetchUser(completion: @escaping (User) -> Void) {
        completion(User(id: "1", name: "Alex", photoURL: ""))
    }
}
