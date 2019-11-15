//
//  ViewController.swift
//  healthyisme
//
//  Created by Haryanto Salim on 11/11/19.
//  Copyright © 2019 Haryanto Salim. All rights reserved.
//

import UIKit
//menggunakan framework health kit
import HealthKit
//menggunakan framework carekit dan research kit
import CareKit

class ViewController: UITableViewController {
    
    //create a healthStore
    var healthStore: HKHealthStore = HKHealthStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //request a permission
        requestPermission(healthStore)
        requestClinicalDataPermission(healthStore)
    }

    /**
     rewuset a permission
     */
    func requestPermission(_ healthStore: HKHealthStore){
        //if available healthData
        if HKHealthStore.isHealthDataAvailable() {
            // Add code to use HealthKit here.
            let allTypes = Set([HKObjectType.workoutType(),
                                HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
                                HKObjectType.quantityType(forIdentifier: .dietaryCholesterol)!, //totalCholesterol mmhg
                HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
                HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
                HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
                                HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
                                HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                                HKObjectType.quantityType(forIdentifier: .heartRate)!])

            healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in
                if !success {
                    // Handle the error here.
                }
            }
        }
    }
    
    func requestClinicalDataPermission(_ healthStore: HKHealthStore){
        if HKHealthStore.isHealthDataAvailable() {
            guard let allergiesType = HKObjectType.clinicalType(forIdentifier: .allergyRecord),
                let medicationsType = HKObjectType.clinicalType(forIdentifier: .medicationRecord) else {
                    fatalError("*** Unable to create the requested types ***")
            }
            
            // Clinical types are read-only.
            healthStore.requestAuthorization(toShare: nil, read: [allergiesType, medicationsType]) { (success, error) in
                
                guard success else {
                    // Handle errors here.
                    fatalError("*** An error occurred while requesting authorization: \(error!.localizedDescription) ***")
                }
                
                // You can start accessing clinical record data.
            }
        }
    }

    
    func queryClinicalHealthRecord(_ healthStore: HKHealthStore){
        // Get all the allergy records.
        guard let allergyType = HKObjectType.clinicalType(forIdentifier: .allergyRecord) else {
            fatalError("*** Unable to create the allergy type ***")
        }

        let allergyQuery = HKSampleQuery(sampleType: allergyType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            
            guard let actualSamples = samples else {
                // Handle the error here.
                print("*** An error occurred: \(error?.localizedDescription ?? "nil") ***")
                return
            }
            
            guard let allergySamples = actualSamples as? [HKClinicalRecord] else {
                print("no clinical record found")
                return
            }
            // Do something with the allergy samples here...
            
            for clinicalRecord in allergySamples{
                guard let fhirRecord = clinicalRecord.fhirResource else {
                    print("No FHIR record found!")
                    return
                }

                do {
                    let jsonDictionary = try JSONSerialization.jsonObject(with: fhirRecord.data, options: [])
                    
                    // Do something with the JSON data here.
//                    {
//                        "asserter": {
//                            "display": "Adam Gooseff",
//                            "reference": "Practitioner/20"
//                        },
//                        "category": {
//                            "coding": [
//                                {
//                                    "code": "diagnosis",
//                                    "system": "http://hl7.org/fhir/condition-category"
//                                }
//                            ]
//                        },
//                        "clinicalStatus": "active",
//                        "code": {
//                            "coding": [
//                                {
//                                    "code": "367498001",
//                                    "display": "Seasonal allergic rhinitis",
//                                    "system": "http://snomed.info/sct"
//                                }
//                            ],
//                            "text": "Seasonal Allergic Rhinitis"
//                        },
//                        "dateRecorded": "2012-01-02",
//                        "id": "2",
//                        "notes": "Worse when visiting family in NC during the spring",
//                        "onsetDateTime": "1994-05-12",
//                        "resourceType": "Condition",
//                        "verificationStatus": "confirmed"
//                    }
                }
                catch let error {
                    print("*** An error occurred while parsing the FHIR data: \(error.localizedDescription) ***")
                    // Handle JSON parse errors here.
                }
            }
        }

        healthStore.execute(allergyQuery)
    }
}

