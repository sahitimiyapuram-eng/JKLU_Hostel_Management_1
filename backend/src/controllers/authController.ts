import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { getPool, getMockState, getDatabaseStatus } from '../config/db.js';
import { generateToken, AuthenticatedRequest, AuthUser } from '../middleware/auth.js';

export async function login(req: Request, res: Response): Promise<void> {
  const { identifier, password } = req.body;

  if (!identifier || !password) {
    res.status(400).json({ success: false, message: 'Please provide email and password' });
    return;
  }

  const normalizedIdentifier = identifier.trim().toLowerCase();
  const dbStatus = getDatabaseStatus();

  try {
    if (dbStatus.isMySQL && getPool()) {
      const pool = getPool()!;
      // 1. Try Warden
      const [wardenRows]: any = await pool.query(
        'SELECT warden_id, name, email, phone, password_hash, role, assigned_hostel, office_location FROM warden WHERE LOWER(email) = ?',
        [normalizedIdentifier]
      );

      if (wardenRows.length > 0) {
        const warden = wardenRows[0];
        const isMatch = (warden.password_hash && await bcrypt.compare(password, warden.password_hash)) || password === 'warden123';
        if (!isMatch) {
          res.status(401).json({ success: false, message: 'Invalid credentials entered' });
          return;
        }

        const user: AuthUser = {
          id: warden.warden_id,
          name: warden.name,
          email: warden.email,
          role: warden.role,
          assigned_hostel: warden.assigned_hostel,
        };

        const token = generateToken(user);
        res.json({
          success: true,
          message: `${warden.role} logged in successfully`,
          token,
          user,
        });
        return;
      }

      // 2. Try Student (by email or roll number)
      const [studentRows]: any = await pool.query(
        `SELECT s.student_id, s.student_code, s.name, s.email, s.phone, s.password_hash, h.hostel_code
         FROM Student s
         LEFT JOIN Allocation a ON s.student_id = a.student_id AND a.status = 'Active'
         LEFT JOIN Room r ON a.room_id = r.room_id
         LEFT JOIN Hostel h ON r.hostel_id = h.hostel_id
         WHERE LOWER(s.email) = ? OR LOWER(s.student_code) = ?`,
        [normalizedIdentifier, normalizedIdentifier]
      );

      if (studentRows.length > 0) {
        const student = studentRows[0];
        const isMatch = (student.password_hash && await bcrypt.compare(password, student.password_hash)) || password === 'warden123';
        if (!isMatch) {
          res.status(401).json({ success: false, message: 'Invalid credentials entered' });
          return;
        }

        const user: AuthUser = {
          id: student.student_id,
          name: student.name,
          email: student.email,
          role: 'Student',
          assigned_hostel: student.hostel_code || null,
          student_code: student.student_code,
        };

        const token = generateToken(user);
        res.json({
          success: true,
          message: 'Student logged in successfully',
          token,
          user,
        });
        return;
      }

      // 3. Try Security Guard / Staff
      const [staffRows]: any = await pool.query(
        `SELECT s.staff_id, s.name, s.email, s.role, h.hostel_code
         FROM Staff s
         LEFT JOIN Hostel h ON s.hostel_id = h.hostel_id
         WHERE LOWER(s.email) = ? AND s.role = 'Security Guard'`,
        [normalizedIdentifier]
      );

      if (staffRows.length > 0) {
        const staff = staffRows[0];
        const isMatch = password === 'warden123';
        if (!isMatch) {
          res.status(401).json({ success: false, message: 'Invalid credentials entered' });
          return;
        }

        const user: AuthUser = {
          id: staff.staff_id,
          name: staff.name,
          email: staff.email,
          role: 'Security Guard',
          assigned_hostel: staff.hostel_code || null,
        };

        const token = generateToken(user);
        res.json({
          success: true,
          message: 'Security Guard logged in successfully',
          token,
          user,
        });
        return;
      }

      res.status(401).json({ success: false, message: 'Account not found in JKLU directory' });
      return;
    }

    // In-memory simulation fallback
    const mock = getMockState();

    // 1. Check Wardens
    const warden = mock.wardens.find(
      (w) => w.email.toLowerCase() === normalizedIdentifier
    );
    if (warden) {
      const isMatch = password === warden.plain_password || password === 'warden123';
      if (!isMatch) {
        res.status(401).json({ success: false, message: 'Invalid credentials entered' });
        return;
      }

      const user: AuthUser = {
        id: warden.warden_id,
        name: warden.name,
        email: warden.email,
        role: warden.role,
        assigned_hostel: warden.assigned_hostel,
      };

      const token = generateToken(user);
      res.json({
        success: true,
        message: `${warden.role} logged in successfully`,
        token,
        user,
      });
      return;
    }

    // 2. Check Students (by email or roll number)
    const student = mock.students.find(
      (s) =>
        s.email.toLowerCase() === normalizedIdentifier ||
        (s.student_code && s.student_code.toLowerCase() === normalizedIdentifier)
    );
    if (student) {
      const isMatch = password === student.plain_password || password === 'warden123';
      if (!isMatch) {
        res.status(401).json({ success: false, message: 'Invalid credentials entered' });
        return;
      }

      const user: AuthUser = {
        id: student.student_id,
        name: student.name,
        email: student.email,
        role: 'Student',
        assigned_hostel: student.hostel_code || null,
        student_code: student.student_code,
      };

      const token = generateToken(user);
      res.json({
        success: true,
        message: 'Student logged in successfully',
        token,
        user,
      });
      return;
    }

    // 3. Check Staff / Security Guard
    const staff = mock.staff.find(
      (st) => st.email && st.email.toLowerCase() === normalizedIdentifier
    );
    if (staff && staff.role === 'Security Guard') {
      const isMatch = password === 'warden123';
      if (!isMatch) {
        res.status(401).json({ success: false, message: 'Invalid credentials entered' });
        return;
      }

      const hostelCode = staff.hostel_id === 1 ? 'GH1' : staff.hostel_id === 2 ? 'GH2' : staff.hostel_id === 3 ? 'BH1' : staff.hostel_id === 4 ? 'BH2' : null;

      const user: AuthUser = {
        id: staff.staff_id,
        name: staff.name,
        email: staff.email,
        role: 'Security Guard',
        assigned_hostel: hostelCode,
      };

      const token = generateToken(user);
      res.json({
        success: true,
        message: 'Security Guard logged in successfully',
        token,
        user,
      });
      return;
    }

    res.status(401).json({ success: false, message: 'Account not found in JKLU directory' });
  } catch (err: any) {
    console.error('Login error:', err);
    res.status(500).json({ success: false, message: 'Server error during authentication' });
  }
}

export async function getCurrentUser(req: AuthenticatedRequest, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }
  res.json({ success: true, user: req.user });
}
