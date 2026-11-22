import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Edge Function : envoyer-notification (FCM V1)
// Supporte :
// 1. Webhook INSERT sur `friends` (demande d'ami)
// 2. Appel interne securise depuis `match-engine` pour `friend_overtake` (RANK-02)

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const FCM_SERVICE_ACCOUNT_B64 = Deno.env.get("FCM_SERVICE_ACCOUNT") ?? "";
const FCM_SERVICE_ACCOUNT = FCM_SERVICE_ACCOUNT_B64 ? JSON.parse(atob(FCM_SERVICE_ACCOUNT_B64)) : null;

async function getAccessToken(): Promise<string> {
  if (!FCM_SERVICE_ACCOUNT) {
    throw new Error("FCM_SERVICE_ACCOUNT non configure");
  }
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: FCM_SERVICE_ACCOUNT.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");

  const unsignedToken = `${encode(header)}.${encode(payload)}`;

  const privateKey = FCM_SERVICE_ACCOUNT.private_key;
  const keyData = privateKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");

  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedToken),
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const jwt = `${unsignedToken}.${signatureB64}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenRes.json();
  return tokenData.access_token;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Methode non autorisee", { status: 405 });
  }

  const body = await req.json();
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  let receiverId = "";
  let title = "Otaku Verse";
  let notifBody = "Tu as une notification !";
  let senderId = "";
  let notifType = "general";

  if (body.type === "INSERT" && body.table === "friends") {
    const record = body.record;
    receiverId = record.receiver_id;
    senderId = record.sender_id;
    notifType = "friend_request";

    const { data: sender } = await supabase
      .from("profiles")
      .select("pseudo")
      .eq("id", record.sender_id)
      .single();

    const senderPseudo = sender?.pseudo ?? "Quelqu'un";
    title = "Demande d'ami";
    notifBody = `@${senderPseudo} veut t'ajouter en ami !`;
  } else {
    // Appel interne (ex: RANK-02 friend_overtake depuis match-engine) : exiger la cle service_role
    const authHeader = req.headers.get("Authorization") ?? "";
    if (authHeader !== `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`) {
      return Response.json({ error: "Acces refuse" }, { status: 403 });
    }
    receiverId = String(body.receiver_id ?? "");
    senderId = String(body.sender_id ?? "");
    notifType = String(body.notif_type ?? "general");
    title = String(body.title ?? "Otaku Verse");
    notifBody = String(body.body ?? "Tu as une notification !");
  }

  if (!receiverId) {
    return Response.json({ error: "receiver_id manquant" }, { status: 400 });
  }

  const { data: profile, error } = await supabase
    .from("profiles")
    .select("fcm_token")
    .eq("id", receiverId)
    .single();

  if (error || !profile?.fcm_token) {
    return Response.json({ error: "Token FCM non trouve pour ce joueur" }, { status: 404 });
  }

  if (!FCM_SERVICE_ACCOUNT) {
    return Response.json({ error: "Secret FCM non configure" }, { status: 500 });
  }

  const accessToken = await getAccessToken();
  const projectId = FCM_SERVICE_ACCOUNT.project_id;

  const fcmResponse = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: profile.fcm_token,
          notification: { title, body: notifBody },
          data: { type: notifType, sender_id: senderId },
        },
      }),
    },
  );

  const fcmResult = await fcmResponse.json();

  if (fcmResponse.ok) {
    return Response.json({ success: true, message: "Notification envoyee" });
  }
  return Response.json({ success: false, error: "FCM V1 erreur", detail: fcmResult }, { status: 500 });
});
