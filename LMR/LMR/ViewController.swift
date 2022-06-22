//  Created on 2022/6/22.

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let sampleVC = LMRSampleVC()
        self.navigationController?.pushViewController(sampleVC, animated: true)
    }


}

