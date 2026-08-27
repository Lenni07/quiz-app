const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

const DEFAULT_ELO = 1000;
const ELO_K_FACTOR = 32;

function expectedScore(ratingA, ratingB) {
  return 1 / (1 + Math.pow(10, (ratingB - ratingA) / 400));
}

function updatedElo(rating, expected, actual) {
  return Math.round(rating + ELO_K_FACTOR * (actual - expected));
}

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

/**
 * Asynchrones ELO-Matchmaking für den Karrieremodus (siehe
 * ROADMAP_QuizApp.md Abschnitt 15). Ausgelöst durch jede eingereichte
 * Karriere-Runde: sucht unter den wartenden Einreichungen desselben Formats
 * den Spieler mit der nächstgelegenen Wertung. Findet sich einer, werden
 * beide ELO-Werte sofort aktualisiert (auch wenn der Gegner längst offline
 * ist) - kein Echtzeit-Gegner nötig. Findet sich keiner, wird die eigene
 * Einreichung selbst zur wartenden Einreichung für spätere Spieler.
 */
exports.matchCareerSubmission = onDocumentCreated(
  "careerSubmissions/{submissionId}",
  async (event) => {
    const submissionRef = event.data?.ref;
    const submission = event.data?.data();
    if (
      !submissionRef || !submission || !submission.uid || !submission.format ||
      typeof submission.score !== "number" || typeof submission.total !== "number"
    ) {
      return;
    }

    const myUserRef = db.collection("users").doc(submission.uid);

    await db.runTransaction(async (tx) => {
      const myUserDoc = await tx.get(myUserRef);
      const myRating = myUserDoc.data()?.eloRating ?? DEFAULT_ELO;

      const candidatesSnap = await tx.get(
        db.collection("careerSubmissions")
          .where("format", "==", submission.format)
          .where("status", "==", "waiting")
          .limit(20)
      );

      let opponentDoc = null;
      let smallestDiff = Infinity;
      for (const doc of candidatesSnap.docs) {
        if (doc.id === submissionRef.id) continue;
        const data = doc.data();
        if (data.uid === submission.uid) continue;
        const diff = Math.abs((data.rating ?? DEFAULT_ELO) - myRating);
        if (diff < smallestDiff) {
          smallestDiff = diff;
          opponentDoc = doc;
        }
      }

      if (!opponentDoc) {
        tx.update(submissionRef, { status: "waiting", rating: myRating });
        return;
      }

      const opponent = opponentDoc.data();
      const opponentRating = opponent.rating ?? DEFAULT_ELO;
      const opponentUserRef = db.collection("users").doc(opponent.uid);

      const myRatio = submission.total > 0 ? submission.score / submission.total : 0;
      const opponentRatio = opponent.total > 0 ? opponent.score / opponent.total : 0;

      let myActual = 0.5;
      if (myRatio > opponentRatio) myActual = 1;
      else if (myRatio < opponentRatio) myActual = 0;

      const myExpected = expectedScore(myRating, opponentRating);
      const myNewRating = updatedElo(myRating, myExpected, myActual);
      const opponentNewRating = updatedElo(opponentRating, 1 - myExpected, 1 - myActual);

      tx.update(submissionRef, {
        status: "matched",
        rating: myRating,
        opponentUid: opponent.uid,
        result: myActual,
      });
      tx.update(opponentDoc.ref, {
        status: "matched",
        opponentUid: submission.uid,
        result: 1 - myActual,
      });

      tx.update(myUserRef, { eloRating: myNewRating });
      tx.update(opponentUserRef, { eloRating: opponentNewRating });

      tx.set(
        db.collection("careerRankings").doc(submission.uid),
        { eloRating: myNewRating, updatedAt: FieldValue.serverTimestamp() },
        { merge: true }
      );
      tx.set(
        db.collection("careerRankings").doc(opponent.uid),
        { eloRating: opponentNewRating, updatedAt: FieldValue.serverTimestamp() },
        { merge: true }
      );
    });
  }
);
