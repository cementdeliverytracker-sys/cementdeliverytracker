# Quick Test Guide - Attendance System

## Prerequisites

- Firebase project configured
- Google Maps API key added
- App built and running on emulator/device

## Test Scenario 1: Admin Sets Location (First Time)

1. **Login as Admin**
   - Use admin credentials
2. **Navigate to Settings**
   - Tap Settings icon in bottom navigation
3. **Go to Location Tab**
   - Tap "Location" tab
4. **Pick Location**
   - Tap "Pick Location from Map" button
   - Grant location permission if prompted
   - Map opens with your current location marked
   - Drag marker to desired enterprise location
   - Tap "Confirm" button
5. **Verify Auto-Fill**
   - Address fields should auto-populate
   - Verify accuracy of city, state, ZIP, country
6. **Save Location**
   - Tap "Save Location" button
   - Wait for success message
7. **Verify Lock**
   - Refresh the screen
   - Green banner should appear: "Location already set. Cannot be changed."
   - All input fields should be disabled (grayed out)
   - "Pick Location from Map" button disabled
   - Save button shows "Location Already Set" and is disabled

## Test Scenario 2: Employee Stamps Login (Within Range)

1. **Login as Employee**
   - Use employee credentials that belong to the admin who set location
2. **View Dashboard**
   - Dashboard shows "Not Logged In" status
   - Orange badge indicates not logged in
   - "Stamp Login" button is enabled
3. **Move to Workplace**
   - Ensure you are within 100 meters of admin's set location
   - (For testing, you can use the same device/emulator)
4. **Stamp Login**
   - Tap "Stamp Login" button
   - Grant location permission if prompted
   - Wait for GPS to acquire location
5. **Verify Success**
   - Success message: "Login stamped successfully"
   - Status card changes to "Logged In" with green badge
   - Login time displays (e.g., "09:30 AM")
   - Date displays (e.g., "January 15, 2025")
   - Button now shows "Already Logged In Today" and is disabled
6. **Check History**
   - Scroll down to "Recent Attendance"
   - Today's entry should appear at top
   - Shows date, time, and distance

## Test Scenario 3: Employee Tries to Login (Outside Range)

1. **Setup**
   - Employee already logged in previously OR
   - Use different device/location far from admin's location
2. **Attempt Login**
   - Tap "Stamp Login" button
3. **Verify Error**
   - Error message: "You must be within 100 meters of your workplace to stamp your login. Distance: XXX.XX meters"
   - Status remains "Not Logged In"
   - Button remains enabled for retry

## Test Scenario 4: Employee Tries to Login Twice Same Day

1. **First Login**
   - Complete successful login (Scenario 2)
2. **Logout and Login Again**
   - Logout from app
   - Login again as same employee
3. **Verify UI State**
   - Dashboard should show "Logged In" status
   - Button already disabled with "Already Logged In Today"
4. **Try Force Click (if somehow enabled)**
   - Error: "You have already logged in today"

## Test Scenario 5: Admin Views All Attendance

This feature is not implemented in UI yet, but you can verify in Firestore:

1. **Open Firebase Console**
   - Go to Firestore Database
2. **Navigate to attendance_logs**
   - You should see documents with:
     - employeeId
     - adminId
     - timestamp
     - location (with latitude, longitude, distance)
     - status: "logged_in"

## Expected Firestore Data

### After Admin Sets Location:

```
enterprises/{adminId}:
{
  "location": {
    "address": "123 Main Street, Downtown",
    "city": "Mumbai",
    "state": "Maharashtra",
    "zipCode": "400001",
    "country": "India",
    "latitude": 19.0760,
    "longitude": 72.8777
  },
  "locationSet": true,
  "locationSetAt": Timestamp,
  ...other fields
}
```

### After Employee Stamps Login:

```
attendance_logs/{logId}:
{
  "employeeId": "employee123",
  "adminId": "admin123",
  "timestamp": Timestamp,
  "location": {
    "latitude": 19.0761,
    "longitude": 72.8778,
    "adminLatitude": 19.0760,
    "adminLongitude": 72.8777,
    "distance": 12.45
  },
  "status": "logged_in",
  "createdAt": Timestamp
}

users/{employeeId}:
{
  "status": "logged_in",
  "lastLoginTime": Timestamp,
  ...other fields
}
```

## Common Issues & Troubleshooting

### Issue: "Location permission denied"

**Solution**:

- Go to device Settings → Apps → Cement Delivery Tracker → Permissions
- Enable Location permission
- Set to "Allow all the time" or "Allow only while using the app"

### Issue: "Admin location not set"

**Solution**:

- Login as admin first
- Complete location setup (Scenario 1)
- Logout and login as employee

### Issue: Map doesn't load

**Solution**:

- Verify Google Maps API key in AndroidManifest.xml
- Check Google Cloud Console that Maps SDK is enabled
- Verify API key has no restrictions blocking the app

### Issue: "Distance: 0.00 meters" in attendance log

**Solution**:

- This is expected when testing on emulator with same coordinates
- On real devices at different locations, distance will be accurate

### Issue: Can't login even though nearby

**Solution**:

- GPS accuracy varies, wait a few seconds for GPS lock
- Try moving outside and try again (better GPS signal)
- Check if admin's location is correctly set

### Issue: Time showing wrong timezone

**Solution**:

- The system uses IST (UTC+5:30)
- Device timezone doesn't matter
- Verify Firestore timestamp is correct

## Testing with Multiple Employees

1. Create multiple employee accounts under same admin
2. Login with each employee on different days
3. Verify each has independent attendance tracking
4. Check that each can only see their own attendance history
5. Verify admin can see all employees' attendance (via Firestore for now)

## Performance Testing

1. **Large Attendance History**
   - Add attendance for 30+ days
   - Verify scrolling is smooth
   - Check if StreamBuilder handles updates efficiently

2. **Multiple Simultaneous Logins**
   - Have multiple employees login at same time
   - Verify no conflicts
   - Check Firestore write performance

## Security Testing

1. **Try to modify attendance via API**
   - Use Firestore REST API or console
   - Try to create log with different employeeId
   - Should be blocked by security rules

2. **Try to change location after setting**
   - Login as admin who already set location
   - Try to update location in Firestore console
   - Should be blocked by rules (or show error in app)

3. **Try to login for another employee**
   - Login as employee A
   - Try to create attendance log with employee B's ID
   - Should be blocked by rules

## Test Report Template

After testing, document results:

```
Test Date: _________
Tester: _________

[ ] Scenario 1: Admin Location Setup - PASS/FAIL
    Notes: _______________________________

[ ] Scenario 2: Employee Login (In Range) - PASS/FAIL
    Distance Measured: _______ meters
    Notes: _______________________________

[ ] Scenario 3: Employee Login (Out of Range) - PASS/FAIL
    Distance Measured: _______ meters
    Error Message: ___________________________

[ ] Scenario 4: Duplicate Login Prevention - PASS/FAIL
    Notes: _______________________________

[ ] Scenario 5: Firestore Data Verification - PASS/FAIL
    Notes: _______________________________

Issues Found:
1. _______________________________________
2. _______________________________________

Suggestions:
1. _______________________________________
2. _______________________________________
```

## Next Steps After Testing

1. **If all tests pass**: Deploy to production
2. **If issues found**: Report to development team with test results
3. **Feature requests**: Document in separate file
4. **Performance issues**: Check logs, optimize queries

## Contact

For issues or questions during testing, refer to:

- ATTENDANCE_SYSTEM_IMPLEMENTATION.md for technical details
- Firebase Console for data verification
- Flutter logs for debugging
