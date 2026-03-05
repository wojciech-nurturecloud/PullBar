//
//  GeneralTab.swift
//  issueBar
//
//  Created by Pavel Makhov on 2021-11-14.
//

import SwiftUI
import Defaults
import KeychainAccess
import LaunchAtLogin

struct PreferencesView: View {

    @Default(.githubApiBaseUrl) var githubApiBaseUrl
    @Default(.githubUsername) var githubUsername
    @Default(.githubAdditionalQuery) var githubAdditionalQuery
    @Default(.excludeDependabot) var excludeDependabot
    @Default(.excludeAlreadyReviewed) var excludeAlreadyReviewed
    @Default(.excludeAlreadyApproved) var excludeAlreadyApproved
    @Default(.highlightIconEnabled) var highlightIconEnabled
    @Default(.highlightIconThreshold) var highlightIconThreshold
    @Default(.highlightOldPRsEnabled) var highlightOldPRsEnabled
    @Default(.highlightOldPRsMinutes) var highlightOldPRsMinutes
    @Default(.excludedAuthors) var excludedAuthors
    @FromKeychain(.githubToken) var githubToken

    @Default(.showAssigned) var showAssigned
    @Default(.showCreated) var showCreated
    @Default(.showRequested) var showRequested

    @Default(.showAvatar) var showAvatar
    @Default(.showLabels) var showLabels

    @Default(.refreshRate) var refreshRate
    @Default(.buildType) var builtType
    @Default(.counterType) var counterType

    @State private var showGhAlert = false

    @StateObject private var githubTokenValidator = GithubTokenValidator()
//    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    
    @State private var isExpanded: Bool = false

    private func row<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .frame(width: 140, alignment: .trailing)
            content()
        }
    }

    var body: some View {

        TabView {
            VStack(alignment: .leading, spacing: 10) {
                row("Pull Requests:") {
                    VStack(alignment: .leading) {
                        Toggle("assigned", isOn: $showAssigned)
                        Toggle("created", isOn: $showCreated)
                        Toggle("review requested", isOn: $showRequested)
                    }
                }
                row("Build Information:") {
                    Picker("", selection: $builtType) {
                        ForEach(BuildType.allCases) { bt in
                            Text(bt.description)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(RadioGroupPickerStyle())
                }
                row("Show Avatar:") { Toggle("", isOn: $showAvatar) }
                row("Show Labels:") { Toggle("", isOn: $showLabels) }
                row("Refresh Rate:") {
                    Picker("", selection: $refreshRate) {
                        Text("1 minute").tag(1)
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                    }.labelsHidden()
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 100)
                }
                row("Launch at login:") {
                    LaunchAtLogin.Toggle { Text("") }
                }
                row("Filters:") {
                    VStack(alignment: .leading) {
                        Toggle("Exclude Dependabot PRs", isOn: $excludeDependabot)
                        Toggle("Exclude reviewed by me", isOn: $excludeAlreadyReviewed)
                        Toggle("Exclude approved PRs", isOn: $excludeAlreadyApproved)
                    }
                }
                row("Highlight icon:") {
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("PRs exceed threshold", isOn: $highlightIconEnabled)
                        HStack {
                            Text("Threshold:")
                            Picker("", selection: $highlightIconThreshold) {
                                Text("1").tag(1)
                                Text("2").tag(2)
                                Text("3").tag(3)
                                Text("5").tag(5)
                                Text("10").tag(10)
                            }
                            .labelsHidden()
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 60)
                            .disabled(!highlightIconEnabled)
                        }
                        Toggle("Any PR older than", isOn: $highlightOldPRsEnabled)
                        HStack {
                            Text("Age (min):")
                            TextField("", value: $highlightOldPRsMinutes, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 60)
                                .disabled(!highlightOldPRsEnabled)
                        }
                        Button("Preview") {
                            NotificationCenter.default.post(name: .previewHighlight, object: nil)
                        }
                        .disabled(!highlightIconEnabled && !highlightOldPRsEnabled)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .tabItem{Text("General")}

            Form {
                HStack(alignment: .center) {
                    Text("API Base URL:").frame(width: 140, alignment: .trailing)
                    TextField("", text: $githubApiBaseUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .textContentType(.password)
                        .frame(width: 200)
                }
                HStack(alignment: .center) {
                    Text("Username:").frame(width: 140, alignment: .trailing)
                    TextField("", text: $githubUsername)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .textContentType(.password)
                        .frame(width: 200)
                }

                HStack(alignment: .center) {
                    Text("Token:").frame(width: 140, alignment: .trailing)
                    VStack(alignment: .leading) {
                        HStack() {
                            SecureField("", text: $githubToken)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .overlay(
                                    Image(systemName: githubTokenValidator.iconName).foregroundColor(githubTokenValidator.iconColor)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .padding(.trailing, 8)
                                )
                                .frame(width: 380)
                                .onChange(of: githubToken) { _ in
                                    githubTokenValidator.validate()
                                }
                            Button {
                                githubTokenValidator.validate()
                            } label: {
                                Image(systemName: "repeat")
                            }
                            .help("Retry")
                        }
                        Text("[Generate](https://github.com/settings/tokens/new?scopes=repo) a personal access token, make sure to select **repo** scope")
                            .font(.footnote)
                            .padding(.leading, 8)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .onAppear() {
                githubTokenValidator.validate()
            }
            .tabItem{Text("Authentication")}

            Form {
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text("Counter:")
                        Text("Number of pull requests next to the icon")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Picker("", selection: $counterType, content: {
                        ForEach(CounterType.allCases) { bt in
                            Text(bt.description)
                        }
                    })
                    .labelsHidden()
                    .pickerStyle(RadioGroupPickerStyle())
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .tabItem{Text("Menubar icon")}

            Form {
                HStack(alignment: .top) {
                    Text("Exclude Authors:").frame(width: 140, alignment: .trailing)
                    VStack(alignment: .leading) {
                        TextField("", text: $excludedAuthors, prompt: Text("user1, user2"))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disableAutocorrection(true)
                            .frame(width: 300)
                        Text("Comma-separated GitHub usernames")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(alignment: .top) {
                    Text("Additional Query:").frame(width: 140, alignment: .trailing)
                    VStack(alignment: .leading) {
                        TextField("", text: $githubAdditionalQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disableAutocorrection(true)
                            .frame(width: 300)
                        Text("[Search docs](https://docs.github.com/en/search-github/getting-started-with-searching-on-github/understanding-the-search-syntax)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }.padding(8)
                .frame(maxWidth: .infinity)
                .tabItem{Text("Advanced")}

        }
        .frame(width: 600)
        .padding()

    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
