//
//  Unit.swift
//  Stepic
//
//  Created by Alexander Karpov on 09.10.15.
//  Copyright © 2015 Alex Karpov. All rights reserved.
//

import CoreData
import Foundation
import SwiftyJSON

final class Unit: NSManagedObject, IDFetchable {
    typealias IdType = Int

    required convenience init(json: JSON) {
        self.init()
        initialize(json)
    }

    func initialize(_ json: JSON) {
        id = json["id"].intValue
        position = json["position"].intValue
        isActive = json["is_active"].boolValue
        lessonId = json["lesson"].intValue
        progressId = json["progress"].string
        sectionId = json["section"].intValue

        assignmentsArray = json["assignments"].arrayObject as! [Int]

        beginDate = Parser.shared.dateFromTimedateJSON(json["begin_date"])
        softDeadline = Parser.shared.dateFromTimedateJSON(json["soft_deadline"])
        hardDeadline = Parser.shared.dateFromTimedateJSON(json["hard_deadline"])
    }

    func update(json: JSON) {
        initialize(json)
    }

    func loadAssignments(_ completion: @escaping (() -> Void), errorHandler: @escaping (() -> Void)) {
        _ = ApiDataDownloader.assignments.retrieve(ids: self.assignmentsArray, existing: self.assignments, refreshMode: .update, success: {
            newAssignments in
            self.assignments = Sorter.sort(newAssignments, byIds: self.assignmentsArray)
            completion()
            }, error: {
                _ in
                print("Error while downloading assignments")
                errorHandler()
        })
   }

    static func getUnit(id: Int) -> Unit? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Unit")

        let predicate = NSPredicate(format: "managedId== %@", id as NSNumber)

        request.predicate = predicate

        do {
            let results = try CoreDataHelper.shared.context.fetch(request)
            if results.count > 1 {
                print("CORE DATA WARNING: More than 1 unit with id \(id)")
            }
            return (results as? [Unit])?.first
        } catch {
            return nil
        }
    }

    static func fetch(_ ids: [Int]) -> [Unit] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Unit")

        let idPredicates = ids.map {
            NSPredicate(format: "managedId == %@", $0 as NSNumber)
        }
        request.predicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.or, subpredicates: idPredicates)
        do {
            guard let results = try CoreDataHelper.shared.context.fetch(request) as? [Unit] else {
                return []
            }
            return results
        } catch {
            return []
        }
    }
}

extension Unit: NextLessonServiceUnitSourceProtocol {
    var uniqueIdentifier: UniqueIdentifierType { "\(self.id)" }
}
