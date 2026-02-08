#!/usr/bin/env python3
"""
Migration script to add adminId to all visits documents in Firestore.
Requires: firebase-admin, google-cloud-firestore
Install: pip3 install firebase-admin google-cloud-firestore
Run: python3 scripts/migrate_visits_add_adminid.py
"""

import json
import os
import sys
from pathlib import Path

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("❌ Missing required packages. Install with:")
    print("   pip3 install firebase-admin google-cloud-firestore")
    sys.exit(1)


def find_service_account():
    """Find Firebase service account JSON file."""
    possible_paths = [
        Path.home() / ".config/firebase/cement-delivery-tracker-72de2-key.json",
        Path.home() / ".firebase/cement-delivery-tracker-72de2-key.json",
        Path("firebase-key.json"),
        Path(".env.firebase"),
    ]
    
    for path in possible_paths:
        if path.exists():
            return str(path)
    
    # Check environment variable
    if "FIREBASE_SERVICE_ACCOUNT" in os.environ:
        return os.environ["FIREBASE_SERVICE_ACCOUNT"]
    
    return None


def initialize_firebase():
    """Initialize Firebase Admin SDK."""
    # Try to use service account
    service_account_path = find_service_account()
    
    if service_account_path:
        print(f"✓ Using service account: {service_account_path}")
        cred = credentials.Certificate(service_account_path)
    else:
        # Use Application Default Credentials (from gcloud or environment)
        print("ℹ Using Application Default Credentials")
        cred = credentials.ApplicationDefault()
    
    firebase_admin.initialize_app(cred, {
        "projectId": "cement-delivery-tracker-72de2"
    })
    
    return firestore.client()


def migrate_visits(db):
    """Add adminId to all visits documents."""
    print("\nStarting migration: Adding adminId to visits...\n")
    
    try:
        # Get all visits
        visits_ref = db.collection("visits")
        docs = visits_ref.stream()
        
        visits_list = list(docs)
        total = len(visits_list)
        
        print(f"Found {total} visits to process\n")
        
        if total == 0:
            print("✓ No visits found. Migration complete.")
            return
        
        processed = 0
        updated = 0
        errors = 0
        
        for doc in visits_list:
            visit_id = doc.id
            visit_data = doc.to_dict()
            processed += 1
            
            # Skip if adminId already exists
            if "adminId" in visit_data:
                print(f"✓ [{processed}/{total}] Visit {visit_id} already has adminId: {visit_data['adminId']}")
                continue
            
            try:
                # Get employee's adminId
                employee_id = visit_data.get("employeeId")
                if not employee_id:
                    print(f"✗ [{processed}/{total}] Visit {visit_id} has no employeeId")
                    errors += 1
                    continue
                
                employee_doc = db.collection("users").document(employee_id).get()
                
                if not employee_doc.exists:
                    print(f"✗ [{processed}/{total}] Employee {employee_id} not found for visit {visit_id}")
                    errors += 1
                    continue
                
                employee_data = employee_doc.to_dict()
                admin_id = employee_data.get("adminId")
                
                if not admin_id:
                    print(f"✗ [{processed}/{total}] Employee {employee_id} has no adminId for visit {visit_id}")
                    errors += 1
                    continue
                
                # Update visit with adminId
                db.collection("visits").document(visit_id).update({
                    "adminId": admin_id
                })
                
                updated += 1
                print(f"✓ [{processed}/{total}] Visit {visit_id} → adminId: {admin_id}")
                
            except Exception as e:
                print(f"✗ [{processed}/{total}] Error processing visit {visit_id}: {str(e)}")
                errors += 1
        
        # Print summary
        print(f"\n{'='*60}")
        print("Migration Summary:")
        print(f"  Total visits:   {total}")
        print(f"  Updated:        {updated}")
        print(f"  Errors:         {errors}")
        print(f"  Already had ID: {total - updated - errors}")
        print(f"{'='*60}\n")
        
    except Exception as e:
        print(f"❌ Migration failed: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    try:
        db = initialize_firebase()
        migrate_visits(db)
        print("✓ Migration complete!")
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        print("\nTo use this script:")
        print("1. Install dependencies: pip3 install firebase-admin")
        print("2. Set up credentials:")
        print("   - Option A: Download service account key from Firebase Console")
        print("     Place at: ~/.firebase/cement-delivery-tracker-72de2-key.json")
        print("   - Option B: Use gcloud auth application-default login")
        sys.exit(1)
