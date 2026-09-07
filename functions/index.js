const crypto = require("crypto");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const { onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

// Geheimer Server-Schlüssel ("Pepper") für das Hashen der Crew-IDs (siehe
// ROADMAP_QuizApp.md Abschnitt 18i). Liegt NUR in der Function-Umgebung,
// nie in der Datenbank. Emulator: aus functions/.env.local. Produktiv:
// `firebase functions:secrets:set CREW_ID_PEPPER`.
const CREW_ID_PEPPER = defineSecret("CREW_ID_PEPPER");

// europe-west10 (Berlin, gleiche Region wie Firestore) unterstuetzt
// Cloud Scheduler nicht, was die zeitgesteuerten Functions
// (resetMonthlySeasons, resetCareerSeason) unmoeglich macht - deshalb
// stattdessen europe-west3 (Frankfurt) fuer ALLE Functions einheitlich,
// statt einzelne Functions in unterschiedlichen Regionen zu verteilen.
// Verarbeitet die personenbezogenen Crew-Daten (Name, Geburtsdatum,
// Position) weiterhin innerhalb Deutschlands/EU statt im
// standardmaessigen us-central1 (USA).
setGlobalOptions({ region: "europe-west3" });

initializeApp();
const db = getFirestore();

const DEFAULT_ELO = 1000;
const STANDARD_K_FACTOR = 32;
// Platzierungsmatches (siehe ROADMAP_QuizApp.md Abschnitt 18b): die ersten
// paar Matches eines Spielers zählen mit einem höheren K-Faktor, damit die
// Wertung schneller auf das tatsächliche Niveau einpendelt, statt sich
// langsam hocharbeiten zu müssen.
const PLACEMENT_MATCHES = 5;
const PLACEMENT_K_FACTOR = 64;

function expectedScore(ratingA, ratingB) {
  return 1 / (1 + Math.pow(10, (ratingB - ratingA) / 400));
}

function updatedElo(rating, expected, actual, kFactor) {
  return Math.round(rating + kFactor * (actual - expected));
}

function kFactorFor(matchesPlayed) {
  return matchesPlayed < PLACEMENT_MATCHES ? PLACEMENT_K_FACTOR : STANDARD_K_FACTOR;
}

/** Wirft, wenn der Aufrufer nicht angemeldet oder nur anonym angemeldet ist.
 *  Für wettbewerbsrelevante Callables (siehe ROADMAP_QuizApp.md Abschnitt 18h,
 *  "Gestufter Zugang"). Die Crew-ID-Prüfung passiert schon beim Betreten der
 *  Warteschlange (firestore.rules isFullAccount) - wer in einem Match ist, hat
 *  sie also bereits; hier reicht der billige, lesezugriffsfreie Anonym-Check. */
function requireNonAnonymous(request) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Login erforderlich.");
  if (request.auth.token?.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("failed-precondition", "Vollwertiges Konto erforderlich.");
  }
  return uid;
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
 * Spiegelt Nickname + Position aus dem privaten users/{uid}-Dokument in die
 * öffentliche careerRankings-Rangliste (siehe ROADMAP_QuizApp.md Abschnitt
 * 18). Echter Name, Department, Crew-ID, Deutsch-Level und Zertifikat werden
 * bewusst NICHT gespiegelt - die bleiben ausschließlich im eigenen Profil
 * sichtbar, und users/{uid} ist per Regel ohnehin nur für den jeweiligen
 * Nutzer lesbar. Legt dabei kein eloRating an - Rangliste zeigt weiterhin
 * nur Nutzer mit mindestens einem gewerteten Match (siehe submitRoundResult
 * unten).
 *
 * Das Deutsch-Level beeinflusst die Wertung/das Matchmaking NICHT mehr
 * (siehe ROADMAP_QuizApp.md Abschnitt 18b - die frühere "Level x 1000
 * Start-EP"-Logik wurde ersatzlos zurückgebaut, da sie Smurfing durch
 * bewusstes Zu-niedrig-Einstufen nicht verhindern konnte). Das Level bleibt
 * reine Profil-Information für Lernmodus-/Department-Zwecke.
 */
exports.onUserProfileWritten = onDocumentWritten("users/{uid}", async (event) => {
  const after = event.data?.after?.exists ? event.data.after.data() : null;
  if (!after) return;
  const uid = event.params.uid;

  const nickname = (after.nickname ?? "").trim();
  // Ohne Nickname keinen (leeren) Ranglisten-Eintrag anlegen - sonst
  // erscheinen namenlose Platzhalter-Zeilen in der Rangliste (siehe
  // ROADMAP_QuizApp.md Abschnitt 18h). Ein bereits vorhandener
  // eloRating-Eintrag (aus einem gewerteten Match) bleibt unangetastet.
  if (!nickname) return;

  await db.collection("careerRankings").doc(uid).set(
    { nickname, position: after.position ?? null },
    { merge: true }
  );
});

/**
 * Weicher Season-Reset der 1-vs-1-Wertung (siehe ROADMAP_QuizApp.md
 * Abschnitt 18b): läuft am 1. jedes Monats um Mitternacht (UTC), staucht die
 * Wertung jedes gewerteten Spielers zur Mitte hin (neue Wertung = (alte
 * Wertung + Grundwertung) / 2) statt sie auf 0 zu setzen - Fortschritt bleibt
 * so spürbar erhalten, die Season bleibt aber trotzdem offen. Betrifft nur
 * Spieler mit mindestens einem gewerteten Match (haben einen eloRating-Wert
 * in careerRankings); rankedMatchesPlayed (Platzierungsmatch-Zähler) bleibt
 * dabei unangetastet - das ist eine einmalige Kalibrierung, kein
 * Season-Reset.
 */
exports.resetCareerSeason = onSchedule(
  { schedule: "0 0 1 * *", timeZone: "Etc/UTC" },
  async () => {
    const newSeasonKey = seasonKeyForDate(new Date());
    const rankingsSnapshot = await db.collection("careerRankings").get();
    const batch = db.batch();

    for (const rankingDoc of rankingsSnapshot.docs) {
      const ranking = rankingDoc.data();
      const closingSeasonKey = ranking.currentSeasonKey || newSeasonKey;
      if (closingSeasonKey === newSeasonKey) {
        // Schon in der neuen Season oder noch nie gewertet gespielt.
        continue;
      }
      if (typeof ranking.eloRating !== "number") continue;

      const newRating = Math.round((ranking.eloRating + DEFAULT_ELO) / 2);
      batch.update(rankingDoc.ref, { eloRating: newRating, currentSeasonKey: newSeasonKey });
      batch.update(db.collection("users").doc(rankingDoc.id), { eloRating: newRating });
    }

    await batch.commit();
  }
);

// --- 1-vs-1-Live-Matchmaking + Draft-Phase (ROADMAP_QuizApp.md Abschnitt 16/17) ---
// Ersetzt das frühere asynchrone Karriere-Matchmaking (matchCareerSubmission),
// das nie live geschaltet war: eine Draft-Phase mit abwechselnden Zügen setzt
// zwingend einen gerade anwesenden Gegner voraus, daher jetzt eine echte
// Warteschlange statt "spiele blind, wird später zugeordnet".

// Muss exakt zu den IDs in lib/models/game_format.dart passen.
const FORMAT_IDS = [
  "allgemeinwissen-quiz", "konversation-ueben", "lueckentext", "richtige-reihenfolge",
  "karteikarten", "wahr-oder-falsch", "gameshow-quiz", "bild-quiz", "open-the-box",
  "find-the-match", "random-wheel", "flip-tiles", "match-up", "word-magnets",
  "group-sort", "rank-order", "hoerverstehen", "persoenliche-fragen",
];
const BANS_PER_PLAYER = 3;
const DRAFT_STEP_MS = 18000; // 18s, Mitte der geforderten 15-20s pro Zug.
const DRAFT_GRACE_MS = 3000; // Kulanz, bevor eine abgelaufene Frist serverseitig erzwungen wird.
// So viele eigene Züge in Folge nur per Auto-Aktion -> der Spieler gilt als
// abwesend, das Match wird ohne Wertungsänderung abgebrochen.
const DRAFT_ABANDON_THRESHOLD = 2;

/**
 * Wendet einen Draft-Zug (Ban oder Pick) von [actorUid] an. Gemeinsame Logik
 * für den manuellen submitDraftAction und die serverseitige Auto-Aktion
 * advanceDraftIfExpired (siehe ROADMAP_QuizApp.md Abschnitt 17).
 *
 * draftAutoStreak = { uid, count } zählt aufeinanderfolgende Auto-Aktionen
 * desselben Spielers; ab DRAFT_ABANDON_THRESHOLD gilt er als abwesend und das
 * Match wird abgebrochen (status "aborted", keine ELO-Änderung).
 */
function applyDraftAction(tx, matchRef, match, actorUid, formatId, { auto }) {
  const takenFormats = [...match.banned, ...Object.values(match.picks)];
  if (!match.pool.includes(formatId) || takenFormats.includes(formatId)) {
    throw new HttpsError("failed-precondition", "Format ist nicht mehr verfügbar.");
  }

  const prev = match.draftAutoStreak || null;
  let streak;
  if (auto) {
    streak = prev && prev.uid === actorUid ? { uid: actorUid, count: prev.count + 1 } : { uid: actorUid, count: 1 };
  } else {
    // Manuelle Aktion: eigenen Abwesenheits-Zähler zurücksetzen.
    streak = prev && prev.uid === actorUid ? null : prev;
  }

  if (auto && streak.count >= DRAFT_ABANDON_THRESHOLD) {
    tx.update(matchRef, {
      status: "aborted",
      abortReason: "opponent_unresponsive",
      abortedUid: actorUid,
      turnUid: null,
      turnDeadline: null,
      draftAutoStreak: streak,
    });
    for (const p of match.players) {
      tx.set(db.collection("careerQueue").doc(p), { status: "idle" }, { merge: true });
    }
    return;
  }

  const isBanStep = match.draftStep < BANS_PER_PLAYER * 2;
  const banned = [...match.banned];
  const picks = { ...match.picks };
  if (isBanStep) banned.push(formatId);
  else picks[actorUid] = formatId;

  const nextStep = match.draftStep + 1;
  const totalSteps = BANS_PER_PLAYER * 2 + 2;
  const players = match.players;

  if (nextStep >= totalSteps) {
    const rest = match.pool.filter((f) => !banned.includes(f) && !Object.values(picks).includes(f));
    const thirdFormat = rest[Math.floor(Math.random() * rest.length)];
    tx.update(matchRef, {
      banned,
      picks,
      draftStep: nextStep,
      status: "playing",
      formats: [picks[players[0]], picks[players[1]], thirdFormat],
      thirdFormat,
      turnUid: null,
      turnDeadline: null,
      draftAutoStreak: streak,
    });
  } else {
    tx.update(matchRef, {
      banned,
      picks,
      draftStep: nextStep,
      turnUid: players[nextStep % 2],
      turnDeadline: Date.now() + DRAFT_STEP_MS,
      draftAutoStreak: streak,
    });
  }
}

/**
 * Sucht bei jedem Eintrag/Update in careerQueue mit status "searching" nach
 * einem passenden Gegner (nächstgelegene ELO-Wertung, kein Toleranz-Limit,
 * damit das Matchmaking bei wenigen gleichzeitigen Spielern nicht ausbleibt).
 * Findet sich einer, wird ein neues Match-Dokument angelegt und beide
 * Warteschlangen-Einträge auf "matched" gesetzt.
 */
exports.matchmakeCareerQueue = onDocumentWritten("careerQueue/{uid}", async (event) => {
  const after = event.data?.after?.exists ? event.data.after.data() : null;
  const uid = event.params.uid;
  if (!after || after.status !== "searching") return;

  await db.runTransaction(async (tx) => {
    const myQueueRef = db.collection("careerQueue").doc(uid);
    const myQueueDoc = await tx.get(myQueueRef);
    if (!myQueueDoc.exists || myQueueDoc.data().status !== "searching") return;

    const myUserDoc = await tx.get(db.collection("users").doc(uid));
    const myRating = myUserDoc.data()?.eloRating ?? DEFAULT_ELO;

    const candidatesSnap = await tx.get(
      db.collection("careerQueue").where("status", "==", "searching").limit(20)
    );

    const candidateInfos = [];
    for (const doc of candidatesSnap.docs) {
      if (doc.id === uid) continue;
      const userDoc = await tx.get(db.collection("users").doc(doc.id));
      candidateInfos.push({ uid: doc.id, rating: userDoc.data()?.eloRating ?? DEFAULT_ELO });
    }
    if (candidateInfos.length === 0) return;

    candidateInfos.sort((a, b) => Math.abs(a.rating - myRating) - Math.abs(b.rating - myRating));
    const opponent = candidateInfos[0];
    const players = [uid, opponent.uid];

    const matchRef = db.collection("matches").doc();
    tx.set(matchRef, {
      players,
      ratings: { [uid]: myRating, [opponent.uid]: opponent.rating },
      status: "drafting",
      pool: FORMAT_IDS,
      banned: [],
      picks: {},
      thirdFormat: null,
      draftStep: 0,
      turnUid: players[0],
      turnDeadline: Date.now() + DRAFT_STEP_MS,
      draftAutoStreak: null,
      formats: null,
      currentRound: 0,
      roundScores: {},
      roundWinners: [null, null, null],
      winnerUid: null,
      eloChange: null,
      createdAt: FieldValue.serverTimestamp(),
    });

    tx.update(myQueueRef, { status: "matched", matchId: matchRef.id });
    tx.update(db.collection("careerQueue").doc(opponent.uid), { status: "matched", matchId: matchRef.id });
  });
});

/**
 * Ein Draft-Zug (Bannen oder Formatauswahl). Läuft abwechselnd: die ersten
 * BANS_PER_PLAYER*2 Schritte sind Bans, danach wählt jeder Spieler einmal.
 * Läuft die clientseitige Zeit ab (15-20s), schickt der Client selbst eine
 * zufällige gültige Aktion statt einer manuellen - serverseitig wird nur
 * geprüft, dass die Aktion für den aktuellen Zug gültig ist, nicht wer/was
 * sie ausgelöst hat.
 */
exports.submitDraftAction = onCall(async (request) => {
  const uid = requireNonAnonymous(request);
  const { matchId, formatId } = request.data || {};
  if (!matchId || !formatId) {
    throw new HttpsError("invalid-argument", "matchId und formatId erforderlich.");
  }

  const matchRef = db.collection("matches").doc(matchId);

  await db.runTransaction(async (tx) => {
    const matchDoc = await tx.get(matchRef);
    if (!matchDoc.exists) throw new HttpsError("not-found", "Match nicht gefunden.");
    const match = matchDoc.data();

    if (match.status !== "drafting") throw new HttpsError("failed-precondition", "Draft-Phase ist vorbei.");
    if (match.turnUid !== uid) throw new HttpsError("failed-precondition", "Du bist nicht am Zug.");

    applyDraftAction(tx, matchRef, match, uid, formatId, { auto: false });
  });

  return { ok: true };
});

/**
 * Erzwingt bei abgelaufener Zug-Frist eine zufällige gültige Aktion für den
 * Spieler, der gerade am Zug ist (siehe ROADMAP_QuizApp.md Abschnitt 17).
 * Wird vom anwesenden Spieler aufgerufen, sobald dessen lokale Uhr die im
 * Match-Dokument hinterlegte Frist überschritten sieht - die eigentliche
 * Frist-Prüfung passiert hier serverseitig gegen turnDeadline, also
 * unabhängig davon, ob beim abwesenden Gegner noch ein Zeitgeber läuft.
 * Idempotent: ist die Frist (noch) nicht abgelaufen oder der Draft vorbei,
 * passiert nichts.
 */
exports.advanceDraftIfExpired = onCall(async (request) => {
  const uid = requireNonAnonymous(request);
  const { matchId } = request.data || {};
  if (!matchId) throw new HttpsError("invalid-argument", "matchId erforderlich.");

  const matchRef = db.collection("matches").doc(matchId);

  await db.runTransaction(async (tx) => {
    const matchDoc = await tx.get(matchRef);
    if (!matchDoc.exists) throw new HttpsError("not-found", "Match nicht gefunden.");
    const match = matchDoc.data();
    if (!match.players.includes(uid)) throw new HttpsError("permission-denied", "Kein Teilnehmer dieses Matches.");

    if (match.status !== "drafting") return;
    if (!match.turnDeadline || Date.now() < match.turnDeadline + DRAFT_GRACE_MS) return;

    const taken = [...match.banned, ...Object.values(match.picks)];
    const available = match.pool.filter((f) => !taken.includes(f));
    if (available.length === 0) return;
    const randomFormat = available[Math.floor(Math.random() * available.length)];

    applyDraftAction(tx, matchRef, match, match.turnUid, randomFormat, { auto: true });
  });

  return { ok: true };
});

/**
 * Sicherheitsnetz: bricht Draft-Matches ab, deren Zug-Frist deutlich (>10 min)
 * abgelaufen ist - also Fälle, in denen BEIDE Spieler weg sind und niemand
 * advanceDraftIfExpired auslöst. Keine Wertungsänderung.
 */
exports.abandonStaleDraftMatches = onSchedule(
  { schedule: "every 10 minutes", timeZone: "Etc/UTC" },
  async () => {
    const cutoff = Date.now() - 10 * 60 * 1000;
    const snap = await db.collection("matches").where("status", "==", "drafting").get();
    const batch = db.batch();
    let count = 0;
    for (const doc of snap.docs) {
      const match = doc.data();
      if (!match.turnDeadline || match.turnDeadline > cutoff) continue;
      batch.update(doc.ref, {
        status: "aborted",
        abortReason: "stale",
        turnUid: null,
        turnDeadline: null,
      });
      for (const p of match.players || []) {
        batch.set(db.collection("careerQueue").doc(p), { status: "idle" }, { merge: true });
      }
      count++;
    }
    if (count > 0) await batch.commit();
  }
);

/**
 * Ein Spieler reicht sein Ergebnis für die aktuelle Runde ein. Sobald beide
 * Ergebnisse einer Runde da sind, wird der Rundensieger bestimmt; nach der
 * dritten Runde der Gesamtsieger (Best of 3) und die ELO-Wertung beider
 * Spieler serverseitig aktualisiert (nie client-vorgegeben).
 */
exports.submitRoundResult = onCall(async (request) => {
  const uid = requireNonAnonymous(request);
  const { matchId, roundIndex, score, total } = request.data || {};
  if (
    !matchId || typeof roundIndex !== "number" ||
    typeof score !== "number" || typeof total !== "number"
  ) {
    throw new HttpsError("invalid-argument", "Ungültige Daten.");
  }

  const matchRef = db.collection("matches").doc(matchId);

  await db.runTransaction(async (tx) => {
    const matchDoc = await tx.get(matchRef);
    if (!matchDoc.exists) throw new HttpsError("not-found", "Match nicht gefunden.");
    const match = matchDoc.data();

    if (match.status !== "playing") throw new HttpsError("failed-precondition", "Match läuft nicht.");
    if (!match.players.includes(uid)) throw new HttpsError("permission-denied", "Kein Teilnehmer dieses Matches.");
    if (roundIndex !== match.currentRound) throw new HttpsError("failed-precondition", "Falsche Runde.");

    const roundKey = String(roundIndex);
    const roundScores = { ...(match.roundScores || {}) };
    const thisRound = { ...(roundScores[roundKey] || {}) };
    if (thisRound[uid]) throw new HttpsError("already-exists", "Ergebnis schon eingereicht.");
    thisRound[uid] = { score, total };
    roundScores[roundKey] = thisRound;

    const [p1, p2] = match.players;
    if (!thisRound[p1] || !thisRound[p2]) {
      tx.update(matchRef, { roundScores });
      return;
    }

    const ratio = (s) => (s.total > 0 ? s.score / s.total : 0);
    const r1 = ratio(thisRound[p1]);
    const r2 = ratio(thisRound[p2]);
    let roundWinner = null;
    if (r1 > r2) roundWinner = p1;
    else if (r2 > r1) roundWinner = p2;

    const roundWinners = [...match.roundWinners];
    roundWinners[roundIndex] = roundWinner;

    if (roundIndex < 2) {
      tx.update(matchRef, { roundScores, roundWinners, currentRound: roundIndex + 1 });
      return;
    }

    const p1Wins = roundWinners.filter((w) => w === p1).length;
    const p2Wins = roundWinners.filter((w) => w === p2).length;
    let winnerUid = null;
    if (p1Wins > p2Wins) winnerUid = p1;
    else if (p2Wins > p1Wins) winnerUid = p2;

    const p1UserRef = db.collection("users").doc(p1);
    const p2UserRef = db.collection("users").doc(p2);
    const p1UserDoc = await tx.get(p1UserRef);
    const p2UserDoc = await tx.get(p2UserRef);
    const p1Rating = p1UserDoc.data()?.eloRating ?? DEFAULT_ELO;
    const p2Rating = p2UserDoc.data()?.eloRating ?? DEFAULT_ELO;
    const p1MatchesPlayed = p1UserDoc.data()?.rankedMatchesPlayed ?? 0;
    const p2MatchesPlayed = p2UserDoc.data()?.rankedMatchesPlayed ?? 0;

    let p1Actual = 0.5;
    let p2Actual = 0.5;
    if (winnerUid === p1) {
      p1Actual = 1;
      p2Actual = 0;
    } else if (winnerUid === p2) {
      p1Actual = 0;
      p2Actual = 1;
    }

    const p1Expected = expectedScore(p1Rating, p2Rating);
    const p1NewRating = updatedElo(p1Rating, p1Expected, p1Actual, kFactorFor(p1MatchesPlayed));
    const p2NewRating = updatedElo(p2Rating, 1 - p1Expected, p2Actual, kFactorFor(p2MatchesPlayed));

    tx.update(matchRef, {
      roundScores,
      roundWinners,
      status: "finished",
      winnerUid,
      eloChange: { [p1]: p1NewRating, [p2]: p2NewRating },
    });
    tx.update(p1UserRef, { eloRating: p1NewRating, rankedMatchesPlayed: p1MatchesPlayed + 1 });
    tx.update(p2UserRef, { eloRating: p2NewRating, rankedMatchesPlayed: p2MatchesPlayed + 1 });
    tx.set(
      db.collection("careerRankings").doc(p1),
      { eloRating: p1NewRating, updatedAt: FieldValue.serverTimestamp(), currentSeasonKey: seasonKeyForDate(new Date()) },
      { merge: true }
    );
    tx.set(
      db.collection("careerRankings").doc(p2),
      { eloRating: p2NewRating, updatedAt: FieldValue.serverTimestamp(), currentSeasonKey: seasonKeyForDate(new Date()) },
      { merge: true }
    );
    tx.update(db.collection("careerQueue").doc(p1), { status: "idle" });
    tx.update(db.collection("careerQueue").doc(p2), { status: "idle" });
  });

  return { ok: true };
});

// --- Crew-ID: Eindeutigkeit + Datenschutz (ROADMAP_QuizApp.md 18h Punkt 3 / 18i) ---

/** Vereinheitlicht eine Crew-ID vor dem Hashen, damit "CR-42", "cr 42" und
 *  "CR42" als dieselbe ID gelten. */
function normalizeCrewId(raw) {
  return String(raw ?? "").trim().toUpperCase().replace(/[\s-]/g, "");
}

/** HMAC-SHA256 der normalisierten Crew-ID mit dem Server-Pepper. Deterministisch
 *  (gleiche ID → gleicher Hash), aber ohne den Pepper nicht rückrechenbar. */
function hashCrewId(normalized) {
  return crypto.createHmac("sha256", CREW_ID_PEPPER.value()).update(normalized).digest("hex");
}

/**
 * Ordnet dem aufrufenden Konto eine Crew-ID zu. Serverseitig durchgesetzt
 * (Client kann es nicht umgehen, siehe firestore.rules): In der Datenbank
 * landet NUR der Hash - als users/{uid}.crewIdHash und als Sperr-Eintrag
 * crewIds/{hash} mit { uid, originalUid, claimedAt/releasedAt }.
 *
 * - Aktiver Inhaber (uid gesetzt) und != Aufrufer  -> Ablehnung.
 * - Wechselt der Inhaber weg, wird der Eintrag NICHT gelöscht, sondern nur
 *   freigegeben (uid = null); originalUid (der Erst-Inhaber) bleibt dauerhaft
 *   stehen. Eine freigegebene ID kann danach NUR der ursprüngliche Inhaber
 *   erneut beanspruchen - so lässt sich eine verifizierte Crew-ID nicht per
 *   "kurz wegwechseln" an ein zweites Google-Konto weiterreichen (18h).
 *   Tippfehler-Korrektur durch dieselbe Person bleibt möglich.
 */
exports.claimCrewId = onCall({ secrets: [CREW_ID_PEPPER] }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Anmeldung erforderlich.");

  const provider = request.auth.token?.firebase?.sign_in_provider;
  if (provider === "anonymous") {
    throw new HttpsError("failed-precondition", "Bitte zuerst mit Google anmelden.");
  }

  const normalized = normalizeCrewId(request.data?.crewId);
  if (normalized.length < 3 || normalized.length > 32) {
    throw new HttpsError("invalid-argument", "Ungültige Crew-ID.");
  }

  const hash = hashCrewId(normalized);
  const crewIdRef = db.collection("crewIds").doc(hash);
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    // --- alle Lesezugriffe zuerst ---
    const userDoc = await tx.get(userRef);
    const currentHash = userDoc.data()?.crewIdHash ?? null;
    if (currentHash === hash) return; // schon von diesem Konto beansprucht

    const oldRef = currentHash ? db.collection("crewIds").doc(currentHash) : null;
    const [crewIdDoc, oldDoc] = await Promise.all([
      tx.get(crewIdRef),
      oldRef ? tx.get(oldRef) : Promise.resolve(null),
    ]);

    // --- prüfen ---
    if (crewIdDoc.exists) {
      const data = crewIdDoc.data();
      const holder = data.uid ?? null;
      const firstOwner = data.originalUid ?? data.uid ?? null;
      if (holder && holder !== uid) {
        throw new HttpsError("already-exists", "Diese Crew-ID ist bereits einem anderen Konto zugeordnet.");
      }
      if (!holder && firstOwner && firstOwner !== uid) {
        throw new HttpsError("already-exists", "Diese Crew-ID ist dauerhaft einem anderen Konto zugeordnet.");
      }
    }

    // --- schreiben ---
    if (oldRef) {
      const firstOwner = oldDoc?.data()?.originalUid ?? oldDoc?.data()?.uid ?? uid;
      tx.set(
        oldRef,
        { uid: null, originalUid: firstOwner, releasedAt: FieldValue.serverTimestamp() },
        { merge: true }
      );
    }

    const firstOwner = crewIdDoc.exists
      ? (crewIdDoc.data().originalUid ?? crewIdDoc.data().uid ?? uid)
      : uid;
    tx.set(
      crewIdRef,
      { uid, originalUid: firstOwner, claimedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
    tx.set(userRef, { crewIdHash: hash, crewId: FieldValue.delete() }, { merge: true });
  });

  return { ok: true };
});
