# JKLU Hostel Management System

A formal, minimal, functional full-stack web application for **JK Lakshmipat University (JKLU)** hostel administration built with **React**, **Node.js/Express**, and **MySQL 8**.

---

## 1. Supported Hostels

The application strictly supports only the four official JKLU hostels:
- **GH1** — Girls Hostel 1 (Standard room numbers: 101, 102, 201...)
- **GH2** — Girls Hostel 2 (Flat-based room numbering: 4 flats per floor identified as A, B, C, D — e.g. 101A, 101B, 101C, 101D, 201A...)
- **BH1** — Boys Hostel 1 (Standard room numbers: 101, 102, 201...)
- **BH2** — Boys Hostel 2 (Standard room numbers: 101, 102...)

---

## 2. Dashboard Views & Role-Based Access Control

The system provides **five distinct dashboard views**:
1. **Chief Warden Dashboard**:
   - Oversees all four hostels (GH1, GH2, BH1, BH2).
   - Hostel-wise comparative analysis of capacity, occupancy, pending complaints, cleaning, and security infractions.
   - Interactive hostel switcher to inspect any specific hostel or view the entire campus.
   - Authority to configure the official weekly mess menu timetable and timings.
2. **GH1 Warden Dashboard**:
   - Strictly restricted to Girls Hostel 1 records.
3. **GH2 Warden Dashboard**:
   - Strictly restricted to Girls Hostel 2 records with flat-based room views (101A, 101B, 101C, 101D).
4. **BH1 Warden Dashboard**:
   - Strictly restricted to Boys Hostel 1 records.
5. **BH2 Warden Dashboard**:
   - Strictly restricted to Boys Hostel 2 records.

*Server-side enforcement*: A hostel warden cannot access or modify records of another hostel.

---

## 3. Official JKLU Student Roll Numbers

Student roll numbers strictly preserve and validate official JKLU formats:
- **B.Tech**: e.g., `2025Btech224`, `2024Btech102`, `2023Btech045`
- **BBA**: e.g., `2024BBA015`, `2025BBA032`
- **B.Des**: e.g., `2024BDes008`, `2025BDes019`

Any student whose roll number is not yet on record is marked with an amber **Unavailable** badge, allowing authorized wardens to input and validate the correct roll number format via modal without fabricating records.

---

## 4. Official Register Tables

The application connects to and manages all 7 key hostel register tables:
1. `register_complaints`: Date, student name, roll no, hostel, room, defect type, status (`Pending`, `In Progress`, `Resolved`), action taken.
2. `cleaning_register`: Hostel code, floor/area, cleaner name, inspection date/time, status (`Satisfactory`, `Needs Attention`, `Re-cleaned`), inspector.
3. `student_out_register`: Student name, roll no, destination, departure timestamp, expected return timestamp, actual return timestamp, parent consent status.
4. `late_night_entry`: Late-arrival timestamp, student name, roll no, room, detailed reason, duty guard, warden notification flag.
5. `attendance_register`: Daily night roll call with presence status (`Present`, `Absent`, `Leave`, `Sick`) and remarks.
6. `maintenance_register`: Repair tickets categorized by work type (Electrical, Plumbing, Carpentry, Civil, Appliance), cost, assigned technician, completion status.
7. `security_handover`: Shift period (Morning, Evening, Night), outgoing/incoming guard names, key inventory status, incident log.

---

## 5. Mess Timetable & Configuration

Under the **Mess** section:
- Complete weekly timetable from **Monday to Sunday** covering **Breakfast, Lunch, Evening Snacks, and Dinner**.
- Unconfigured meal slots display **"Menu not configured"** and **"Timings not configured"** until confirmed.
- An authorized warden can click **Configure** on any meal slot to input the official university menu items and serving timings.

---

## 6. Demonstration Login Credentials

All demonstration accounts use the password: `warden123`

| Role / View | Institutional Email ID | Password | Scope |
|---|---|---|---|
| **Chief Warden** | `chief.warden@jklu.edu.in` | `warden123` | Master oversight across GH1, GH2, BH1, BH2 |
| **GH1 Warden** | `gh1.warden@jklu.edu.in` | `warden123` | Girls Hostel 1 records only |
| **GH2 Warden** | `gh2.warden@jklu.edu.in` | `warden123` | Girls Hostel 2 records only (Flats A, B, C, D) |
| **BH1 Warden** | `bh1.warden@jklu.edu.in` | `warden123` | Boys Hostel 1 records only |
| **BH2 Warden** | `bh2.warden@jklu.edu.in` | `warden123` | Boys Hostel 2 records only |

*The login screen includes 1-click quick-fill buttons for rapid evaluator testing.*

---

## 7. Execution Guide in VS Code with MySQL Workbench

### Step 1: Open MySQL Workbench & Execute `database.sql`
1. Open **MySQL Workbench** and connect to your local MySQL 8.0 server (`localhost:3306`).
2. Click **File -> Open SQL Script...** and choose `database.sql` (or `jklu_migration.sql` if upgrading an existing schema).
3. Click the **Execute (⚡)** button.
4. Verify the `hostel_management` schema is created with the 4 JKLU hostels and register tables.

### Step 2: Configure Environment Credentials
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Ensure your database password is set in `.env`:
```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_actual_mysql_password
DB_NAME=hostel_management
PORT=3000
JWT_SECRET=super_secret_hostel_jwt_key_college_dbms_2024
```

### Step 3: Install & Start Development Server
```bash
npm install
npm run dev
```
Navigate in your browser to:
```
http://localhost:3000
```
"# JKLU_Hostel_Management" 
"# JKLU_Hostel_Management" 
