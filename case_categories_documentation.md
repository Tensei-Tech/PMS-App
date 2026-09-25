# Case Categories, Acts, Sections & Form Templates Documentation

## 1. Robbery & Dacoity Legal Section Mapping (BNS 2023 vs. IPC 1860)

| Category / Offence Description | Act | BNS Section | Subsection | IPC Equivalent Section | Associated Form Template |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Robbery** (Definition - Theft causing hurt/fear) | BNS 2023 | **309** | **1** | IPC 390 | `Robbery Form Template` (ID: 4) |
| **Robbery** (Definition - Extortion with fear) | BNS 2023 | **309** | **2** | IPC 390 | `Robbery Form Template` (ID: 4) |
| **Robbery** (Definition - Restraint / Instant Hurt) | BNS 2023 | **309** | **3** | IPC 390 | `Robbery Form Template` (ID: 4) |
| **Robbery** (Punishment for Robbery) | BNS 2023 | **309** | **4** | IPC 392 | `Robbery Form Template` (ID: 4) |
| **Robbery** (Attempt to Commit Robbery) | BNS 2023 | **309** | **5** | IPC 393 | `Robbery Form Template` (ID: 4) |
| **Robbery** (Voluntarily Causing Hurt in Committing Robbery) | BNS 2023 | **309** | **6** | IPC 394 | `Robbery Form Template` (ID: 4) |
| **Dacoity** (Definition - 5 or more persons committing robbery) | BNS 2023 | **310** | **1** | IPC 391 | `Dacoity Form Template` (ID: 3) |
| **Dacoity** (Punishment for Dacoity) | BNS 2023 | **310** | **2** | IPC 395 | `Dacoity Form Template` (ID: 3) |
| **Dacoity** (Dacoity with Murder) | BNS 2023 | **310** | **3** | IPC 396 | `Dacoity Form Template` (ID: 3) |
| **Dacoity** (Making Preparation to Commit Dacoity) | BNS 2023 | **310** | **4** | IPC 399 | `Dacoity Form Template` (ID: 3) |
| **Dacoity** (Belonging to Gang of Dacoits) | BNS 2023 | **310** | **5** | IPC 400 | `Dacoity Form Template` (ID: 3) |
| **Dacoity** (Assembling for Purpose of Committing Dacoity) | BNS 2023 | **310** | **6** | IPC 402 | `Dacoity Form Template` (ID: 3) |
| **Robbery, or Dacoity, with Attempt to Cause Death or Grievous Hurt** | BNS 2023 | **311** | — | IPC 397 | `Robbery Form Template` (ID: 4) |
| **Attempt to Commit Robbery or Dacoity When Armed with Deadly Weapon** | BNS 2023 | **312** | — | IPC 398 | `Robbery Form Template` (ID: 4) |

---

## 2. Dynamic Form Templates

| Template ID | Template Name | Key Applicable Sections | Description |
| :---: | :--- | :--- | :--- |
| **3** | `Dacoity Form Template` | BNS 310(1–6), IPC 391, 395, 396, 399, 400, 402 | Dynamic template capturing gang details, preparation spots, weapons used, stolen property value, and victim injuries. |
| **4** | `Robbery Form Template` | BNS 309(1–6), 311, 312, IPC 390, 392, 393, 394, 397, 398 | Dynamic template capturing weapon details, mode of threat/hurt, vehicle details, stolen property, and accused identification. |

---

## 3. Database Schema Reference

### `act_sections` & `act_subsections` Relations

```
  [Act: BNS 2023]
       │
       ├── Section 309 (Robbery) ──► Robbery Form Template (ID: 4)
       │    ├── Subsection 1 (IPC 390)
       │    ├── Subsection 2 (IPC 390)
       │    ├── Subsection 3 (IPC 390)
       │    ├── Subsection 4 (IPC 392)
       │    ├── Subsection 5 (IPC 393)
       │    └── Subsection 6 (IPC 394)
       │
       ├── Section 310 (Dacoity) ──► Dacoity Form Template (ID: 3)
       │    ├── Subsection 1 (IPC 391)
       │    ├── Subsection 2 (IPC 395)
       │    ├── Subsection 3 (IPC 396)
       │    ├── Subsection 4 (IPC 399)
       │    ├── Subsection 5 (IPC 400)
       │    └── Subsection 6 (IPC 402)
       │
       ├── Section 311 (Death / Grievous Hurt Attempt) ──► Robbery Form Template (ID: 4)
       └── Section 312 (Armed with Deadly Weapon) ─────► Robbery Form Template (ID: 4)
```
