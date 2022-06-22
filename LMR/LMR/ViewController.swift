//  Created on 2022/6/22.

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        

    }

    @IBAction func clickSample(_ sender: Any) {
        let vc = LMRSampleVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func clickSample3D(_ sender: Any) {
        let vc = LMRSample3DVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

