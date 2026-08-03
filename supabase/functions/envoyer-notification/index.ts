import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Edge Function : envoyer-notification
// Utilise l'API FCM V1 (OAuth2 avec compte de service Google)
// Declenchee via webhook quand un INSERT se fait dans la table `friends`

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Le JSON du compte de service Firebase (stocke en secret base64)
const FCM_SERVICE_ACCOUNT_B64 = Deno.env.get("FCM_SERVICE_ACCOUNT")!;
const FCM_SERVICE_ACCOUNT = JSON.parse(atob(FCM_SERVICE_ACCOUNT_B64));

// Generer un token OAuth2 pour l'API FCM V1
async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: FCM_SERVICE_ACCOUNT.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  // Encoder en base64url
  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");

  const unsignedToken = `${encode(header)}.${encode(payload)}`;

  // Signer avec la cle privee RSA
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
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedToken)
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const jwt = `${unsignedToken}.${signatureB64}`;

  // Echanger le JWT contre un access token
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

  let receiverId: string;
  let title: string;
  let notifBody: string;
  let senderId = "";

  if (body.type === "INSERT" && body.table === "friends") {
    // Webhook Supabase : nouvelle demande d'ami
    const record = body.record;
    receiverId = record.receiver_id;
    senderId = record.sender_id;

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data: sender } = await supabase
      .from("profiles")
      .select("pseudo")
      .eq("id", record.sender_id)
      .single();

    const senderPseudo = sender?.pseudo ?? "Quelqu'un";
    title = "Demande d'ami";
    notifBody = `@${senderPseudo} veut t'ajouter en ami !`;
  } else {
    // Appel manuel
    receiverId = body.receiver_id;
    title = body.title ?? "Otaku Verse";
    notifBody = body.body ?? "Tu as une notification !";
  }

  if (!receiverId) {
    return Response.json({ error: "receiver_id manquant" }, { status: 400 });
  }

  // Recuperer le fcm_token du destinataire
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const { data: profile, error } = await supabase
    .from("profiles")
    .select("fcm_token")
    .eq("id", receiverId)
    .single();

  if (error || !profile?.fcm_token) {
    return Response.json(
      { error: "Token FCM non trouve pour ce joueur" },
      { status: 404 }
    );
  }

  // Obtenir un access token OAuth2
  const accessToken = await getAccessToken();
  const projectId = FCM_SERVICE_ACCOUNT.project_id;

  // Envoyer via FCM API V1
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
          notification: {
            title: title,
            body: notifBody,
          },
          data: {
            type: "friend_request",
            sender_id: senderId,
          },
        },
      }),
    }
  );

  const fcmResult = await fcmResponse.json();

  if (fcmResponse.ok) {
    return Response.json({ success: true, message: "Notification envoyee" });
  } else {
    return Response.json(
      { success: false, error: "FCM V1 erreur", detail: fcmResult },
      { status: 500 }
    );
  }
});
