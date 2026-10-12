# Wallet

**Your Money, Your Rhythm.**

Wallet is a native iOS personal finance app built with **Swift** and **SwiftUI**. Its goal is to make everyday expense tracking simple and help people understand how much they can comfortably spend.

> Track what you've spent. Plan what you can spend.

## Why Wallet?

Everyday expense tracking often breaks down because recording a purchase takes too many steps, past transactions are inconvenient to add, and generic categories don't match how people actually spend. Wallet starts with frictionless recording, then grows into practical spending planning.

## Product Direction

- **Quick expense entry:** amount, category, and date, with as few steps as possible.
- **Calendar-based entry:** select a day and add a transaction directly to that date.
- **Flexible categories:** choose from suggested category templates, rename them, and eventually manage custom categories.
- **Currency preference:** choose a default currency (such as CAD or CNY) without forced conversion. Historical amounts must keep their original currency meaning.
- **Monthly insights:** review spending by calendar month.
- **Spending planning:** use income, payday cadence, fixed expenses, and optional savings targets to estimate what remains available.
- **Reimbursements:** distinguish money paid back by friends from income and show net spending.

These are **planned capabilities**, not a list of features already implemented.

## Tech Stack

| Area | Technology |
| --- | --- |
| Platform | iOS |
| Language | Swift |
| UI | SwiftUI |
| Architecture | Feature-first; lightweight MVVM where useful |
| Local persistence | SwiftData (planned) |
| IDE | Xcode |
| Version control | Git and GitHub |

## Roadmap

| Milestone | Goal | Status |
| --- | --- | --- |
| M0 · Foundation | Xcode setup, basic SwiftUI screen, project structure, README | In progress |
| V0.0 · Record | Add an expense, persist it locally, and see it after relaunch | Planned |
| V0.1 · Track | Edit/delete, custom categories, calendar backdating, quick add, monthly overview | Planned |
| V0.2 · Plan | Income, payday settings, fixed expenses, savings targets, estimated spendable money, reimbursements | Planned |
| V0.3 · Anticipate | Recurring obligations and upcoming expenses | Planned |
| V1.0 · Release | Refined UX, testing, accessibility, data protection/backup strategy, public iOS release | Future |

The first functional milestone is intentionally small: **Add → Save → Relaunch → View**.

## Project Structure

```text
Wallet/
├── WalletApp.swift
├── Features/
│   └── Home/
│       └── HomeView.swift
└── Assets.xcassets

WalletTests/
WalletUITests/
```

Additional folders and layers will be added when actual features need them.

## Getting Started

1. Install Xcode with an iOS Simulator runtime.
2. Clone this repository:
   ```bash
   git clone https://github.com/1chen011/wallet-ios.git
   ```
3. Open `Wallet.xcodeproj` in Xcode.
4. Select an available iPhone simulator.
5. Press **⌘R** to build and run.

## Development Principles

- Ship small, working vertical slices.
- Keep `main` buildable; develop changes on feature branches and review them through pull requests.
- Make transaction entry reliable before investing in analytics.
- Prefer transparent, deterministic calculations over AI for financial planning.
- Learn through building: understand, test, and explain key code decisions.
- Use the app in real life before expanding scope.

## Current Status

**Early development.** The Xcode project has been initialized, pushed to GitHub, and launched in an iPhone Simulator. The initial home screen and project structure are being prepared. Expense recording and persistence are **not implemented yet**.
