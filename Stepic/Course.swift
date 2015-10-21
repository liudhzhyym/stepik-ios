//
//  Course.swift
//  
//
//  Created by Alexander Karpov on 25.09.15.
//
//

import Foundation
import CoreData
import SwiftyJSON

@objc
class Course: NSManagedObject, JSONInitializable {

// Insert code here to add functionality to your managed object subclass
    
    convenience required init(json: JSON) {
        self.init()
        initialize(json)
    }

    func initialize(json: JSON) {
        id = json["id"].intValue
        title = json["title"].stringValue
        courseDescription = json["description"].stringValue
        coverURLString = Constants.stepicURLString + json["cover"].stringValue
        
        beginDate = Parser.sharedParser.dateFromTimedateJSON(json["begin_date_source"])
        endDate = Parser.sharedParser.dateFromTimedateJSON(json["last_deadline"])
        
        enrolled = json["enrollment"].int != nil
        featured = json["is_featured"].boolValue
        
        summary = json["summary"].stringValue
        workload = json["workload"].stringValue
        introURL = json["intro"].stringValue
        format = json["course_format"].stringValue
        audience = json["target_audience"].stringValue
        certificate = json["certificate"].stringValue
        requirements = json["requirements"].stringValue
        
        sectionsArray = json["sections"].arrayObject as! [Int]
        instructorsArray = json["instructors"].arrayObject as! [Int]
    }
    
    
    func update(json json: JSON) {
        id = json["id"].intValue
        title = json["title"].stringValue
        courseDescription = json["description"].stringValue
        coverURLString = Constants.stepicURLString + json["cover"].stringValue
        
        beginDate = Parser.sharedParser.dateFromTimedateJSON(json["begin_date_source"])
        endDate = Parser.sharedParser.dateFromTimedateJSON(json["last_deadline"])
        
        enrolled = json["enrollment"].int != nil
        featured = json["is_featured"].boolValue
        
        summary = json["summary"].stringValue
        workload = json["workload"].stringValue
        introURL = json["intro"].stringValue
        format = json["course_format"].stringValue
        audience = json["target_audience"].stringValue
        certificate = json["certificate"].stringValue
        requirements = json["requirements"].stringValue
        
        sectionsArray = json["sections"].arrayObject as! [Int]
        instructorsArray = json["instructors"].arrayObject as! [Int]
    }
    
    
    convenience init(json: JSON, tabNumber: Int) {
        self.init(json: json)
        self.tabNumber = tabNumber
    }
        
    func loadAllInstructors(success success: (Void -> Void)) {
        AuthentificationManager.sharedManager.autoRefreshToken(success: {
            ApiDataDownloader.sharedDownloader.getUsersByIds(self.instructorsArray, deleteUsers: self.instructors, refreshMode: .Update, success: {
                users in
//                print("instructors count inside Course class -> \(users.count)")
                self.instructors = users
                CoreDataHelper.instance.save()
                success()  
                }, failure : {
                    error in
                    print("error while loading section")
            })
        })        
    }
    
    func loadAllSections(success success: (Void -> Void)) {
        AuthentificationManager.sharedManager.autoRefreshToken(success: {
            ApiDataDownloader.sharedDownloader.getSectionsByIds(self.sectionsArray, existingSections: self.sections, refreshMode: .Update, success: {
                    secs in
                    self.sections = secs
                    CoreDataHelper.instance.save()
                    success()  
                }, failure : {
                        error in
                        print("error while loading section")
                })
        })        
    }
    
    class func getCourses(featured: Bool? = nil, enrolled: Bool? = nil, tabNumber: Int) throws -> [Course] {
        let request = NSFetchRequest(entityName: "Course")
        let descriptor = NSSortDescriptor(key: "managedId", ascending: false)
        var predicate = NSPredicate(value: true)
        
        let p = NSPredicate(format: "managedTabNumber == %@", tabNumber as NSNumber)
        predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [predicate, p]) 
        
        if let f = featured {
            let p = NSPredicate(format: "managedFeatured == %@", f as NSNumber)
            predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [predicate, p])
        }
        
        if let e = enrolled {
            let p = NSPredicate(format: "managedEnrolled == %@", e as NSNumber)
            predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [predicate, p])
        }
        
        request.predicate = predicate
        request.sortDescriptors = [descriptor]
        
        do {
            let results = try CoreDataHelper.instance.context.executeFetchRequest(request)
            return results as! [Course]
        }
        catch {
            throw FetchError.RequestExecution
        }
    }
    
    class func deleteAll(tabNumber: Int) {
        do {
            let c = try getCourses(tabNumber: tabNumber)
            for course in c {
                CoreDataHelper.instance.deleteBeforeAppFinish(course)
            }
        }
        catch {
            print("Error while deleting course objects")
        }    
    }
}

extension NSTimeInterval {
    init(timeString: String) {
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        formatter.locale = NSLocale(localeIdentifier: "en_US")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        self = formatter.dateFromString(timeString)!.timeIntervalSince1970
    }
}