//
//  ViewController.swift
//  Example
//
//  Created by Min Kim on 1/19/19.
//  Copyright © 2019 Min Kim. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    lazy var label: UILabel = {
        let label: UILabel = .init()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func configure(userId: String) {
        label.text = "User ID: \(userId)"
    }

    func configure(bookId: String) {
        label.text = "Book ID: \(bookId)"
    }
}
