//
//  PromptInput.swift
//  PlaygroundStudio
//
//  Created by User on 21/11/25.
//


import Foundation

struct PromptInput: Identifiable, Codable, Hashable {
    var id = UUID()
    var generalPrompt: String
    var learningObjective: String
    var targetSchoolLevel: String
    var availableAssets: String
    var teacherOrParentIntent: String
    
    public var finalPrompt: String {
        """
        \(generalPrompt)
        
        With Specific Learning Objective: \(learningObjective)
        
        Target School level of: \(targetSchoolLevel)
        
        This playground book intended for: \(teacherOrParentIntent)
        
        """
    }

    init(generalPrompt: String = "",
        learningObjective: String = "",
         targetSchoolLevel: String = "",
         availableAssets: String = "",
         teacherOrParentIntent: String = "") {
        self.generalPrompt = generalPrompt
        self.learningObjective = learningObjective
        self.targetSchoolLevel = targetSchoolLevel
        self.availableAssets = availableAssets
        self.teacherOrParentIntent = teacherOrParentIntent
    }
    
    
}
