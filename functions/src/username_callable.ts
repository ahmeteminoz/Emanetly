import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
const callableRuntimeOptions = {
  region: "europe-west1",
  memory: "256MiB" as const,
  timeoutSeconds: 15,
  maxInstances: 10,
};

/**
 * Callable Cloud Function: setUsername
 * Validates, normalizes, and transactionally registers a custom unique username for a user.
 */
export const setUsername = onCall(callableRuntimeOptions, async (request) => {
  // 1. Authentication Guard
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Bu işlemi gerçekleştirmek için giriş yapmış olmalısınız.");
  }

  // 2. Email Verification Guard
  if (request.auth.token.email_verified !== true) {
    throw new HttpsError("failed-precondition", "Kullanıcı adı belirlemeden önce e-posta adresinizi doğrulamalısınız.");
  }

  const uid = request.auth.uid;
  const rawUsername = request.data.username;

  if (typeof rawUsername !== "string") {
    throw new HttpsError("invalid-argument", "Geçersiz kullanıcı adı parametresi.");
  }

  // 3. Normalization (trim and lowercase)
  const normalized = rawUsername.trim().toLowerCase();

  // 4. Regex Validation Rules
  const usernameRegex = /^[a-z0-9](?:[a-z0-9]|[._](?=[a-z0-9])){1,18}[a-z0-9]$/;
  if (!usernameRegex.test(normalized)) {
    throw new HttpsError(
      "invalid-argument",
      "Kullanıcı adı 3-20 karakter uzunluğunda olmalı, sadece küçük harf, rakam, nokta (.) ve alt çizgi (_) içermeli, harf veya rakamla başlayıp bitmelidir. Art arda nokta veya alt çizgi içeremez."
    );
  }

  // 5. Reserved username list and pattern checks
  const exactReserved = [
    "admin", "administrator", "emanetly", "support", "destek",
    "moderator", "mod", "official", "system", "root",
    "deleteduser", "eskikullanici"
  ];
  
  if (exactReserved.includes(normalized)) {
    throw new HttpsError("invalid-argument", "Bu kullanıcı adı rezerve edilmiştir ve kullanılamaz.");
  }

  if (normalized.includes("emanetly")) {
    throw new HttpsError("invalid-argument", "Kullanıcı adı 'emanetly' kelimesini içeremez.");
  }

  const forbiddenPrefixes = ["admin", "support", "official", "moderator"];
  for (const prefix of forbiddenPrefixes) {
    if (normalized.startsWith(prefix)) {
      throw new HttpsError("invalid-argument", `Kullanıcı adı '${prefix}' kelimesiyle başlayamaz.`);
    }
  }

  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);
  const newClaimRef = db.collection("usernames").doc(normalized);

  try {
    const result = await db.runTransaction(async (transaction) => {
      // 5.1 READ PHASE (All reads must happen before writes)
      
      // Read profile
      const userSnap = await transaction.get(userRef);
      if (!userSnap.exists) {
        throw new HttpsError("not-found", "Kullanıcı profili bulunamadı.");
      }

      const userData = userSnap.data() || {};
      const currentSource = userData.usernameSource;
      const currentOnboarding = userData.onboardingComplete;
      const oldUsername = userData.usernameNormalized;

      // Rule: If already custom and onboarding complete, reject changes
      if (currentSource === "custom" && currentOnboarding === true) {
        throw new HttpsError("failed-precondition", "Kullanıcı adınızı daha önce belirlemişsiniz. Tekrar değiştiremezsiniz.");
      }

      // Check for Idempotency
      if (oldUsername === normalized) {
        logger.info(`Emanetly setUsername: Idempotent no-op for uid: ${uid}, username: ${normalized}`);
        return { success: true, idempotent: true };
      }

      // Read new claim doc
      const newClaimSnap = await transaction.get(newClaimRef);
      if (newClaimSnap.exists) {
        const claimData = newClaimSnap.data();
        if (claimData && claimData.uid !== uid) {
          throw new HttpsError("already-exists", "Bu kullanıcı adı başka bir kullanıcı tarafından alınmış.");
        }
      }

      // Read old claim doc if there is one
      let oldClaimRef: admin.firestore.DocumentReference | null = null;
      let isOldClaimValid = false;
      if (oldUsername) {
        oldClaimRef = db.collection("usernames").doc(oldUsername);
        const oldClaimSnap = await transaction.get(oldClaimRef);
        if (oldClaimSnap.exists) {
          const oldClaimData = oldClaimSnap.data();
          if (oldClaimData && oldClaimData.uid === uid) {
            isOldClaimValid = true;
          }
        }
      }

      // 5.2 WRITE PHASE (All writes/deletes happen after reads)
      
      // Set new username claim doc
      transaction.set(newClaimRef, {
        uid: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update user profile
      transaction.update(userRef, {
        username: normalized,
        usernameNormalized: normalized,
        usernameSource: "custom",
        usernameChangedAt: admin.firestore.FieldValue.serverTimestamp(),
        onboardingComplete: true,
      });

      // Delete old username claim safely
      if (oldClaimRef && isOldClaimValid) {
        transaction.delete(oldClaimRef);
      }

      return { success: true };
    });

    return result;
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error(`Emanetly setUsername error:`, error);
    throw new HttpsError("internal", "Kullanıcı adı belirlenirken bilinmeyen bir hata oluştu.");
  }
});
