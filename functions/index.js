const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

/** "YYYY-MM", z. B. "2026-08" — identifiziert eine Season eindeutig. */
function seasonKeyForDate(date) {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");
  return `${year}-${month}`;
}

/**
 * Wird bei jedem übermittelten Spielergebnis ausgelöst (siehe
 * ROADMAP_QuizApp.md Abschnitt 6) und addiert die Punkte zum laufenden
 * Season-Punktestand des jeweiligen Schiffs. Legt das Schiff-Dokument bei
 * Bedarf neu an.
 */
exports.onScoreSubmissionCreated = onDocumentCreated(
  "scoreSubmissions/{submissionId}",
  async (event) => {
    const submission = event.data?.data();
    if (!submission || !submission.shipId || typeof submission.score !== "number") {
      return;
    }

    const shipRef = db.collection("ships").doc(submission.shipId);
    await db.runTransaction(async (tx) => {
      const shipDoc = await tx.get(shipRef);
      if (!shipDoc.exists) {
        tx.set(shipRef, {
          name: submission.shipId,
          seasonScore: submission.score,
          currentSeasonKey: seasonKeyForDate(new Date()),
        });
      } else {
        tx.update(shipRef, { seasonScore: FieldValue.increment(submission.score) });
      }
    });
  }
);

/**
 * Läuft am 1. jedes Monats um Mitternacht (UTC): schließt die laufende
 * Season jedes Schiffs ab (Archiv unter ships/{id}/seasons/{season}) und
 * setzt den Punktestand für die neue Season auf 0 zurück.
 */
exports.resetMonthlySeasons = onSchedule(
  { schedule: "0 0 1 * *", timeZone: "Etc/UTC" },
  async () => {
    const now = new Date();
    const newSeasonKey = seasonKeyForDate(now);

    const shipsSnapshot = await db.collection("ships").get();
    const batch = db.batch();

    for (const shipDoc of shipsSnapshot.docs) {
      const ship = shipDoc.data();
      const closingSeasonKey = ship.currentSeasonKey || newSeasonKey;
      if (closingSeasonKey === newSeasonKey) {
        // Schon in der neuen Season (z. B. gerade erst angelegt) - nichts zu tun.
        continue;
      }

      const seasonRef = shipDoc.ref.collection("seasons").doc(closingSeasonKey);
      batch.set(seasonRef, {
        score: ship.seasonScore || 0,
        closedAt: FieldValue.serverTimestamp(),
      });
      batch.update(shipDoc.ref, {
        seasonScore: 0,
        currentSeasonKey: newSeasonKey,
      });
    }

    await batch.commit();
  }
);
