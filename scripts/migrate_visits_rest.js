#!/usr/bin/env node

// Migration script using Firebase REST API
// Requires: Firebase CLI authenticated (firebase login)

const https = require("https");
const fs = require("fs");
const path = require("path");

const PROJECT_ID = "cement-delivery-tracker-72de2";
const FIRESTORE_DB = "(default)";

// Read firebase config from web config if available
let webConfig = null;
try {
  webConfig = JSON.parse(
    fs.readFileSync(
      path.join(__dirname, "../web/firebase-config.json"),
      "utf8",
    ),
  );
} catch (e) {
  console.warn("Warning: Could not read firebase-config.json");
}

async function getAuthToken() {
  // For Firebase REST API, we'll use Application Default Credentials
  // via gcloud if available
  return new Promise((resolve, reject) => {
    const child_process = require("child_process");
    child_process.exec(
      "gcloud auth application-default print-access-token",
      (error, stdout, stderr) => {
        if (error || !stdout) {
          // Fallback: use firebase CLI token
          child_process.exec(
            "firebase login:ci 2>/dev/null || echo ''",
            (err, token) => {
              if (token) {
                resolve(token.trim());
              } else {
                reject(
                  new Error(
                    "Could not get authentication token. Try: gcloud auth application-default login",
                  ),
                );
              }
            },
          );
        } else {
          resolve(stdout.trim());
        }
      },
    );
  });
}

async function firebaseRequest(method, path, body = null) {
  const token = await getAuthToken();

  return new Promise((resolve, reject) => {
    const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/${FIRESTORE_DB}/documents${path}`;

    const options = {
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    };

    const req = https.request(url, options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode, data });
        }
      });
    });

    req.on("error", reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function migrateVisits() {
  console.log("Starting migration: Adding adminId to visits...\n");

  try {
    // Get all visits using Firestore REST API
    const response = await firebaseRequest("GET", "/visits?pageSize=10000");

    if (response.status !== 200) {
      throw new Error(
        `Failed to fetch visits: ${response.status} - ${JSON.stringify(response.data)}`,
      );
    }

    const documents = response.data.documents || [];
    console.log(`Found ${documents.length} visits\n`);

    let processed = 0;
    let updated = 0;
    let errors = 0;

    for (const doc of documents) {
      const visitId = doc.name.split("/").pop();
      const visitData = {};

      // Parse Firestore document structure
      if (doc.fields) {
        Object.keys(doc.fields).forEach((key) => {
          const field = doc.fields[key];
          if (field.stringValue) visitData[key] = field.stringValue;
          else if (field.booleanValue !== undefined)
            visitData[key] = field.booleanValue;
          // Add more field types as needed
        });
      }

      if (visitData.adminId) {
        console.log(
          `✓ [${processed + 1}/${documents.length}] Visit ${visitId} already has adminId`,
        );
        processed++;
        continue;
      }

      try {
        // Get employee data
        const employeeRes = await firebaseRequest(
          "GET",
          `/users/${visitData.employeeId}`,
        );

        if (employeeRes.status !== 200 || !employeeRes.data.fields) {
          console.warn(
            `✗ [${processed + 1}/${documents.length}] Employee ${visitData.employeeId} not found`,
          );
          errors++;
          processed++;
          continue;
        }

        const adminId = employeeRes.data.fields.adminId?.stringValue;

        if (!adminId) {
          console.warn(
            `✗ [${processed + 1}/${documents.length}] Employee has no adminId`,
          );
          errors++;
          processed++;
          continue;
        }

        // Update visit with adminId
        const updateRes = await firebaseRequest("PATCH", `/visits/${visitId}`, {
          fields: { adminId: { stringValue: adminId } },
        });

        if (updateRes.status !== 200) {
          throw new Error(`Update failed: ${updateRes.status}`);
        }

        updated++;
        console.log(
          `✓ [${processed + 1}/${documents.length}] Visit ${visitId} → adminId: ${adminId}`,
        );
        processed++;
      } catch (error) {
        console.error(
          `✗ [${processed + 1}/${documents.length}] Error:`,
          error.message,
        );
        errors++;
        processed++;
      }
    }

    console.log(`\n${"=".repeat(60)}`);
    console.log(`Migration Summary:`);
    console.log(`  Total visits:   ${documents.length}`);
    console.log(`  Updated:        ${updated}`);
    console.log(`  Errors:         ${errors}`);
    console.log(`  Already had ID: ${documents.length - updated - errors}`);
    console.log(`${"=".repeat(60)}\n`);

    process.exit(0);
  } catch (error) {
    console.error("Migration failed:", error.message);
    process.exit(1);
  }
}

migrateVisits();
