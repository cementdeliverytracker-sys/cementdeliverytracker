#!/usr/bin/env node

// Migration script to add adminId to all visits documents
// Usage: node scripts/migrate_visits_add_adminid.js

const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const fs = require("fs");
const os = require("os");
const path = require("path");

// Try to get credentials from Firebase CLI or environment
let credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

if (!credentialsPath) {
  // Try common Firebase credential locations
  const commonPaths = [
    path.join(
      os.homedir(),
      ".config/gcloud/application_default_credentials.json",
    ),
    path.join(os.homedir(), ".cache/firebase/credentials.json"),
    "firebase-key.json",
    ".env.firebasekey",
  ];

  for (const p of commonPaths) {
    if (fs.existsSync(p)) {
      credentialsPath = p;
      break;
    }
  }
}

let app;
if (credentialsPath && fs.existsSync(credentialsPath)) {
  const serviceAccount = JSON.parse(fs.readFileSync(credentialsPath, "utf8"));
  app = initializeApp({
    credential: cert(serviceAccount),
  });
} else {
  // Use default credentials (Firebase CLI)
  app = initializeApp({
    projectId: "cement-delivery-tracker-72de2",
  });
}

const db = getFirestore(app);
const BATCH_SIZE = 500;

async function migrateVisits() {
  console.log("Starting migration: Adding adminId to visits...\n");

  try {
    // Get all visits
    const visitsSnapshot = await db.collection("visits").get();
    console.log(`Found ${visitsSnapshot.size} visits to process\n`);

    if (visitsSnapshot.empty) {
      console.log("No visits found. Migration complete.");
      process.exit(0);
    }

    let processed = 0;
    let updated = 0;
    let errors = 0;
    let batch = db.batch();

    for (const visitDoc of visitsSnapshot.docs) {
      const visitData = visitDoc.data();

      // Skip if adminId already exists
      if (visitData.adminId) {
        console.log(
          `✓ [${processed + 1}/${visitsSnapshot.size}] Visit ${visitDoc.id} already has adminId: ${visitData.adminId}`,
        );
        processed++;
        continue;
      }

      try {
        // Get the employee's adminId
        const employeeDoc = await db
          .collection("users")
          .doc(visitData.employeeId)
          .get();

        if (!employeeDoc.exists) {
          console.warn(
            `✗ [${processed + 1}/${visitsSnapshot.size}] Employee ${visitData.employeeId} not found for visit ${visitDoc.id}`,
          );
          errors++;
          processed++;
          continue;
        }

        const employeeData = employeeDoc.data();
        const adminId = employeeData.adminId;

        if (!adminId) {
          console.warn(
            `✗ [${processed + 1}/${visitsSnapshot.size}] Employee ${visitData.employeeId} has no adminId for visit ${visitDoc.id}`,
          );
          errors++;
          processed++;
          continue;
        }

        // Add update to batch
        batch.update(visitDoc.ref, { adminId });
        updated++;
        console.log(
          `✓ [${processed + 1}/${visitsSnapshot.size}] Visit ${visitDoc.id} → adminId: ${adminId}`,
        );

        // Commit batch when it reaches the size limit
        if (updated % BATCH_SIZE === 0) {
          await batch.commit();
          console.log(`\n  ✔ Committed batch of ${BATCH_SIZE} updates\n`);
          batch = db.batch();
        }

        processed++;
      } catch (error) {
        console.error(
          `✗ [${processed + 1}/${visitsSnapshot.size}] Error processing visit ${visitDoc.id}:`,
          error.message,
        );
        errors++;
        processed++;
      }
    }

    // Commit remaining updates
    if (updated % BATCH_SIZE !== 0) {
      await batch.commit();
      console.log(
        `\n✔ Committed final batch of ${updated % BATCH_SIZE} updates`,
      );
    }

    console.log(`\n${"=".repeat(60)}`);
    console.log(`Migration Summary:`);
    console.log(`  Total visits:   ${visitsSnapshot.size}`);
    console.log(`  Updated:        ${updated}`);
    console.log(`  Errors:         ${errors}`);
    console.log(`  Already had ID: ${visitsSnapshot.size - updated - errors}`);
    console.log(`${"=".repeat(60)}\n`);

    process.exit(0);
  } catch (error) {
    console.error("Migration failed:", error);
    process.exit(1);
  }
}

migrateVisits();
