-- =====================================================================
-- JK Lakshmipat University (JKLU) Hostel Management System
-- Database Schema & Master Demonstration Records
-- Target Database: MySQL 8.0+
-- File: database.sql
-- Hostels Supported: GH1 (Girls Hostel 1), GH2 (Girls Hostel 2),
--                    BH1 (Boys Hostel 1), BH2 (Boys Hostel 2)
-- =====================================================================

DROP DATABASE IF EXISTS hostel_management;
CREATE DATABASE hostel_management CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE hostel_management;

-- ---------------------------------------------------------------------
-- Table 1: Warden
-- ---------------------------------------------------------------------
CREATE TABLE Warden (
    warden_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('Chief Warden', 'Warden') NOT NULL DEFAULT 'Warden',
    assigned_hostel VARCHAR(10) NULL, -- 'GH1', 'GH2', 'BH1', 'BH2', or NULL for Chief Warden
    office_location VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 2: Hostel
-- Only 4 hostels at JKLU: GH1, GH2, BH1, BH2
-- ---------------------------------------------------------------------
CREATE TABLE Hostel (
    hostel_id INT AUTO_INCREMENT PRIMARY KEY,
    hostel_code ENUM('GH1', 'GH2', 'BH1', 'BH2') NOT NULL UNIQUE,
    hostel_name VARCHAR(100) NOT NULL UNIQUE,
    warden_id INT NULL,
    total_floors INT NOT NULL DEFAULT 4,
    gender ENUM('Boys', 'Girls') NOT NULL,
    address VARCHAR(255) NOT NULL DEFAULT 'JK Lakshmipat University Campus, Near Mahindra SEZ, Ajmer Road, Jaipur, Rajasthan 302026',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_hostel_warden FOREIGN KEY (warden_id) REFERENCES Warden(warden_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 3: Room
-- GH1, BH1, BH2: numeric rooms (e.g. 101, 102...)
-- GH2: flat-based rooms (e.g. 101A, 101B, 101C, 101D...)
-- ---------------------------------------------------------------------
CREATE TABLE Room (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    hostel_id INT NOT NULL,
    room_number VARCHAR(20) NOT NULL,
    floor_number INT NOT NULL,
    capacity INT NOT NULL DEFAULT 2,
    current_occupancy INT NOT NULL DEFAULT 0,
    status ENUM('Available', 'Full', 'Maintenance') NOT NULL DEFAULT 'Available',
    monthly_fee DECIMAL(10, 2) NOT NULL DEFAULT 4800.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_hostel_room UNIQUE (hostel_id, room_number),
    CONSTRAINT fk_room_hostel FOREIGN KEY (hostel_id) REFERENCES Hostel(hostel_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 4: Student
-- Preserves JKLU roll number formats: e.g. 2025Btech224, 2024BBA015, 2024BDes008
-- ---------------------------------------------------------------------
CREATE TABLE Student (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    student_code VARCHAR(30) NULL UNIQUE, -- JKLU Roll Number
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    emergency_contact VARCHAR(20) NOT NULL,
    department VARCHAR(100) NOT NULL,
    programme ENUM('B.Tech', 'BBA', 'B.Des', 'M.Tech', 'BCA') NOT NULL DEFAULT 'B.Tech',
    year_of_study INT NOT NULL DEFAULT 1,
    password_hash VARCHAR(255) NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    blood_group VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 5: Allocation
-- ---------------------------------------------------------------------
CREATE TABLE Allocation (
    allocation_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    room_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    status ENUM('Active', 'Terminated', 'Transferred') NOT NULL DEFAULT 'Active',
    notes VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_allocation_student FOREIGN KEY (student_id) REFERENCES Student(student_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_allocation_room FOREIGN KEY (room_id) REFERENCES Room(room_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 6: Staff
-- ---------------------------------------------------------------------
CREATE TABLE Staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role ENUM('Electrician', 'Plumber', 'Carpenter', 'Housekeeping', 'Mess Cook', 'Supervisor', 'Security Guard') NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) UNIQUE,
    shift_timing VARCHAR(50) NOT NULL,
    hostel_id INT NULL,
    salary DECIMAL(10, 2) NOT NULL DEFAULT 22000.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_staff_hostel FOREIGN KEY (hostel_id) REFERENCES Hostel(hostel_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 7: Fee_Payment
-- ---------------------------------------------------------------------
CREATE TABLE Fee_Payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    amount_paid DECIMAL(10, 2) NOT NULL,
    due_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    payment_date DATE NOT NULL,
    payment_method ENUM('Online', 'Bank Transfer', 'Demand Draft', 'Cash') NOT NULL,
    transaction_reference VARCHAR(100) NOT NULL UNIQUE,
    status ENUM('Paid', 'Pending', 'Overdue') NOT NULL DEFAULT 'Paid',
    billing_month VARCHAR(30) NOT NULL,
    remarks VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fee_student FOREIGN KEY (student_id) REFERENCES Student(student_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 8: Mess & Mess_Weekly_Menu Configuration
-- ---------------------------------------------------------------------
CREATE TABLE Mess (
    mess_id INT AUTO_INCREMENT PRIMARY KEY,
    hostel_id INT NOT NULL,
    mess_name VARCHAR(100) NOT NULL,
    caterer_name VARCHAR(100) NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_mess_hostel FOREIGN KEY (hostel_id) REFERENCES Hostel(hostel_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Mess_Weekly_Menu (
    menu_id INT AUTO_INCREMENT PRIMARY KEY,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    meal_type ENUM('Breakfast', 'Lunch', 'Evening Snacks', 'Dinner') NOT NULL,
    menu_items TEXT NULL, -- NULL until configured
    meal_timing VARCHAR(100) NULL, -- NULL until configured
    is_configured BOOLEAN NOT NULL DEFAULT FALSE,
    last_updated_by VARCHAR(100) NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uk_day_meal UNIQUE (day_of_week, meal_type)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 9: Visitor & Visit
-- ---------------------------------------------------------------------
CREATE TABLE Visitor (
    visitor_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    id_proof_type ENUM('Aadhaar', 'Driver License', 'Passport', 'Voter ID', 'College ID') NOT NULL,
    id_proof_number VARCHAR(50) NOT NULL,
    address VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE Visit (
    visit_id INT AUTO_INCREMENT PRIMARY KEY,
    visitor_id INT NOT NULL,
    student_id INT NOT NULL,
    hostel_id INT NOT NULL,
    relation_to_student VARCHAR(50) NOT NULL,
    purpose VARCHAR(200) NOT NULL,
    check_in DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    check_out DATETIME NULL,
    status ENUM('Inside', 'Checked Out') NOT NULL DEFAULT 'Inside',
    guard_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_visit_visitor FOREIGN KEY (visitor_id) REFERENCES Visitor(visitor_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_visit_student FOREIGN KEY (student_id) REFERENCES Student(student_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_visit_hostel FOREIGN KEY (hostel_id) REFERENCES Hostel(hostel_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 10: Complaint (Core entity)
-- ---------------------------------------------------------------------
CREATE TABLE Complaint (
    complaint_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    room_id INT NULL,
    category ENUM('Electrical', 'Plumbing', 'Carpentry', 'Cleaning', 'Wi-Fi/Internet', 'Mess Food', 'Discipline', 'Other') NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    status ENUM('Pending', 'In Progress', 'Resolved', 'Rejected') NOT NULL DEFAULT 'Pending',
    priority ENUM('Low', 'Medium', 'High', 'Urgent') NOT NULL DEFAULT 'Medium',
    staff_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at DATETIME NULL,
    resolution_remarks TEXT,
    CONSTRAINT fk_complaint_student FOREIGN KEY (student_id) REFERENCES Student(student_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_complaint_room FOREIGN KEY (room_id) REFERENCES Room(room_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_complaint_staff FOREIGN KEY (staff_id) REFERENCES Staff(staff_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- JKLU REGISTER TABLES
-- =====================================================================

-- Register 1: register_complaints
CREATE TABLE register_complaints (
    id INT AUTO_INCREMENT PRIMARY KEY,
    complaint_date DATE NOT NULL,
    student_name VARCHAR(100) NOT NULL,
    student_roll_no VARCHAR(50) NULL,
    hostel_code ENUM('GH1', 'GH2', 'BH1', 'BH2') NOT NULL,
    room_no VARCHAR(20) NOT NULL,
    complaint_type VARCHAR(100) NOT NULL,
    complaint_details TEXT NOT NULL,
    status ENUM('Pending', 'In Progress', 'Resolved') NOT NULL DEFAULT 'Pending',
    resolved_date DATE NULL,
    action_taken TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Register 2: cleaning_register
CREATE TABLE cleaning_register (
    cleaning_id INT AUTO_INCREMENT PRIMARY KEY,
    hostel_code ENUM('GH1', 'GH2', 'BH1', 'BH2') NOT NULL,
    floor_or_area VARCHAR(100) NOT NULL,
    cleaner_name VARCHAR(100) NOT NULL,
    cleaning_date DATE NOT NULL,
    cleaning_time TIME NOT NULL,
    inspection_status ENUM('Satisfactory', 'Needs Attention', 'Re-cleaned') NOT NULL DEFAULT 'Satisfactory',
    remarks VARCHAR(255) NULL,
    inspected_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Register 3: student_out_register
CREATE TABLE student_out_register (
    out_id INT AUTO_INCREMENT PRIMARY KEY,
    student_name VARCHAR(100) NOT NULL,
    roll_no VARCHAR(50) NULL,
    hostel_code ENUM('GH1', 'GH2', 'BH1', 'BH2') NOT NULL,
    room_no VARCHAR(20) NOT NULL,
    destination VARCHAR(200) NOT NULL,
    out_date DATE NOT NULL,
    out_time TIME NOT NULL,
    expected_in_date DATE NOT NULL,
    expected_in_time TIME NOT NULL,
    actual_in_date DATE NULL,
    actual_in_time TIME NULL,
    contact_number VARCHAR(20) NOT NULL,
    parent_consent_status ENUM('Approved', 'Pending', 'Not Required') NOT NULL DEFAULT 'Approved',
    remarks VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Register 4: late_night_entry
CREATE TABLE late_night_entry (
    entry_id INT AUTO_INCREMENT PRIMARY KEY,
    student_name VARCHAR(100) NOT NULL,
    roll_no VARCHAR(50) NULL,
    hostel_code ENUM('GH1', 'GH2', 'BH1', 'BH2') NOT NULL,
    room_no VARCHAR(20) NOT NULL,
    entry_date DATE NOT NULL,
    entry_time TIME NOT NULL,
    reason_for_late TEXT NOT NULL,
    guard_on_duty VARCHAR(100) NOT NULL,
    warden_notified BOOLEAN NOT NULL DEFAULT TRUE,
    action_or_remarks VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Register 5: attendance_register
CREATE TABLE attendance_register (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NULL,
    student_name VARCHAR(100) NOT NULL,
    roll_no VARCHAR(50) NULL,
    hostel_code ENUM('GH1', 'GH2', 'BH1', 'BH2') NOT NULL,
    room_no VARCHAR(20) NOT NULL,
    date DATE NOT NULL,
    status ENUM('Present', 'Absent', 'Leave', 'Sick') NOT NULL DEFAULT 'Present',
    remarks VARCHAR(150) NULL,
    recorded_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_student_attendance_reg UNIQUE (roll_no, date)
) ENGINE=InnoDB;

-- Register 6: maintenance_register
CREATE TABLE maintenance_register (
    maint_id INT AUTO_INCREMENT PRIMARY KEY,
    hostel_code ENUM('GH1', 'GH2', 'BH1', 'BH2') NOT NULL,
    location_or_room VARCHAR(50) NOT NULL,
    issue_description TEXT NOT NULL,
    work_type ENUM('Electrical', 'Plumbing', 'Carpentry', 'Civil', 'Appliance', 'Other') NOT NULL,
    reported_date DATE NOT NULL,
    assigned_worker VARCHAR(100) NULL,
    completion_status ENUM('Pending', 'In Progress', 'Completed') NOT NULL DEFAULT 'Pending',
    completed_date DATE NULL,
    cost DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Register 7: security_handover
CREATE TABLE security_handover (
    handover_id INT AUTO_INCREMENT PRIMARY KEY,
    hostel_code ENUM('GH1', 'GH2', 'BH1', 'BH2') NOT NULL,
    handover_date DATE NOT NULL,
    shift ENUM('Morning (06:00 - 14:00)', 'Evening (14:00 - 22:00)', 'Night (22:00 - 06:00)') NOT NULL,
    outgoing_guard VARCHAR(100) NOT NULL,
    incoming_guard VARCHAR(100) NOT NULL,
    keys_status VARCHAR(200) NOT NULL DEFAULT 'All room & gate keys accounted for',
    incident_summary TEXT NULL,
    verified_by_warden BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Indexes
CREATE INDEX idx_reg_complaints_hostel ON register_complaints(hostel_code);
CREATE INDEX idx_cleaning_hostel ON cleaning_register(hostel_code);
CREATE INDEX idx_out_hostel ON student_out_register(hostel_code);
CREATE INDEX idx_late_hostel ON late_night_entry(hostel_code);
CREATE INDEX idx_attendance_hostel ON attendance_register(hostel_code);
CREATE INDEX idx_maintenance_hostel ON maintenance_register(hostel_code);
CREATE INDEX idx_handover_hostel ON security_handover(hostel_code);

-- =====================================================================
-- SEED DEMONSTRATION RECORDS (JKLU SPECIFIC)
-- Password for all demo accounts: warden123
-- =====================================================================

-- 1. Wardens
INSERT INTO Warden (warden_id, name, email, phone, password_hash, role, assigned_hostel, office_location) VALUES
(1, 'Dr. S. K. Sharma', 'chief.warden@jklu.edu.in', '9829012340', '$2b$10$uA9K1/i1f95aXf7Q4d7eouB59yJ00kPekr9m7bF0L4pQWfPfxq9Xy', 'Chief Warden', NULL, 'Administrative Block, Ground Floor Rm 104'),
(2, 'Prof. Rekha Gupta', 'gh1.warden@jklu.edu.in', '9829012341', '$2b$10$uA9K1/i1f95aXf7Q4d7eouB59yJ00kPekr9m7bF0L4pQWfPfxq9Xy', 'Warden', 'GH1', 'Girls Hostel 1 Warden Office'),
(3, 'Dr. Meenakshi Pareek', 'gh2.warden@jklu.edu.in', '9829012342', '$2b$10$uA9K1/i1f95aXf7Q4d7eouB59yJ00kPekr9m7bF0L4pQWfPfxq9Xy', 'Warden', 'GH2', 'Girls Hostel 2 Ground Floor Suite'),
(4, 'Prof. Amit Joshi', 'bh1.warden@jklu.edu.in', '9829012343', '$2b$10$uA9K1/i1f95aXf7Q4d7eouB59yJ00kPekr9m7bF0L4pQWfPfxq9Xy', 'Warden', 'BH1', 'Boys Hostel 1 Warden Office Room 02'),
(5, 'Dr. Virendra Singh', 'bh2.warden@jklu.edu.in', '9829012344', '$2b$10$uA9K1/i1f95aXf7Q4d7eouB59yJ00kPekr9m7bF0L4pQWfPfxq9Xy', 'Warden', 'BH2', 'Boys Hostel 2 Ground Floor Office');

-- 2. Hostels (Only 4 JKLU Hostels)
INSERT INTO Hostel (hostel_id, hostel_code, hostel_name, warden_id, total_floors, gender, address) VALUES
(1, 'GH1', 'Girls Hostel 1 (GH1)', 2, 4, 'Girls', 'JKLU Campus, South Residential Zone'),
(2, 'GH2', 'Girls Hostel 2 (GH2 - Flats)', 3, 4, 'Girls', 'JKLU Campus, South Residential Zone'),
(3, 'BH1', 'Boys Hostel 1 (BH1)', 4, 4, 'Boys', 'JKLU Campus, North Residential Zone'),
(4, 'BH2', 'Boys Hostel 2 (BH2)', 5, 4, 'Boys', 'JKLU Campus, North Residential Zone');

-- 3. Rooms
-- GH1: Normal rooms 101, 102, 103, 201...
-- GH2: Flat-based rooms 101A, 101B, 101C, 101D, 201A, 201B, 201C, 201D...
-- BH1 & BH2: Normal rooms
INSERT INTO Room (room_id, hostel_id, room_number, floor_number, capacity, current_occupancy, status, monthly_fee) VALUES
-- GH1
(1, 1, '101', 1, 2, 2, 'Full', 4800.00),
(2, 1, '102', 1, 2, 1, 'Available', 4800.00),
(3, 1, '201', 2, 2, 0, 'Available', 4800.00),
-- GH2 (Flat-based numbering: A, B, C, D)
(4, 2, '101A', 1, 2, 2, 'Full', 5200.00),
(5, 2, '101B', 1, 2, 1, 'Available', 5200.00),
(6, 2, '101C', 1, 2, 0, 'Available', 5200.00),
(7, 2, '101D', 1, 2, 0, 'Available', 5200.00),
(8, 2, '201A', 2, 2, 0, 'Available', 5200.00),
-- BH1
(9, 3, '101', 1, 2, 2, 'Full', 4800.00),
(10, 3, '102', 1, 2, 1, 'Available', 4800.00),
(11, 3, '201', 2, 2, 0, 'Available', 4800.00),
-- BH2
(12, 4, '101', 1, 2, 1, 'Available', 4800.00),
(13, 4, '102', 1, 2, 0, 'Available', 4800.00);

-- 4. Students with official JKLU Roll Numbers (e.g. 2025Btech224, 2024BBA015, 2024BDes008)
INSERT INTO Student (student_id, student_code, name, email, phone, emergency_contact, department, programme, year_of_study, password_hash, gender, blood_group) VALUES
(1, '2025Btech224', 'Aarav Choudhary', 'aarav.choudhary@jklu.edu.in', '9829011101', '9829099901', 'Computer Science & Engineering', 'B.Tech', 1, '$2b$10$uA9K1/i1f95aXf7Q4d7eouB59yJ00kPekr9m7bF0L4pQWfPfxq9Xy', 'Male', 'O+'),
(2, '2024Btech102', 'Rohan Mehta', 'rohan.mehta@jklu.edu.in', '9829011102', '9829099902', 'Computer Science & Engineering', 'B.Tech', 2, '$2b$10$uA9K1/i1f95aXf7Q4d7eouB59yJ00kPekr9m7bF0L4pQWfPfxq9Xy', 'Male', 'B+'),
(3, '2024BBA015', 'Tanvi Mathur', 'tanvi.mathur@jklu.edu.in', '9829011103', '9829099903', 'Institute of Management', 'BBA', 2, '$2b$10$uA9K1/i1f95aXf7Q4d7eouB59yJ00kPekr9m7bF0L4pQWfPfxq9Xy', 'Female', 'A+'),
(4, '2024BDes008', 'Ishita Sharma', 'ishita.sharma@jklu.edu.in', '9829011104', '9829099904', 'Institute of Design', 'B.Des', 2, '$2b$10$uA9K1/i1f95aXf7Q4d7eouB59yJ00kPekr9m7bF0L4pQWfPfxq9Xy', 'Female', 'AB+'),
(5, '2023Btech045', 'Kabir Verma', 'kabir.verma@jklu.edu.in', '9829011105', '9829099905', 'Mechanical Engineering', 'B.Tech', 3, '$2b$10$uA9K1/i1f95aXf7Q4d7eouB59yJ00kPekr9m7bF0L4pQWfPfxq9Xy', 'Male', 'O-'),
(6, '2025BDes019', 'Diya Khandelwal', 'diya.khandelwal@jklu.edu.in', '9829011106', '9829099906', 'Institute of Design', 'B.Des', 1, '$2b$10$uA9K1/i1f95aXf7Q4d7eouB59yJ00kPekr9m7bF0L4pQWfPfxq9Xy', 'Female', 'B+'),
(7, NULL, 'Gaurav Rathore', 'gaurav.rathore@jklu.edu.in', '9829011107', '9829099907', 'Computer Science & Engineering', 'B.Tech', 1, '$2b$10$uA9K1/i1f95aXf7Q4d7eouB59yJ00kPekr9m7bF0L4pQWfPfxq9Xy', 'Male', 'A-'); -- Roll number pending verification

-- 5. Allocations
INSERT INTO Allocation (allocation_id, student_id, room_id, start_date, end_date, status, notes) VALUES
(1, 1, 9, '2024-07-25', NULL, 'Active', 'BH1 Bed 1'),
(2, 2, 9, '2024-07-25', NULL, 'Active', 'BH1 Bed 2'),
(3, 5, 10, '2024-08-01', NULL, 'Active', 'BH1 Bed 1'),
(4, 3, 1, '2024-07-26', NULL, 'Active', 'GH1 Bed 1'),
(5, 4, 4, '2024-07-26', NULL, 'Active', 'GH2 Flat 101A Bed 1'),
(6, 6, 4, '2024-07-26', NULL, 'Active', 'GH2 Flat 101A Bed 2');

-- 6. Register Complaints
INSERT INTO register_complaints (id, complaint_date, student_name, student_roll_no, hostel_code, room_no, complaint_type, complaint_details, status, resolved_date, action_taken) VALUES
(1, '2024-10-10', 'Tanvi Mathur', '2024BBA015', 'GH1', '101', 'Electrical', 'Ceiling fan capacitor making rattling noise and speed not regulating', 'Resolved', '2024-10-11', 'Electrician replaced capacitor and switch'),
(2, '2024-10-12', 'Ishita Sharma', '2024BDes008', 'GH2', '101A', 'Plumbing', 'Washroom faucet continuous drip in Flat 101A', 'In Progress', NULL, 'Plumber visited, washer replacement parts requisitioned'),
(3, '2024-10-13', 'Aarav Choudhary', '2025Btech224', 'BH1', '101', 'Wi-Fi/Internet', 'LAN port RJ45 clip broken in study cubicle', 'Pending', NULL, NULL),
(4, '2024-10-14', 'Gaurav Rathore', NULL, 'BH2', '101', 'Carpentry', 'Wardrobe door hinges loosened and misaligned', 'Pending', NULL, NULL);

-- 7. Cleaning Register
INSERT INTO cleaning_register (cleaning_id, hostel_code, floor_or_area, cleaner_name, cleaning_date, cleaning_time, inspection_status, remarks, inspected_by) VALUES
(1, 'GH1', 'Floor 1 Corridors & Washrooms', 'Sunita Devi', '2024-10-14', '08:30:00', 'Satisfactory', 'Cleaned and sanitized with disinfectant', 'Warden Prof. Rekha Gupta'),
(2, 'GH2', 'Floor 1 Flats A-D Common Foyer', 'Pooja Bai', '2024-10-14', '09:00:00', 'Satisfactory', 'Garbage cleared and floor mopped', 'Warden Dr. Meenakshi Pareek'),
(3, 'BH1', 'Ground Floor Wing A Washrooms', 'Ramesh Lal', '2024-10-14', '07:45:00', 'Satisfactory', 'Deep cleaned and mirrors wiped', 'Warden Prof. Amit Joshi'),
(4, 'BH2', 'Floor 1 Lobby & Staircase', 'Mohan Ram', '2024-10-14', '10:15:00', 'Needs Attention', 'Dust bin near water dispenser required emptying', 'Warden Dr. Virendra Singh');

-- 8. Student Out Register
INSERT INTO student_out_register (out_id, student_name, roll_no, hostel_code, room_no, destination, out_date, out_time, expected_in_date, expected_in_time, actual_in_date, actual_in_time, contact_number, parent_consent_status, remarks) VALUES
(1, 'Aarav Choudhary', '2025Btech224', 'BH1', '101', 'Mahindra SEZ Tech Park', '2024-10-14', '16:30:00', '2024-10-14', '19:30:00', '2024-10-14', '19:15:00', '9829011101', 'Approved', 'Attending academic coding workshop'),
(2, 'Tanvi Mathur', '2024BBA015', 'GH1', '101', 'Vaishali Nagar Jaipur', '2024-10-14', '15:00:00', '2024-10-14', '20:00:00', '2024-10-14', '19:50:00', '9829011103', 'Approved', 'Purchased semester project textbooks'),
(3, 'Kabir Verma', '2023Btech045', 'BH1', '102', 'Mansarovar Metro Station', '2024-10-14', '18:00:00', '2024-10-14', '21:00:00', NULL, NULL, '9829011105', 'Approved', 'Day outpass approved by warden');

-- 9. Late Night Entry
INSERT INTO late_night_entry (entry_id, student_name, roll_no, hostel_code, room_no, entry_date, entry_time, reason_for_late, guard_on_duty, warden_notified, action_or_remarks) VALUES
(1, 'Kabir Verma', '2023Btech045', 'BH1', '102', '2024-10-13', '22:45:00', 'City bus delay on Ajmer Road route near toll plaza', 'Guard Rajesh Yadav', TRUE, 'First delay warning noted on gate log'),
(2, 'Gaurav Rathore', NULL, 'BH2', '101', '2024-10-12', '23:10:00', 'Delayed return from robotics laboratory prototype testing', 'Guard Mahesh Shinde', TRUE, 'Lab supervisor confirmation verified');

-- 10. Attendance Register
INSERT INTO attendance_register (attendance_id, student_id, student_name, roll_no, hostel_code, room_no, date, status, remarks, recorded_by) VALUES
(1, 1, 'Aarav Choudhary', '2025Btech224', 'BH1', '101', '2024-10-14', 'Present', 'Present in room at 9:30 PM roll call', 'Prof. Amit Joshi'),
(2, 2, 'Rohan Mehta', '2024Btech102', 'BH1', '101', '2024-10-14', 'Present', 'Present at roll call', 'Prof. Amit Joshi'),
(3, 3, 'Tanvi Mathur', '2024BBA015', 'GH1', '101', '2024-10-14', 'Present', 'Present at roll call', 'Prof. Rekha Gupta'),
(4, 4, 'Ishita Sharma', '2024BDes008', 'GH2', '101A', '2024-10-14', 'Present', 'Present in Flat 101A', 'Dr. Meenakshi Pareek'),
(5, 5, 'Kabir Verma', '2023Btech045', 'BH1', '102', '2024-10-14', 'Present', 'Present at roll call', 'Prof. Amit Joshi'),
(6, 6, 'Diya Khandelwal', '2025BDes019', 'GH2', '101A', '2024-10-14', 'Present', 'Present in Flat 101A', 'Dr. Meenakshi Pareek');

-- 11. Maintenance Register
INSERT INTO maintenance_register (maint_id, hostel_code, location_or_room, issue_description, work_type, reported_date, assigned_worker, completion_status, completed_date, cost) VALUES
(1, 'GH1', 'Room 101', 'Ceiling fan capacitor replacement', 'Electrical', '2024-10-10', 'Mukesh Sharma (Electrician)', 'Completed', '2024-10-11', 250.00),
(2, 'GH2', 'Flat 101A Washroom', 'Water valve leakage repair', 'Plumbing', '2024-10-12', 'Suresh Gond (Plumber)', 'In Progress', NULL, 300.00),
(3, 'BH1', 'Room 101', 'Network port recrimping', 'Other', '2024-10-13', 'Campus IT Support', 'Pending', NULL, 0.00),
(4, 'BH2', 'Ground Floor Corridor', 'LED tube light flickering near entry gate', 'Electrical', '2024-10-14', 'Mukesh Sharma (Electrician)', 'Pending', NULL, 400.00);

-- 12. Security Handover
INSERT INTO security_handover (handover_id, hostel_code, handover_date, shift, outgoing_guard, incoming_guard, keys_status, incident_summary, verified_by_warden) VALUES
(1, 'GH1', '2024-10-14', 'Morning (06:00 - 14:00)', 'Rajendra Meena', 'Kailash Chand', 'All room & gate keys accounted for', 'Calm shift, no unauthorized entries recorded', TRUE),
(2, 'GH2', '2024-10-14', 'Morning (06:00 - 14:00)', 'Kiran Devi', 'Sunita Gurjar', 'All flat keys and emergency master key intact', 'No untoward incidents observed', TRUE),
(3, 'BH1', '2024-10-14', 'Evening (14:00 - 22:00)', 'Rajesh Yadav', 'Mahesh Shinde', 'All room & gate keys accounted for', 'Evening roll-call gate movement verified', TRUE),
(4, 'BH2', '2024-10-14', 'Morning (06:00 - 14:00)', 'Mahesh Shinde', 'Dinesh Kumar', 'All keys present and verified', 'Courier parcel deliveries logged at gate', TRUE);

-- 13. Mess Weekly Menu Initial Seed (All 7 days x 4 meals initialized to unconfigured as required)
INSERT INTO Mess_Weekly_Menu (day_of_week, meal_type, menu_items, meal_timing, is_configured, last_updated_by) VALUES
('Monday', 'Breakfast', NULL, NULL, FALSE, NULL),
('Monday', 'Lunch', NULL, NULL, FALSE, NULL),
('Monday', 'Evening Snacks', NULL, NULL, FALSE, NULL),
('Monday', 'Dinner', NULL, NULL, FALSE, NULL),
('Tuesday', 'Breakfast', NULL, NULL, FALSE, NULL),
('Tuesday', 'Lunch', NULL, NULL, FALSE, NULL),
('Tuesday', 'Evening Snacks', NULL, NULL, FALSE, NULL),
('Tuesday', 'Dinner', NULL, NULL, FALSE, NULL),
('Wednesday', 'Breakfast', NULL, NULL, FALSE, NULL),
('Wednesday', 'Lunch', NULL, NULL, FALSE, NULL),
('Wednesday', 'Evening Snacks', NULL, NULL, FALSE, NULL),
('Wednesday', 'Dinner', NULL, NULL, FALSE, NULL),
('Thursday', 'Breakfast', NULL, NULL, FALSE, NULL),
('Thursday', 'Lunch', NULL, NULL, FALSE, NULL),
('Thursday', 'Evening Snacks', NULL, NULL, FALSE, NULL),
('Thursday', 'Dinner', NULL, NULL, FALSE, NULL),
('Friday', 'Breakfast', NULL, NULL, FALSE, NULL),
('Friday', 'Lunch', NULL, NULL, FALSE, NULL),
('Friday', 'Evening Snacks', NULL, NULL, FALSE, NULL),
('Friday', 'Dinner', NULL, NULL, FALSE, NULL),
('Saturday', 'Breakfast', NULL, NULL, FALSE, NULL),
('Saturday', 'Lunch', NULL, NULL, FALSE, NULL),
('Saturday', 'Evening Snacks', NULL, NULL, FALSE, NULL),
('Saturday', 'Dinner', NULL, NULL, FALSE, NULL),
('Sunday', 'Breakfast', NULL, NULL, FALSE, NULL),
('Sunday', 'Lunch', NULL, NULL, FALSE, NULL),
('Sunday', 'Evening Snacks', NULL, NULL, FALSE, NULL),
('Sunday', 'Dinner', NULL, NULL, FALSE, NULL);

SELECT 'JKLU Hostel Management Database initialized with 4 Hostels (GH1, GH2, BH1, BH2) and Register Tables!' AS status;
-- =====================================================================
-- SQL JOIN QUERIES
-- =====================================================================

-- =====================================================================
-- SQL JOIN QUERIES
-- =====================================================================

-- 1. INNER JOIN: Students with their allocated rooms and hostels
SELECT s.student_id, s.name, s.student_code,
       h.hostel_name, r.room_number
FROM Student s
INNER JOIN Allocation a ON s.student_id = a.student_id
INNER JOIN Room r ON a.room_id = r.room_id
INNER JOIN Hostel h ON r.hostel_id = h.hostel_id;

-- 2. LEFT JOIN: All students and their allocation details
SELECT s.student_id, s.name, s.student_code,
       r.room_number, h.hostel_name
FROM Student s
LEFT JOIN Allocation a ON s.student_id = a.student_id
LEFT JOIN Room r ON a.room_id = r.room_id
LEFT JOIN Hostel h ON r.hostel_id = h.hostel_id;

-- 3. RIGHT JOIN: All hostels and their assigned wardens
SELECT h.hostel_name, h.hostel_code,
       w.name AS warden_name, w.email
FROM Warden w
RIGHT JOIN Hostel h ON w.warden_id = h.warden_id;

-- 4. INNER JOIN: Students and their fee payment details
SELECT s.name, s.student_code,
       f.amount_paid, f.due_amount,
       f.payment_date, f.status
FROM Student s
INNER JOIN Fee_Payment f ON s.student_id = f.student_id;

-- 5. INNER JOIN: Complaints with student and staff details
SELECT c.complaint_id, s.name AS student_name,
       c.category, c.title, c.status,
       st.name AS assigned_staff
FROM Complaint c
INNER JOIN Student s ON c.student_id = s.student_id
LEFT JOIN Staff st ON c.staff_id = st.staff_id;

-- 6. INNER JOIN: Visitors and the students they are visiting
SELECT v.full_name AS visitor_name,
       s.name AS student_name,
       h.hostel_name, vi.purpose,
       vi.check_in, vi.check_out
FROM Visit vi
INNER JOIN Visitor v ON vi.visitor_id = v.visitor_id
INNER JOIN Student s ON vi.student_id = s.student_id
INNER JOIN Hostel h ON vi.hostel_id = h.hostel_id;

-- 7. LEFT JOIN: All hostels and their staff members
SELECT h.hostel_name, st.name AS staff_name,
       st.role, st.phone
FROM Hostel h
LEFT JOIN Staff st ON h.hostel_id = st.hostel_id;

-- 8. INNER JOIN: Students and their attendance records
SELECT s.name, s.student_code,
       ar.date, ar.status, ar.recorded_by
FROM Student s
INNER JOIN attendance_register ar
ON s.student_id = ar.student_id;

-- 9. INNER JOIN: Rooms with hostel details
SELECT h.hostel_name, r.room_number,
       r.floor_number, r.capacity,
       r.current_occupancy, r.status
FROM Hostel h
INNER JOIN Room r ON h.hostel_id = r.hostel_id;

-- 10. LEFT JOIN: All students and their complaints
SELECT s.name, s.student_code,
       c.complaint_id, c.category,
       c.title, c.status
FROM Student s
LEFT JOIN Complaint c ON s.student_id = c.student_id;

-- 11. INNER JOIN: Maintenance records with hostel details
SELECT h.hostel_name, m.location_or_room,
       m.issue_description, m.work_type,
       m.completion_status, m.cost
FROM Hostel h
INNER JOIN maintenance_register m
ON h.hostel_code = m.hostel_code;

-- 12. INNER JOIN: Allocations with student, room and hostel details
SELECT a.allocation_id, s.name AS student_name,
       r.room_number, h.hostel_name,
       a.start_date, a.status
FROM Allocation a
INNER JOIN Student s ON a.student_id = s.student_id
INNER JOIN Room r ON a.room_id = r.room_id
INNER JOIN Hostel h ON r.hostel_id = h.hostel_id;

-- 13. INNER JOIN: Students with their out-pass records
SELECT s.name, s.student_code,
       o.destination, o.out_date,
       o.expected_in_date, o.parent_consent_status
FROM Student s
INNER JOIN student_out_register o
ON s.student_code = o.roll_no;

-- 14. LEFT JOIN: All hostels and their cleaning records
SELECT h.hostel_name, cr.floor_or_area,
       cr.cleaner_name, cr.cleaning_date,
       cr.inspection_status
FROM Hostel h
LEFT JOIN cleaning_register cr
ON h.hostel_code = cr.hostel_code;

-- 15. INNER JOIN: Students and their late-night entry records
SELECT s.name, s.student_code,
       l.entry_date, l.entry_time,
       l.reason_for_late, l.guard_on_duty
FROM Student s
INNER JOIN late_night_entry l
ON s.student_code = l.roll_no;

-- 16. RIGHT JOIN: All students and their attendance records
SELECT s.name, s.student_code,
       ar.date, ar.status
FROM Student s
RIGHT JOIN attendance_register ar
ON s.student_id = ar.student_id;

-- 17. INNER JOIN: Hostels and their security handover records
SELECT h.hostel_name, sh.handover_date,
       sh.shift, sh.outgoing_guard,
       sh.incoming_guard, sh.verified_by_warden
FROM Hostel h
INNER JOIN security_handover sh
ON h.hostel_code = sh.hostel_code;

-- 18. CROSS JOIN: All possible combinations of days and meal types
SELECT d.day_of_week, m.meal_type
FROM
(SELECT 'Monday' AS day_of_week
 UNION SELECT 'Tuesday'
 UNION SELECT 'Wednesday'
 UNION SELECT 'Thursday'
 UNION SELECT 'Friday'
 UNION SELECT 'Saturday'
 UNION SELECT 'Sunday') d
CROSS JOIN
(SELECT 'Breakfast' AS meal_type
 UNION SELECT 'Lunch'
 UNION SELECT 'Evening Snacks'
 UNION SELECT 'Dinner') m;

-- 19. SELF JOIN: Compare students belonging to the same department
SELECT s1.name AS student1,
       s2.name AS student2,
       s1.department
FROM Student s1
INNER JOIN Student s2
ON s1.department = s2.department
AND s1.student_id < s2.student_id;

-- 20. INNER JOIN: Complaints with student, room and hostel details
SELECT c.complaint_id, s.name AS student_name,
       h.hostel_name, r.room_number,
       c.category, c.priority, c.status
FROM Complaint c
INNER JOIN Student s ON c.student_id = s.student_id
LEFT JOIN Room r ON c.room_id = r.room_id
<<<<<<< Updated upstream
LEFT JOIN Hostel h ON r.hostel_id = h.hostel_id;

select * from attendance_register;
=======
LEFT JOIN Hostel h ON r.hostel_id = h.hostel_id;
>>>>>>> Stashed changes
