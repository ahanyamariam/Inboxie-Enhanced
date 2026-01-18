# Inboxie  
**An Action-Intelligent Email Client for Reducing Missed Follow-ups and Deadlines**

---

## Abstract

Inboxie is a multi-provider email client that augments traditional email interfaces with an action-intelligence layer designed to reduce missed follow-ups, overlooked requests, and unmanaged deadlines. Rather than prioritizing chronological ordering, the system surfaces emails based on inferred intent, urgency, and required user action. The application emphasizes explainability, user control, and privacy-aware processing, enabling users to understand *why* an email is flagged and how prioritization decisions are made.

---

## Project Objectives

The primary objectives of Inboxie are as follows:

- To identify emails that require user action using rule-based and AI-assisted intent detection  
- To prevent missed replies, follow-ups, and time-sensitive tasks  
- To present prioritization decisions in an explainable and transparent manner  
- To organize emails by human-readable intent (e.g., needs reply, waiting on others)  
- To provide customizable labels and buckets adaptable to individual user workflows  
- To maintain strong privacy guarantees through configurable data storage modes  

---

## Scope and MVP Focus

The Minimum Viable Product (MVP) focuses on the following scope:

- Gmail integration as the initial email provider  
- Identification and surfacing of emails that require action  
- A dedicated “Needs Action” view distinct from a traditional inbox  
- Rule-based intelligence with limited AI augmentation  
- Explainable recommendations through transparent triggers  
- User-configurable priority sensitivity and basic label customization  

Support for additional email providers, advanced machine learning pipelines, and full rule-mapping interfaces are explicitly out of scope for the MVP phase.

---

## Core Features (MVP)

### 1. Action-Centric Inbox
- Dedicated “Needs Action” panel displaying a limited set of high-priority emails  
- Priority inbox with summary lines and action labels  
- Quick actions: reply, snooze, mark as done, mute sender  

### 2. Explainability and Trust
- “Why recommended?” explanations for every flagged email  
- Human-readable triggers such as:
  - Direct questions
  - Unanswered threads
  - Deadlines or time-sensitive language
  - Waiting-for-response conditions  
- Confidence indicators for inferred actions  

### 3. Intent-Based Buckets
Default buckets include:
- Needs Reply  
- Waiting on Others  
- Calendar-worthy  
- Bills & Receipts  
- Low Value / Newsletters  

### 4. Privacy Controls
Users may select one of the following data-handling modes:
- Process-only (no storage)  
- Metadata and summaries only (recommended)  
- Full email text storage (optional)  

---

## System Architecture

### Frontend
- Flutter (cross-platform mobile framework)
- Material Design 3
- Reactive state management

### Backend
- Firebase Authentication (Google Sign-In)
- Cloud Firestore (email metadata, user settings)
- Cloud Functions (email processing and intelligence logic)
- Firebase Scheduler (follow-up reminders and periodic checks)

### Email Integration
- Gmail API (read-only access for MVP)
- Incremental synchronization of recent messages

### Intelligence Layer
- Rule-based intent detection (primary)
- Optional LLM-based summarization and draft assistance
- Structured outputs with explainable signals

---

## Data Model Overview

High-level Firestore structure:

```

users/
└── {userId}/
├── profile/
├── settings/
├── emails/
└── threads/

```

Only metadata and derived intelligence outputs are stored by default. Full email content is stored only when explicitly enabled by the user.

---

## Project Setup (Development)

### Prerequisites
- Flutter (stable channel)
- Android Studio
- Firebase CLI
- Node.js (for Cloud Functions)

### Initial Setup
1. Clone the repository  
2. Configure Firebase for the project  
3. Add platform-specific Firebase configuration files (not committed to version control)  
4. Enable Google Sign-In and Gmail API access  
5. Run the application locally using Flutter tooling  

---

## Collaboration and Version Control

The project follows a structured Git workflow:

- `main` — stable, demo-ready branch  
- `dev` — integration branch  
- `feature/*` — task-specific development branches  

All changes are introduced via pull requests with mandatory review. Direct commits to the main branch are restricted.

---

## Ethical and Privacy Considerations

Inboxie is designed with the following principles:

- No automated replies are sent without explicit user action  
- All prioritization decisions are explainable to the user  
- Data storage is minimized and configurable  
- Email content is never shared with third parties without consent  

These principles are enforced at both the architectural and interface levels.

---

## Development Timeline

The MVP is developed over a structured seven-week timeline:

- Week 1: Project setup, authentication, Gmail integration  
- Week 2: Core UI and inbox rendering  
- Week 3: Action and intent detection logic  
- Week 4: User actions and thread state management  
- Week 5: Buckets and low-value filtering  
- Week 6: Explainability and AI-assisted features  
- Week 7: UX refinement, testing, and demonstration  

---

## Status

The project is under active development. Features and architecture are subject to change as the MVP evolves.
