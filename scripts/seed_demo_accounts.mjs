import admin from "firebase-admin";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const serviceAccountPath = path.join(__dirname, "serviceAccountKey.json");

if (!fs.existsSync(serviceAccountPath)) {
  console.error(
    "Missing scripts/serviceAccountKey.json. Download a Firebase service account key and place it there first."
  );
  process.exit(1);
}

const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, "utf8"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const now = new Date().toISOString();

const users = [
  {
    key: "admin",
    email: "admin@demo.com",
    password: "demo123",
    displayName: "JomImpact Admin",
    firestore: {
      name: "JomImpact Admin",
      email: "admin@demo.com",
      role: "admin",
      skills: [],
      organizerApprovalStatus: "notRequired",
      totalHours: null,
      totalEvents: null,
      photoUrl: null,
      bio: "Platform administrator for organizer approvals.",
      createdAt: now
    }
  },
  {
    key: "organizer",
    email: "organizer@demo.com",
    password: "demo123",
    displayName: "Green Earth Society",
    firestore: {
      name: "Green Earth Society",
      email: "organizer@demo.com",
      role: "organizer",
      organization: "Green Earth Society",
      skills: [],
      organizerApprovalStatus: "approved",
      approvalNotes: "Approved for demo access.",
      totalHours: null,
      totalEvents: 1,
      photoUrl: null,
      bio: "We organize sustainability and community volunteer activities.",
      location: "Kuala Lumpur",
      phone: "+60 12-345 6789",
      createdAt: now
    }
  },
  {
    key: "pendingOrganizer",
    email: "pending.organizer@demo.com",
    password: "demo123",
    displayName: "Hope Outreach",
    firestore: {
      name: "Hope Outreach",
      email: "pending.organizer@demo.com",
      role: "organizer",
      organization: "Hope Outreach",
      skills: [],
      organizerApprovalStatus: "pending",
      approvalNotes: null,
      totalHours: null,
      totalEvents: 0,
      photoUrl: null,
      bio: "Awaiting approval to start publishing events.",
      location: "Selangor",
      phone: "+60 11-2345 6789",
      createdAt: now
    }
  },
  {
    key: "volunteer",
    email: "volunteer@demo.com",
    password: "demo123",
    displayName: "Alya Volunteer",
    firestore: {
      name: "Alya Volunteer",
      email: "volunteer@demo.com",
      role: "volunteer",
      skills: ["First Aid", "Crowd Support", "Teaching"],
      organizerApprovalStatus: "notRequired",
      totalHours: 24,
      totalEvents: null,
      photoUrl: null,
      bio: "Community volunteer who enjoys environmental and education events.",
      location: "Shah Alam",
      phone: "+60 10-987 6543",
      createdAt: now
    }
  }
];

async function upsertAuthUser({ email, password, displayName }) {
  try {
    const existing = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(existing.uid, {
      password,
      displayName
    });
    return existing.uid;
  } catch (error) {
    if (error.code !== "auth/user-not-found") {
      throw error;
    }
    const created = await admin.auth().createUser({
      email,
      password,
      displayName
    });
    return created.uid;
  }
}

async function seedUsers() {
  const ids = {};

  for (const user of users) {
    const uid = await upsertAuthUser(user);
    ids[user.key] = uid;
    await db.collection("users").doc(uid).set({
      id: uid,
      ...user.firestore
    }, { merge: true });
    console.log(`Seeded user: ${user.email}`);
  }

  return ids;
}

async function seedEvent(organizerId) {
  const eventId = "demo_cleanup_event";
  await db.collection("events").doc(eventId).set({
    id: eventId,
    organizerId,
    organizerName: "Green Earth Society",
    organizerPhotoUrl: "",
    title: "River Cleanup Day",
    description: "Help clean the riverbank and sort collected waste with the local community.",
    location: "Taman Tasik Titiwangsa, Kuala Lumpur",
    startDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000 + 4 * 60 * 60 * 1000).toISOString(),
    category: "environment",
    status: "published",
    maxVolunteers: 40,
    currentVolunteers: 0,
    imageUrl: null,
    requirements: ["Wear outdoor clothing", "Bring water bottle"],
    benefits: ["Volunteer certificate", "Refreshments provided"],
    createdAt: now
  }, { merge: true });

  console.log(`Seeded event: ${eventId}`);
}

async function main() {
  const ids = await seedUsers();
  await seedEvent(ids.organizer);
  console.log("");
  console.log("Demo accounts ready:");
  console.log("  admin@demo.com / demo123");
  console.log("  organizer@demo.com / demo123");
  console.log("  pending.organizer@demo.com / demo123");
  console.log("  volunteer@demo.com / demo123");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
