//
//  TabBarController.swift
//  healthyisme
//
//  Created by Haryanto Salim on 15/11/19.
//  Copyright © 2019 Haryanto Salim. All rights reserved.
//

import UIKit
import CareKit

class TabBarController: UITabBarController {
    
    lazy var carePlanStore: OCKCarePlanStore = {
        //store’s instantiation closure
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let url = urls[0].appendingPathComponent("carePlanStore")
        
        if !fileManager.fileExists(atPath: url.path) {
            try! fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        
        return OCKCarePlanStore(persistenceDirectoryURL: url)
    }()
    
    
    let activityStartDate = DateComponents(year: 2016, month: 1, day: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let careCard = OCKCareCardViewController(carePlanStore: carePlanStore)
        careCard.title = "Care"
        let symptomTracker = OCKSymptomTrackerViewController(carePlanStore: carePlanStore)
        symptomTracker.title = "Measurements"
        
        viewControllers = [
            UINavigationController(rootViewController: careCard),
            UINavigationController(rootViewController: symptomTracker)
        ]
        
        addActivities()
        
        symptomTracker.delegate = self
    }
    
    func interventions() -> [OCKCarePlanActivity] {
        
        let waterSchedule = OCKCareSchedule.dailySchedule(withStartDate: activityStartDate, occurrencesPerDay: 8)
        let waterIntervention = OCKCarePlanActivity.intervention(withIdentifier: "water", groupIdentifier: nil, title: "Water", text: "Number of glasses", tintColor: .blue, instructions: nil, imageURL: nil, schedule: waterSchedule, userInfo: nil, optional: false)
        
        let exerciseSchedule = OCKCareSchedule.dailySchedule(withStartDate: activityStartDate, occurrencesPerDay: 1, daysToSkip: 1, endDate: nil)
        let exerciseIntervention = OCKCarePlanActivity.intervention(withIdentifier: "exercise", groupIdentifier: nil, title: "Exercise", text: "30 min", tintColor: .orange, instructions: nil, imageURL: nil, schedule: exerciseSchedule, userInfo: nil, optional: false)
        
        return [waterIntervention, exerciseIntervention]
    }
    
    func assessments() -> [OCKCarePlanActivity] {
        
        let oncePerDaySchedule = OCKCareSchedule.dailySchedule(withStartDate: activityStartDate, occurrencesPerDay: 1)
        
        let sleepAssessment = OCKCarePlanActivity.assessment(withIdentifier: "sleep", groupIdentifier: nil, title: "Sleep", text: "How many hours did you sleep last night?", tintColor: .purple, resultResettable: true, schedule: oncePerDaySchedule, userInfo: nil, optional: false)
        
        let weightAssessment = OCKCarePlanActivity.assessment(withIdentifier: "weight", groupIdentifier: nil, title: "Weight", text: "How much do you weigh?", tintColor: .brown, resultResettable: true, schedule: oncePerDaySchedule, userInfo: nil, optional: false)
        
        return [sleepAssessment, weightAssessment]
    }
    
    
    func addActivities(){
        
        carePlanStore.activities { (_, activities, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            guard activities.count == 0 else {return}
            
            for activity in self.interventions() + self.assessments(){
                self.carePlanStore.add(activity) { (_, error) in
                    guard let error = error else {return}
                    print(error.localizedDescription)
                }
            }
        }
        
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension TabBarController: OCKSymptomTrackerViewControllerDelegate{
    func symptomTrackerViewController(_ viewController: OCKSymptomTrackerViewController, didSelectRowWithAssessmentEvent assessmentEvent: OCKCarePlanEvent) {
        let alert: UIAlertController
        
        if assessmentEvent.activity.identifier == "sleep" {
            alert = sleepAlert(event: assessmentEvent)
        } else if assessmentEvent.activity.identifier == "weight" {
            alert = weightAlert(event: assessmentEvent)
        } else {
            return
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func sleepAlert(event: OCKCarePlanEvent)->UIAlertController{
        //create the alert
        let alert = UIAlertController(title: "Sleep", message: "How many hours did you sleep last night?", preferredStyle: .alert)
        //add textfield to the alert
        alert.addTextField { (textField) in
            textField.keyboardType = .numberPad
        }
        //create action
        let doneAction = UIAlertAction(title: "Done", style: .default) { (action) in
            let sleepField = alert.textFields![0]
            let result = OCKCarePlanEventResult(valueString: sleepField.text!
                , unitString: "hours", userInfo: nil)
            self.carePlanStore.update(event, with: result, state: .completed) { (_, _, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
        //add action to alert
        alert.addAction(doneAction)
        return alert
    }
    
    func weightAlert(event: OCKCarePlanEvent) -> UIAlertController {
        let alert = UIAlertController(title: "Weight", message: "How much do you weigh (in kilograms)?", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.keyboardType = .numberPad
        }
        let doneAction = UIAlertAction(title: "Done", style: .default) { [unowned self] _ in
            let weightField = alert.textFields![0]
            let result = OCKCarePlanEventResult(valueString: weightField.text!, unitString: "kg", userInfo: nil)
            self.carePlanStore.update(event, with: result, state: .completed) { (_, _, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
        alert.addAction(doneAction)
        
        return alert
    }

}
