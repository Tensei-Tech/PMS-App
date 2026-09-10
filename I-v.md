Build a modern, professional **Police Criminal Case Management System** based on the following workflow:

**FIR Registration → Persons & Property → Investigation → Arrest/Custody/Bail → Evidence → Charge Sheet/Final Report → Court Trial → Verdict → Case Closure → Scrutiny/Prosecution**

The application should be designed as a **case lifecycle management system**, not just a single long form.

### 1. Dashboard

Create a dashboard showing:

* Total FIRs/Cases
* Active Investigations
* Cases Pending Investigation
* Charge Sheets Pending
* Cases Under Court Trial
* Convicted Cases
* Acquitted Cases
* Closed Cases
* Cases requiring scrutiny/approval
* Recent case activity
* Upcoming deadlines/hearings

Include search and filters by:

* FIR/CR number
* Police station
* Act/Section
* Accused name
* Complainant name
* IO name
* Case status
* Registration date
* Court status

### 2. FIR / Case Registration

Create a case registration screen with:

* Serial Number
* C.R. / FIR Number
* Registered Date & Time
* Registered By
* Police Station
* Act
* Multiple Sections
* Crime Spot

  * Village/Town
  * Address
  * Area Name
* Brief description of offence

Acts and Sections should support searchable dropdowns and multiple selections.

### 3. Person / KYC Management

Create a reusable **Person/KYC profile** that can be attached to different roles within a case.

KYC fields:

* Full Name
* Age / Date of Birth
* Gender
* Occupation
* Mobile Number
* Address
* Identification/KYC details
* Photo
* Other relevant personal information

A single person record should be reusable as:

* Complainant
* Victim
* Injured
* Deceased
* Accused
* Suspect
* Witness
* Surety
* Relative

Do not duplicate the person's basic information when changing their role.

### 4. Case Persons

Allow adding multiple people under each category:

**Complainant**

* Person/KYC
* Statement/details

**Victim**

* Person/KYC
* Medical examination: Yes/No

**Injured**

* Person/KYC
* Medical examination: Yes/No
* Status transition: Ability to mark as "Deceased" if they succumb to injuries (prompts for Date of Death).

**Deceased**

* Person/KYC
* Death-related details
* Inquest/post-mortem information

**Accused**

* Person/KYC
* Accused status
* Arrest status
* Current custody/bail status
* Case Status Automation: If an accused is named, the case status should automatically become **"Detected"**. Otherwise, it remains **"Undetected"**.
* Repeat Offender Tagging: If the accused's profile already exists in another case within the **current police station's records**, automatically show a **"Repeat Offender"** badge.

**Suspected Person**

* Person/KYC
* Investigation status

**Unidentified Person (अनोळखी)**

* Temporary Name (e.g., ABCD, XYZ)
* Gender
* Approx Age
* Occupation (possible)
* Skin Color
* Description
* Name update (if known later)

**Unknown Person (अज्ञात)**

* Completely unknown (no physical description available).

### 5. Property Management

Create a property/evidence section:

* Stolen Property
* Property Description
* Quantity
* Identification/serial number
* Estimated value
* Recovery status
* Recovery Date
* Recovered From
* Seizure details
* Current custody/location

Support multiple property records per case.

### 6. Investigation

Create a chronological investigation timeline.

Support events such as:

* IO Assigned
* IO Changed
* Investigation activity
* Search
* Seizure
* Panchanama (Spot, Inquest, Identification, Search, Exhumation)
* Memorandum Panchanama (must explicitly link to a specific Accused)
* Identification
* Inquest
* Medical examination
* Fingerprint collection
* Technical/mobile investigation
* CDR request
* CDR received
* Other investigation activities

Each event should contain:

* Event type
* Date
* Time
* Location
* Officer
* Description
* Related person
* Related accused
* Related property/evidence
* Attachments/documents

### 7. Arrest & Notice

For every accused, track:

* Arrest status
* Arrest Date & Time
* Arrest location
* Arresting officer
* Relative name
* Relationship
* Notice issued
* Notice Date/Time
* Released on Notice
* Wanted/Absconding status

The accused's timeline should clearly show every status change.

### 8. Custody & Bail

Track accused-level custody information:

**PCR**

* Start date
* End date
* Number of days
* Court/order details

**MCR**

* Start date
* End date
* Number of days
* Jail

**Bail**

* Anticipatory Bail
* Regular Bail
* Bail Date
* Bail order/details

**PR Bond**

* Date
* Amount/details
* Status

**Surety**

* Person/KYC
* Relationship
* Bond details

### 9. Preventive Action

Create a preventive-action module supporting:

* Relevant legal sections such as 107/116 where applicable
* Date
* Outward Number
* Bond details
* Bond cancellation date
* Related person/accused

### 10. Charge Sheet / Final Report

Create a case completion section supporting:

* Charge Sheet Number
* Charge Sheet Date
* Accused included in charge sheet
* Discharged accused
* Final Report type

  * Charge Sheet
  * A Summary
  * B Summary
  * C Summary
  * NC-Final
  * Abated
  * Quashed by High Court
  * Other applicable disposal types

Accused should be selectable from the existing accused list rather than manually entered again.

### 11. Court / Trial

Create a court-tracking module.

Track:

* Court Name
* Case Number
* Filing Date
* Hearing dates
* Judge/Magistrate
* Charges framed
* Trial status
* Important orders
* Next hearing
* Case documents

For the final outcome, allow selecting existing accused and assigning:

* **Convicted**
* **Acquitted**
* **Discharged**
* Other applicable outcome

Record:

* Outcome date
* Judgment date
* Relevant order/document
* Remarks
* If **Convicted**, record specific sentence details:
  * Years
  * Months
  * Fine Amount

One FIR may contain multiple accused with different outcomes.

### 12. Scrutiny / Prosecution Workflow

Create a sequential approval workflow:

**Investigation Officer → Senior Police Officer/Scrutiny → Higher Officer → APP/Prosecution**

Each stage should have:

* Sent Date
* Received Date
* Grant/Approval Date
* Status
* Remarks
* Officer
* Attached documents

Show the current stage clearly.

### 13. Case Timeline

Every case should have a unified chronological timeline.

Example:

```text
FIR Registered
      ↓
IO Assigned
      ↓
Victim Added
      ↓
Accused Identified
      ↓
Search Conducted
      ↓
Evidence Seized
      ↓
Accused Arrested
      ↓
PCR
      ↓
MCR
      ↓
Bail
      ↓
Investigation Completed
      ↓
Charge Sheet Filed
      ↓
Court Trial
      ↓
Judgment
      ↓
Convicted / Acquitted
      ↓
Case Closed
```

The timeline should automatically update whenever an event is added.

### 14. Case Detail Page

Create a comprehensive case page with tabs:

1. Overview
2. FIR
3. Persons
4. Accused
5. Victims
6. Property
7. Investigation
8. Arrest
9. Custody & Bail
10. Evidence/Documents
11. Charge Sheet
12. Court
13. Scrutiny
14. Timeline
15. Audit Log

Display important case status at the top.

### 15. Documents & Attachments

Allow uploading and organizing documents such as:

* FIR
* Statements
* Panchanama
* Seizure documents
* Medical reports
* Fingerprint reports
* CDR documents
* Arrest documents
* Bail orders
* Charge sheet
* Court orders
* Judgment

Each document should be linked to the relevant case/person/event.

### 16. User Roles & Permissions

Implement role-based access control.

Example roles:

* Police Officer
* Investigating Officer
* Senior Officer
* Scrutiny Officer
* Prosecutor/APP
* Administrator

Users should only be able to view/edit information permitted by their role.

Maintain a complete **audit log** showing:

* Who created a record
* Who modified it
* What changed
* Date/time of change

### 17. UI/UX Requirements

Design the application as a professional **government/police enterprise system**.

Use:

* Clean dashboard
* Sidebar navigation
* Professional tables
* Cards for statistics
* Stepper/timeline components
* Tabs for case sections
* Modal/drawer forms where appropriate
* Searchable dropdowns
* Date/time pickers
* Status badges
* Confirmation dialogs
* Responsive design
* Clear validation messages

Avoid making the interface visually overwhelming. The large workflow should be broken into manageable screens and sections.

### 18. Data Architecture

Structure the backend around these main entities:

```text
User
PoliceStation
Case/FIR
Act
Section
Person
CasePerson
Accused
Victim
Injured
Deceased
Property
InvestigationEvent
Evidence
Arrest
Custody
Bail
Surety
PreventiveAction
ChargeSheet
CourtCase
CourtHearing
CourtOutcome
Scrutiny
Document
AuditLog
```

Important relationships:

```text
Case
 ├── Persons
 ├── Accused
 ├── Victims
 ├── Injured
 ├── Deceased
 ├── Property
 ├── Investigation Events
 ├── Evidence/Documents
 ├── Arrest/Custody/Bail
 ├── Charge Sheet
 ├── Court Case
 │    ├── Hearings
 │    └── Outcomes
 └── Scrutiny Workflow
```

### 19. Critical Requirement

Do **not** treat the application as one giant form.

The system must distinguish between:

* **Case-level information**
* **Person-level information**
* **Accused-level information**
* **Property/evidence-level information**
* **Investigation events**
* **Court-level information**
* **Case outcome**

A single FIR can contain multiple accused, and each accused can have a different journey and final outcome.

The system should therefore support **many-to-one and one-to-many relationships** and maintain a complete chronological history.

### 20. Goal

Build a system where a police officer can open any FIR and immediately understand:

**What happened → Who is involved → What investigation has been completed → What evidence exists → What happened to each accused → What is the current legal/court status → What action is pending → How the case ultimately ended.**

Use realistic sample data to demonstrate the complete workflow.
