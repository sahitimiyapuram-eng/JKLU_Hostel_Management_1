import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

export const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306', 10),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'hostel_management',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  ...(process.env.DB_SSL_CA
    ? { ssl: { ca: process.env.DB_SSL_CA } }
    : {}),
};

export type DatabaseMode = 'mysql' | 'in_memory_simulation';
let currentMode: DatabaseMode = 'in_memory_simulation';
let connectionError: string | null = null;
let pool: mysql.Pool | null = null;

// Mock in-memory state initialized identically to database.sql for JKLU
export interface MockDBState {
  wardens: any[];
  hostels: any[];
  rooms: any[];
  students: any[];
  allocations: any[];
  staff: any[];
  fee_payments: any[];
  messes: any[];
  mess_menu_config: any[];
  register_complaints: any[];
  cleaning_register: any[];
  student_out_register: any[];
  late_night_entry: any[];
  attendance_register: any[];
  maintenance_register: any[];
  security_handover: any[];
  visitors: any[];
  visits: any[];
  complaints: any[];
  security_logs: any[];
  maintenance: any[];
}

const DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'] as const;
const MEALS = ['Breakfast', 'Lunch', 'Evening Snacks', 'Dinner'] as const;

const initialMessConfig: any[] = [];
let menuIdCounter = 1;
DAYS.forEach((day) => {
  MEALS.forEach((meal) => {
    initialMessConfig.push({
      menu_id: menuIdCounter++,
      day_of_week: day,
      meal_type: meal,
      menu_items: null, // "Menu not configured" until set
      meal_timing: null, // "Timings not configured" until set
      is_configured: false,
      last_updated_by: null,
      updated_at: new Date().toISOString(),
    });
  });
});

const mockState: MockDBState = {
  wardens: [
    {
      warden_id: 1,
      name: 'Dr. S. K. Sharma',
      email: 'chief.warden@jklu.edu.in',
      phone: '9829012340',
      role: 'Chief Warden',
      assigned_hostel: null, // Chief warden oversees all hostels
      plain_password: 'warden123',
      office_location: 'Administrative Block, Ground Floor Rm 104',
    },
    {
      warden_id: 2,
      name: 'Prof. Rekha Gupta',
      email: 'gh1.warden@jklu.edu.in',
      phone: '9829012341',
      role: 'Warden',
      assigned_hostel: 'GH1',
      plain_password: 'warden123',
      office_location: 'Girls Hostel 1 Warden Office',
    },
    {
      warden_id: 3,
      name: 'Dr. Meenakshi Pareek',
      email: 'gh2.warden@jklu.edu.in',
      phone: '9829012342',
      role: 'Warden',
      assigned_hostel: 'GH2',
      plain_password: 'warden123',
      office_location: 'Girls Hostel 2 Ground Floor Suite',
    },
    {
      warden_id: 4,
      name: 'Prof. Amit Joshi',
      email: 'bh1.warden@jklu.edu.in',
      phone: '9829012343',
      role: 'Warden',
      assigned_hostel: 'BH1',
      plain_password: 'warden123',
      office_location: 'Boys Hostel 1 Warden Office Room 02',
    },
    {
      warden_id: 5,
      name: 'Dr. Virendra Singh',
      email: 'bh2.warden@jklu.edu.in',
      phone: '9829012344',
      role: 'Warden',
      assigned_hostel: 'BH2',
      plain_password: 'warden123',
      office_location: 'Boys Hostel 2 Ground Floor Office',
    },
  ],
  hostels: [
    {
      hostel_id: 1,
      hostel_code: 'GH1',
      hostel_name: 'Girls Hostel 1 (GH1)',
      warden_id: 2,
      total_floors: 4,
      gender: 'Girls',
      address: 'JKLU Campus, South Residential Zone',
    },
    {
      hostel_id: 2,
      hostel_code: 'GH2',
      hostel_name: 'Girls Hostel 2 (GH2 - Flats)',
      warden_id: 3,
      total_floors: 4,
      gender: 'Girls',
      address: 'JKLU Campus, South Residential Zone',
    },
    {
      hostel_id: 3,
      hostel_code: 'BH1',
      hostel_name: 'Boys Hostel 1 (BH1)',
      warden_id: 4,
      total_floors: 4,
      gender: 'Boys',
      address: 'JKLU Campus, North Residential Zone',
    },
    {
      hostel_id: 4,
      hostel_code: 'BH2',
      hostel_name: 'Boys Hostel 2 (BH2)',
      warden_id: 5,
      total_floors: 4,
      gender: 'Boys',
      address: 'JKLU Campus, North Residential Zone',
    },
  ],
  rooms: [
    // GH1 (Standard room numbering)
    { room_id: 1, hostel_id: 1, hostel_code: 'GH1', room_number: '101', floor_number: 1, capacity: 2, current_occupancy: 2, status: 'Full', monthly_fee: 4800.00 },
    { room_id: 2, hostel_id: 1, hostel_code: 'GH1', room_number: '102', floor_number: 1, capacity: 2, current_occupancy: 1, status: 'Available', monthly_fee: 4800.00 },
    { room_id: 3, hostel_id: 1, hostel_code: 'GH1', room_number: '201', floor_number: 2, capacity: 2, current_occupancy: 0, status: 'Available', monthly_fee: 4800.00 },

    // GH2 (Flat-based room numbering: 101A, 101B, 101C, 101D...)
    { room_id: 4, hostel_id: 2, hostel_code: 'GH2', room_number: '101A', floor_number: 1, capacity: 2, current_occupancy: 2, status: 'Full', monthly_fee: 5200.00 },
    { room_id: 5, hostel_id: 2, hostel_code: 'GH2', room_number: '101B', floor_number: 1, capacity: 2, current_occupancy: 1, status: 'Available', monthly_fee: 5200.00 },
    { room_id: 6, hostel_id: 2, hostel_code: 'GH2', room_number: '101C', floor_number: 1, capacity: 2, current_occupancy: 0, status: 'Available', monthly_fee: 5200.00 },
    { room_id: 7, hostel_id: 2, hostel_code: 'GH2', room_number: '101D', floor_number: 1, capacity: 2, current_occupancy: 0, status: 'Available', monthly_fee: 5200.00 },
    { room_id: 8, hostel_id: 2, hostel_code: 'GH2', room_number: '201A', floor_number: 2, capacity: 2, current_occupancy: 0, status: 'Available', monthly_fee: 5200.00 },

    // BH1 (Standard room numbering)
    { room_id: 9, hostel_id: 3, hostel_code: 'BH1', room_number: '101', floor_number: 1, capacity: 2, current_occupancy: 2, status: 'Full', monthly_fee: 4800.00 },
    { room_id: 10, hostel_id: 3, hostel_code: 'BH1', room_number: '102', floor_number: 1, capacity: 2, current_occupancy: 1, status: 'Available', monthly_fee: 4800.00 },
    { room_id: 11, hostel_id: 3, hostel_code: 'BH1', room_number: '201', floor_number: 2, capacity: 2, current_occupancy: 0, status: 'Available', monthly_fee: 4800.00 },

    // BH2 (Standard room numbering)
    { room_id: 12, hostel_id: 4, hostel_code: 'BH2', room_number: '101', floor_number: 1, capacity: 2, current_occupancy: 1, status: 'Available', monthly_fee: 4800.00 },
    { room_id: 13, hostel_id: 4, hostel_code: 'BH2', room_number: '102', floor_number: 1, capacity: 2, current_occupancy: 0, status: 'Available', monthly_fee: 4800.00 },
  ],
  students: [
    {
      student_id: 1,
      student_code: '2025Btech224',
      name: 'Aarav Choudhary',
      email: 'aarav.choudhary@jklu.edu.in',
      phone: '9829011101',
      emergency_contact: '9829099901',
      department: 'Computer Science & Engineering',
      programme: 'B.Tech',
      year_of_study: 1,
      gender: 'Male',
      blood_group: 'O+',
      hostel_code: 'BH1',
      room_number: '101',
      plain_password: 'warden123',
    },
    {
      student_id: 2,
      student_code: '2024Btech102',
      name: 'Rohan Mehta',
      email: 'rohan.mehta@jklu.edu.in',
      phone: '9829011102',
      emergency_contact: '9829099902',
      department: 'Computer Science & Engineering',
      programme: 'B.Tech',
      year_of_study: 2,
      gender: 'Male',
      blood_group: 'B+',
      hostel_code: 'BH1',
      room_number: '101',
      plain_password: 'warden123',
    },
    {
      student_id: 3,
      student_code: '2024BBA015',
      name: 'Tanvi Mathur',
      email: 'tanvi.mathur@jklu.edu.in',
      phone: '9829011103',
      emergency_contact: '9829099903',
      department: 'Institute of Management',
      programme: 'BBA',
      year_of_study: 2,
      gender: 'Female',
      blood_group: 'A+',
      hostel_code: 'GH1',
      room_number: '101',
      plain_password: 'warden123',
    },
    {
      student_id: 4,
      student_code: '2024BDes008',
      name: 'Ishita Sharma',
      email: 'ishita.sharma@jklu.edu.in',
      phone: '9829011104',
      emergency_contact: '9829099904',
      department: 'Institute of Design',
      programme: 'B.Des',
      year_of_study: 2,
      gender: 'Female',
      blood_group: 'AB+',
      hostel_code: 'GH2',
      room_number: '101A',
      plain_password: 'warden123',
    },
    {
      student_id: 5,
      student_code: '2023Btech045',
      name: 'Kabir Verma',
      email: 'kabir.verma@jklu.edu.in',
      phone: '9829011105',
      emergency_contact: '9829099905',
      department: 'Mechanical Engineering',
      programme: 'B.Tech',
      year_of_study: 3,
      gender: 'Male',
      blood_group: 'O-',
      hostel_code: 'BH1',
      room_number: '102',
      plain_password: 'warden123',
    },
    {
      student_id: 6,
      student_code: '2025BDes019',
      name: 'Diya Khandelwal',
      email: 'diya.khandelwal@jklu.edu.in',
      phone: '9829011106',
      emergency_contact: '9829099906',
      department: 'Institute of Design',
      programme: 'B.Des',
      year_of_study: 1,
      gender: 'Female',
      blood_group: 'B+',
      hostel_code: 'GH2',
      room_number: '101A',
      plain_password: 'warden123',
    },
    {
      student_id: 7,
      student_code: null, // Unavailable - pending verification
      name: 'Gaurav Rathore',
      email: 'gaurav.rathore@jklu.edu.in',
      phone: '9829011107',
      emergency_contact: '9829099907',
      department: 'Computer Science & Engineering',
      programme: 'B.Tech',
      year_of_study: 1,
      gender: 'Male',
      blood_group: 'A-',
      hostel_code: 'BH2',
      room_number: '101',
      plain_password: 'warden123',
    },
  ],
  allocations: [
    { allocation_id: 1, student_id: 1, room_id: 9, start_date: '2024-07-25', end_date: null, status: 'Active', notes: 'BH1 Bed 1' },
    { allocation_id: 2, student_id: 2, room_id: 9, start_date: '2024-07-25', end_date: null, status: 'Active', notes: 'BH1 Bed 2' },
    { allocation_id: 3, student_id: 5, room_id: 10, start_date: '2024-08-01', end_date: null, status: 'Active', notes: 'BH1 Bed 1' },
    { allocation_id: 4, student_id: 3, room_id: 1, start_date: '2024-07-26', end_date: null, status: 'Active', notes: 'GH1 Bed 1' },
    { allocation_id: 5, student_id: 4, room_id: 4, start_date: '2024-07-26', end_date: null, status: 'Active', notes: 'GH2 Flat 101A Bed 1' },
    { allocation_id: 6, student_id: 6, room_id: 4, start_date: '2024-07-26', end_date: null, status: 'Active', notes: 'GH2 Flat 101A Bed 2' },
  ],
  staff: [
    { staff_id: 1, name: 'Mukesh Sharma', role: 'Electrician', phone: '9829100001', email: 'mukesh.electric@jklu.edu.in', shift_timing: '09:00 AM - 05:00 PM', hostel_id: null, salary: 26000.00 },
    { staff_id: 2, name: 'Suresh Gond', role: 'Plumber', phone: '9829100002', email: 'suresh.plumb@jklu.edu.in', shift_timing: '09:00 AM - 05:00 PM', hostel_id: null, salary: 25000.00 },
    { staff_id: 3, name: 'Rajesh Yadav', role: 'Security Guard', phone: '9829100003', email: 'rajesh.guard@jklu.edu.in', shift_timing: '06:00 AM - 02:00 PM', hostel_id: 3, salary: 22000.00 },
    { staff_id: 4, name: 'Mahesh Shinde', role: 'Security Guard', phone: '9829100004', email: 'mahesh.guard@jklu.edu.in', shift_timing: '02:00 PM - 10:00 PM', hostel_id: 3, salary: 22000.00 },
    { staff_id: 5, name: 'Sunita Devi', role: 'Housekeeping', phone: '9829100005', email: 'sunita.hk@jklu.edu.in', shift_timing: '07:30 AM - 03:30 PM', hostel_id: 1, salary: 19000.00 },
  ],
  fee_payments: [
    { payment_id: 1, student_id: 1, amount_paid: 4800.00, due_amount: 0.00, payment_date: '2024-10-02', payment_method: 'Online', transaction_reference: 'JKLU-TXN-1011', status: 'Paid', billing_month: 'October 2024', remarks: 'BH1 Room 101 Accommodation Fee' },
    { payment_id: 2, student_id: 3, amount_paid: 4800.00, due_amount: 0.00, payment_date: '2024-10-01', payment_method: 'Online', transaction_reference: 'JKLU-TXN-1012', status: 'Paid', billing_month: 'October 2024', remarks: 'GH1 Room 101 Fee' },
    { payment_id: 3, student_id: 4, amount_paid: 5200.00, due_amount: 0.00, payment_date: '2024-10-03', payment_method: 'Bank Transfer', transaction_reference: 'JKLU-NEFT-8891', status: 'Paid', billing_month: 'October 2024', remarks: 'GH2 Flat 101A Fee' },
  ],
  messes: [
    { mess_id: 1, hostel_id: 3, mess_name: 'JKLU Central Dining Hall (Mess 1)', caterer_name: 'Sodexo India Campus Dining', contact_number: '9829019991' },
    { mess_id: 2, hostel_id: 1, mess_name: 'JKLU South Campus Dining Hall (Mess 2)', caterer_name: 'Sodexo India Campus Dining', contact_number: '9829019992' },
  ],
  mess_menu_config: initialMessConfig,

  // Register Tables
  register_complaints: [
    {
      id: 1,
      complaint_date: '2024-10-10',
      student_name: 'Tanvi Mathur',
      student_roll_no: '2024BBA015',
      hostel_code: 'GH1',
      room_no: '101',
      complaint_type: 'Electrical',
      complaint_details: 'Ceiling fan capacitor making rattling noise and speed not regulating',
      status: 'Resolved',
      resolved_date: '2024-10-11',
      action_taken: 'Electrician replaced capacitor and switch',
    },
    {
      id: 2,
      complaint_date: '2024-10-12',
      student_name: 'Ishita Sharma',
      student_roll_no: '2024BDes008',
      hostel_code: 'GH2',
      room_no: '101A',
      complaint_type: 'Plumbing',
      complaint_details: 'Washroom faucet continuous drip in Flat 101A',
      status: 'In Progress',
      resolved_date: null,
      action_taken: 'Plumber visited, washer replacement parts requisitioned',
    },
    {
      id: 3,
      complaint_date: '2024-10-13',
      student_name: 'Aarav Choudhary',
      student_roll_no: '2025Btech224',
      hostel_code: 'BH1',
      room_no: '101',
      complaint_type: 'Wi-Fi/Internet',
      complaint_details: 'LAN port RJ45 clip broken in study cubicle',
      status: 'Pending',
      resolved_date: null,
      action_taken: null,
    },
    {
      id: 4,
      complaint_date: '2024-10-14',
      student_name: 'Gaurav Rathore',
      student_roll_no: null, // roll number unavailable
      hostel_code: 'BH2',
      room_no: '101',
      complaint_type: 'Carpentry',
      complaint_details: 'Wardrobe door hinges loosened and misaligned',
      status: 'Pending',
      resolved_date: null,
      action_taken: null,
    },
  ],
  cleaning_register: [
    {
      cleaning_id: 1,
      hostel_code: 'GH1',
      floor_or_area: 'Floor 1 Corridors & Washrooms',
      cleaner_name: 'Sunita Devi',
      cleaning_date: '2024-10-14',
      cleaning_time: '08:30:00',
      inspection_status: 'Satisfactory',
      remarks: 'Cleaned and sanitized with disinfectant',
      inspected_by: 'Warden Prof. Rekha Gupta',
    },
    {
      cleaning_id: 2,
      hostel_code: 'GH2',
      floor_or_area: 'Floor 1 Flats A-D Common Foyer',
      cleaner_name: 'Pooja Bai',
      cleaning_date: '2024-10-14',
      cleaning_time: '09:00:00',
      inspection_status: 'Satisfactory',
      remarks: 'Garbage cleared and floor mopped',
      inspected_by: 'Warden Dr. Meenakshi Pareek',
    },
    {
      cleaning_id: 3,
      hostel_code: 'BH1',
      floor_or_area: 'Ground Floor Wing A Washrooms',
      cleaner_name: 'Ramesh Lal',
      cleaning_date: '2024-10-14',
      cleaning_time: '07:45:00',
      inspection_status: 'Satisfactory',
      remarks: 'Deep cleaned and mirrors wiped',
      inspected_by: 'Warden Prof. Amit Joshi',
    },
    {
      cleaning_id: 4,
      hostel_code: 'BH2',
      floor_or_area: 'Floor 1 Lobby & Staircase',
      cleaner_name: 'Mohan Ram',
      cleaning_date: '2024-10-14',
      cleaning_time: '10:15:00',
      inspection_status: 'Needs Attention',
      remarks: 'Dust bin near water dispenser required emptying',
      inspected_by: 'Warden Dr. Virendra Singh',
    },
  ],
  student_out_register: [
    {
      out_id: 1,
      student_name: 'Aarav Choudhary',
      roll_no: '2025Btech224',
      hostel_code: 'BH1',
      room_no: '101',
      destination: 'Mahindra SEZ Tech Park',
      out_date: '2024-10-14',
      out_time: '16:30:00',
      expected_in_date: '2024-10-14',
      expected_in_time: '19:30:00',
      actual_in_date: '2024-10-14',
      actual_in_time: '19:15:00',
      contact_number: '9829011101',
      parent_consent_status: 'Approved',
      remarks: 'Attending academic coding workshop',
    },
    {
      out_id: 2,
      student_name: 'Tanvi Mathur',
      roll_no: '2024BBA015',
      hostel_code: 'GH1',
      room_no: '101',
      destination: 'Vaishali Nagar Jaipur',
      out_date: '2024-10-14',
      out_time: '15:00:00',
      expected_in_date: '2024-10-14',
      expected_in_time: '20:00:00',
      actual_in_date: '2024-10-14',
      actual_in_time: '19:50:00',
      contact_number: '9829011103',
      parent_consent_status: 'Approved',
      remarks: 'Purchased semester project textbooks',
    },
    {
      out_id: 3,
      student_name: 'Kabir Verma',
      roll_no: '2023Btech045',
      hostel_code: 'BH1',
      room_no: '102',
      destination: 'Mansarovar Metro Station',
      out_date: '2024-10-14',
      out_time: '18:00:00',
      expected_in_date: '2024-10-14',
      expected_in_time: '21:00:00',
      actual_in_date: null,
      actual_in_time: null,
      contact_number: '9829011105',
      parent_consent_status: 'Approved',
      remarks: 'Day outpass approved by warden',
    },
  ],
  late_night_entry: [
    {
      entry_id: 1,
      student_name: 'Kabir Verma',
      roll_no: '2023Btech045',
      hostel_code: 'BH1',
      room_no: '102',
      entry_date: '2024-10-13',
      entry_time: '22:45:00',
      reason_for_late: 'City bus delay on Ajmer Road route near toll plaza',
      guard_on_duty: 'Guard Rajesh Yadav',
      warden_notified: true,
      action_or_remarks: 'First delay warning noted on gate log',
    },
    {
      entry_id: 2,
      student_name: 'Gaurav Rathore',
      roll_no: null,
      hostel_code: 'BH2',
      room_no: '101',
      entry_date: '2024-10-12',
      entry_time: '23:10:00',
      reason_for_late: 'Delayed return from robotics laboratory prototype testing',
      guard_on_duty: 'Guard Mahesh Shinde',
      warden_notified: true,
      action_or_remarks: 'Lab supervisor confirmation verified',
    },
  ],
  attendance_register: [
    { attendance_id: 1, student_id: 1, student_name: 'Aarav Choudhary', roll_no: '2025Btech224', hostel_code: 'BH1', room_no: '101', date: '2024-10-14', status: 'Present', remarks: 'Present in room at 9:30 PM roll call', recorded_by: 'Prof. Amit Joshi' },
    { attendance_id: 2, student_id: 2, student_name: 'Rohan Mehta', roll_no: '2024Btech102', hostel_code: 'BH1', room_no: '101', date: '2024-10-14', status: 'Present', remarks: 'Present at roll call', recorded_by: 'Prof. Amit Joshi' },
    { attendance_id: 3, student_id: 3, student_name: 'Tanvi Mathur', roll_no: '2024BBA015', hostel_code: 'GH1', room_no: '101', date: '2024-10-14', status: 'Present', remarks: 'Present at roll call', recorded_by: 'Prof. Rekha Gupta' },
    { attendance_id: 4, student_id: 4, student_name: 'Ishita Sharma', roll_no: '2024BDes008', hostel_code: 'GH2', room_no: '101A', date: '2024-10-14', status: 'Present', remarks: 'Present in Flat 101A', recorded_by: 'Dr. Meenakshi Pareek' },
    { attendance_id: 5, student_id: 5, student_name: 'Kabir Verma', roll_no: '2023Btech045', hostel_code: 'BH1', room_no: '102', date: '2024-10-14', status: 'Present', remarks: 'Present at roll call', recorded_by: 'Prof. Amit Joshi' },
    { attendance_id: 6, student_id: 6, student_name: 'Diya Khandelwal', roll_no: '2025BDes019', hostel_code: 'GH2', room_no: '101A', date: '2024-10-14', status: 'Present', remarks: 'Present in Flat 101A', recorded_by: 'Dr. Meenakshi Pareek' },
  ],
  maintenance_register: [
    {
      maint_id: 1,
      hostel_code: 'GH1',
      location_or_room: 'Room 101',
      issue_description: 'Ceiling fan capacitor replacement',
      work_type: 'Electrical',
      reported_date: '2024-10-10',
      assigned_worker: 'Mukesh Sharma (Electrician)',
      completion_status: 'Completed',
      completed_date: '2024-10-11',
      cost: 250.00,
    },
    {
      maint_id: 2,
      hostel_code: 'GH2',
      location_or_room: 'Flat 101A Washroom',
      issue_description: 'Water valve leakage repair',
      work_type: 'Plumbing',
      reported_date: '2024-10-12',
      assigned_worker: 'Suresh Gond (Plumber)',
      completion_status: 'In Progress',
      completed_date: null,
      cost: 300.00,
    },
    {
      maint_id: 3,
      hostel_code: 'BH1',
      location_or_room: 'Room 101',
      issue_description: 'Network port recrimping',
      work_type: 'Other',
      reported_date: '2024-10-13',
      assigned_worker: 'Campus IT Support',
      completion_status: 'Pending',
      completed_date: null,
      cost: 0.00,
    },
    {
      maint_id: 4,
      hostel_code: 'BH2',
      location_or_room: 'Ground Floor Corridor',
      issue_description: 'LED tube light flickering near entry gate',
      work_type: 'Electrical',
      reported_date: '2024-10-14',
      assigned_worker: 'Mukesh Sharma (Electrician)',
      completion_status: 'Pending',
      completed_date: null,
      cost: 400.00,
    },
  ],
  security_handover: [
    {
      handover_id: 1,
      hostel_code: 'GH1',
      handover_date: '2024-10-14',
      shift: 'Morning (06:00 - 14:00)',
      outgoing_guard: 'Rajendra Meena',
      incoming_guard: 'Kailash Chand',
      keys_status: 'All room & gate keys accounted for',
      incident_summary: 'Calm shift, no unauthorized entries recorded',
      verified_by_warden: true,
    },
    {
      handover_id: 2,
      hostel_code: 'GH2',
      handover_date: '2024-10-14',
      shift: 'Morning (06:00 - 14:00)',
      outgoing_guard: 'Kiran Devi',
      incoming_guard: 'Sunita Gurjar',
      keys_status: 'All flat keys and emergency master key intact',
      incident_summary: 'No untoward incidents observed',
      verified_by_warden: true,
    },
    {
      handover_id: 3,
      hostel_code: 'BH1',
      handover_date: '2024-10-14',
      shift: 'Evening (14:00 - 22:00)',
      outgoing_guard: 'Rajesh Yadav',
      incoming_guard: 'Mahesh Shinde',
      keys_status: 'All room & gate keys accounted for',
      incident_summary: 'Evening roll-call gate movement verified',
      verified_by_warden: true,
    },
    {
      handover_id: 4,
      hostel_code: 'BH2',
      handover_date: '2024-10-14',
      shift: 'Morning (06:00 - 14:00)',
      outgoing_guard: 'Mahesh Shinde',
      incoming_guard: 'Dinesh Kumar',
      keys_status: 'All keys present and verified',
      incident_summary: 'Courier parcel deliveries logged at gate',
      verified_by_warden: true,
    },
  ],
  visitors: [
    { visitor_id: 1, full_name: 'Mr. Rajesh Choudhary', phone: '9829099901', id_proof_type: 'Aadhaar', id_proof_number: 'XXXX-XXXX-1234', address: 'Ajmer, Rajasthan' },
    { visitor_id: 2, full_name: 'Mrs. Sunita Mathur', phone: '9829099903', id_proof_type: 'Aadhaar', id_proof_number: 'XXXX-XXXX-5678', address: 'Kota, Rajasthan' },
  ],
  visits: [
    { visit_id: 1, visitor_id: 1, student_id: 1, hostel_id: 3, check_in: '2024-10-14 10:30:00', check_out: '2024-10-14 12:00:00', relation_to_student: 'Father', purpose: 'Semester fee discussion', status: 'Completed', guard_name: 'Rajesh Yadav' },
    { visit_id: 2, visitor_id: 2, student_id: 3, hostel_id: 1, check_in: '2024-10-14 15:00:00', check_out: null, relation_to_student: 'Mother', purpose: 'Delivering winter apparel', status: 'Inside', guard_name: 'Rajesh Yadav' },
  ],
  complaints: [
    { complaint_id: 1, student_id: 3, category: 'Electrical', title: 'Study table reading lamp socket sparking', description: 'Room 101 plug point sparking when laptop charger plugged in', priority: 'High', status: 'Pending', assigned_staff_name: 'Mukesh Sharma', resolution_remarks: null, created_at: '2024-10-10' },
    { complaint_id: 2, student_id: 4, category: 'Plumbing', title: 'Flat 101A washroom cold water tap dripping', description: 'Continuous water drip in washroom tap', priority: 'Medium', status: 'In Progress', assigned_staff_name: 'Suresh Gond', resolution_remarks: 'Gasket replacement scheduled', created_at: '2024-10-12' },
  ],
  security_logs: [
    { log_id: 1, student_id: 5, event_type: 'Entry', destination: 'Local Market', reason: 'City bus delay', is_late_entry: true, logged_at: '2024-10-13 22:45:00', guard_name: 'Rajesh Yadav' },
    { log_id: 2, student_id: 1, event_type: 'Exit', destination: 'Mahindra SEZ Tech Park', reason: 'Coding workshop', is_late_entry: false, logged_at: '2024-10-14 16:30:00', guard_name: 'Rajesh Yadav' },
  ],
  maintenance: [
    { maint_id: 1, room_id: 1, hostel_id: 1, description: 'Ceiling fan capacitor replacement', status: 'Completed', cost: 250.00, scheduled_date: '2024-10-10', completed_date: '2024-10-11', worker_name: 'Mukesh Sharma' },
    { maint_id: 2, room_id: 4, hostel_id: 2, description: 'Water valve leakage repair', status: 'In Progress', cost: 300.00, scheduled_date: '2024-10-12', completed_date: null, worker_name: 'Suresh Gond' },
  ],
};

export async function initDatabaseConnection(): Promise<void> {
  try {
    pool = mysql.createPool(dbConfig);
    const connection = await pool.getConnection();
    await connection.ping();
    connection.release();
    currentMode = 'mysql';
    connectionError = null;
    console.log(`[JKLU Hostel DBMS] Connected successfully to MySQL at ${dbConfig.host}:${dbConfig.port}/${dbConfig.database}`);
  } catch (err: any) {
    currentMode = 'in_memory_simulation';
    connectionError = err.message || 'MySQL unreachable';
    console.warn(`[JKLU Hostel DBMS] MySQL Connection Notice: ${connectionError}`);
    console.warn(`[JKLU Hostel DBMS] Running in simulation mode pre-seeded with JKLU 4 hostels (GH1, GH2, BH1, BH2) and register tables.`);
    console.warn(`[JKLU Hostel DBMS] To switch to live MySQL: execute database.sql in MySQL Workbench on localhost:${dbConfig.port}.`);
  }
}

export function getDatabaseStatus() {
  return {
    mode: currentMode,
    isMySQL: currentMode === 'mysql',
    config: {
      host: dbConfig.host,
      port: dbConfig.port,
      database: dbConfig.database,
      user: dbConfig.user,
    },
    error: connectionError,
    hostels: ['GH1', 'GH2', 'BH1', 'BH2'],
  };
}

export function getPool(): mysql.Pool | null {
  return pool;
}

export function getMockState(): MockDBState {
  return mockState;
}
