//  Created on 2022/7/5.

import UIKit

class LMRError: Error {
    var description: String
    
    init(_ description: String) {
        self.description = description
    }
}

func LMRAssert(_ value: Bool, _ info: String) throws {
    if !value {
        NSLog("asset fail: %@", info)
        throw LMRError(info)
    }
}
