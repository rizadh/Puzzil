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

    private let generationQueue: DispatchQueue
    private let generatorBlock: GeneratorBlock
    private var queue = [Element]()
    private let elementRequired: DispatchSemaphore
    private let elementAvailable = DispatchSemaphore(value: 0)
    private let queueLock = DispatchSemaphore(value: 1)

    init(name: String, queueLength: Int, _ generatorBlock: @escaping GeneratorBlock) {
        self.generatorBlock = generatorBlock
        generationQueue = DispatchQueue(label: "com.rizadh.Puzzil.QueuedGenerator.generationQueue.\(name)", qos: .utility)
        elementRequired = DispatchSemaphore(value: queueLength)

        generationQueue.async {
            while true { self.populateQueue() }
        }
    }

    private func populateQueue() {
        if let element = generatorBlock() {
            elementRequired.wait()
            queueLock.wait()
            queue.append(element)
            queueLock.signal()
            elementAvailable.signal()
        }
    }

    func next() -> Element {
        elementAvailable.wait()
        elementRequired.signal()

        queueLock.wait()
        let element = queue.removeLast()
        queueLock.signal()

        return element
    }
}
