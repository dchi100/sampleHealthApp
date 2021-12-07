//
//  ViewController.swift
//  sampleHealthApp
//
//  Created by Daniel Chi on 10/18/21.
//

import UIKit
import HealthKit



class ViewController: UIViewController {
    let healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit(from: "count/min")
        
    private var value = 0

    override func viewDidLoad() {
        super.viewDidLoad()
            // Do any additional setup after loading the view.
        authoriseHealthKitAccess()
    }
    
    func authoriseHealthKitAccess() {
        let healthKitTypes: Set = [
                // access step count
                HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
                //access heart rate
                HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
            ]

        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { (check, error) in
            if(check){
                print("Successfully authorized!")
                self.latestHeartRate()
            }
        }

    }

    func getTodaysSteps(completion: @escaping (Double) -> Void) {
        
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            var resultCount = 0.0
            guard let result = result else {
                print("Failed to fetch steps rate")
                completion(resultCount)
                return
            }
            if let sum = result.sumQuantity() {
                resultCount = sum.doubleValue(for: HKUnit.count())
            }
            
            DispatchQueue.main.async {
                completion(resultCount)
            }
        }
        healthStore.execute(query)
    }
    
    @IBOutlet weak var totalSteps: UILabel!
    @IBAction func getTotalSteps(_ sender: Any) {
        getTodaysSteps { (result) in
            print("\(result)")
            DispatchQueue.main.async {
                self.totalSteps.text = "\(result)"
            }
        }
    }
            
    @IBOutlet weak var heartRate: UILabel!
    
    func latestHeartRate(){
        guard let sampleType = HKObjectType.quantityType(forIdentifier: .heartRate) else{
            return
        }
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { (sample, result, error) in
            guard error == nil else{
                return
            }
            
            let data = result![0] as! HKQuantitySample
            let unit = HKUnit(from: "count/min")
            let latestHr = data.quantity.doubleValue(for: unit)
            
            self.value = Int(latestHr)
            self.heartRate.text = "Latest heart rate: \(self.value)"
            
        }
        
        healthStore.execute(query)
    }
    
//    private func startHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
//
//        // We want data points from our current device
//        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
//
//        // A query that returns changes to the HealthKit store, including a snapshot of new changes and continuous monitoring as a long-running query.
//        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
//                query, samples, deletedObjects, queryAnchor, error in
//
//            // A sample that represents a quantity, including the value and the units.
//            guard let samples = samples as? [HKQuantitySample] else {
//                return
//            }
//
//
//
//            self.process(samples, type: quantityTypeIdentifier)
//        }
//
//        // It provides us with both the ability to receive a snapshot of data, and then on subsequent calls, a snapshot of what has changed.
//        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!, predicate: devicePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
//
//        query.updateHandler = updateHandler
//
//        // query execution
//        healthStore.execute(query)
//
//    }
//
//    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
//                        // variable initialization
//            var lastHeartRate = 0.0
//
//            // cycle and value assignment
//            for sample in samples {
//                if type == .heartRate {lastHeartRate = sample.quantity.doubleValue(for: heartRateQuantity)}
//
//                    self.value = Int(lastHeartRate)
//
//                    self.heartRate.text = "\(value)"
//        }
//    }
}







