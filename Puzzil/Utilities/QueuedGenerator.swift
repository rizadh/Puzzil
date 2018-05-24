//
//  QueuedGenerator.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-05-23.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

class QueuedGenerator<Element> {
    typealias GeneratorBlock = () -> Element?

    private let accessQueue = DispatchQueue(label: "com.rizadh.Puzzil.QueuedGenerator.accessQueue", qos: .userInitiated)
    private let generatorQueue = DispatchQueue(label: "com.rizadh.Puzzil.QueuedGenerator.generatorQueue", qos: .userInitiated)
    private let generatorBlock: GeneratorBlock
    private var queuedElements = [Element]()
    private let generatorSemaphore: DispatchSemaphore

    init(queueLength: Int = 5, _ generatorBlock: @escaping GeneratorBlock) {
        self.generatorBlock = generatorBlock
        generatorSemaphore = DispatchSemaphore(value: queueLength)

        generatorQueue.async { self.populateQueue() }
    }

    private func populateQueue() {
        if let element = generatorBlock() {
            generatorSemaphore.wait()
            accessQueue.async {
                self.queuedElements.append(element)
            }
        }

        populateQueue()
    }

    func next() -> Element {
        var element: Element!

        accessQueue.sync {
            element = queuedElements.removeLast()
        }

        generatorSemaphore.signal()

        return element
    }
}
