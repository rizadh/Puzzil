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

    private let generatorBlock: GeneratorBlock
    private var queue = [Element]()
    private let elementAvailable = DispatchSemaphore(value: 0)
    private let queueLock = DispatchSemaphore(value: 1)
    private let generationQueue: DispatchQueue
    init(name: String, queueLength: Int, _ generatorBlock: @escaping GeneratorBlock) {
        self.generatorBlock = generatorBlock
        generationQueue =
            DispatchQueue(label: "com.rizadh.Puzzil.QueuedGenerator.generationQueue.\(name)", qos: .utility)

        for _ in 0..<queueLength { populateQueue() }
    }

    private func populateQueue() {
        generationQueue.async {
            var element: Element!

            while element == nil {
                element = self.generatorBlock()
            }

            self.queueLock.wait()
            self.queue.append(element)
            self.queueLock.signal()
            self.elementAvailable.signal()
        }
    }

    func next() -> Element {
        elementAvailable.wait()
        populateQueue()

        queueLock.wait()
        let element = queue.removeLast()
        queueLock.signal()

        return element
    }

    func wait() {
        elementAvailable.wait()
        elementAvailable.signal()
    }
}
