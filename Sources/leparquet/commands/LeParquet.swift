//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import ArgumentParser
import Foundation

struct LeParquet: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "leparquet",
        abstract: "A tool to calculate parquet layout and material quantities.",
        discussion:
        """
        Terminology: Height is the same as width in parqute term.
        It is small side of of the board. Number of rows constitutes height of the layout.
        """,
        version: Version.value,
        subcommands: [
            Deck.self,
//            GenerateConfig.self,
        ]
//        defaultSubcommand: Version.self
    )
}
