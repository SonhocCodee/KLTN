// ============================================================
// Supabase Edge Function: send-push
// Gửi push notification qua Firebase Cloud Messaging HTTP v1.
// Không cần firebase-admin, chạy được trên Deno Edge Functions.
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.6';
import { SignJWT, importPKCS8 } from 'npm:jose@5.9.6';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-secret',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type SendPushBody = {
  title: string;
  body: string;
  type?: 'general' | 'update' | 'daily_fact' | 'animal' | string;
  data?: Record<string, unknown>;
  target?: 'all' | 'users';
  user_ids?: string[];
  created_by?: string;
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    if (req.method !== 'POST') {
      return json({ error: 'Method not allowed' }, 405);
    }

    const adminSecret = Deno.env.get('ADMIN_PUSH_SECRET') ?? '';
    const inputSecret = req.headers.get('x-admin-secret') ?? '';
    if (!adminSecret || inputSecret !== adminSecret) {
      return json({ error: 'Unauthorized' }, 401);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const payload = (await req.json()) as SendPushBody;
    const title = payload.title?.trim();
    const body = payload.body?.trim();
    const type = payload.type?.trim() || 'general';
    const data = payload.data ?? {};
    const target = payload.target ?? 'all';
    const userIds = payload.user_ids ?? [];

    if (!title || !body) {
      return json({ error: 'Thiếu title hoặc body' }, 400);
    }
    if (target === 'users' && userIds.length === 0) {
      return json({ error: 'target=users nhưng user_ids trống' }, 400);
    }

    const { data: inserted, error: insertError } = await supabase
      .from('push_notifications')
      .insert({
        title,
        body,
        type,
        data,
        target,
        target_user_ids: target === 'users' ? userIds : null,
        status: 'sending',
        created_by: payload.created_by ?? 'admin',
      })
      .select('id')
      .single();

    if (insertError) throw insertError;
    const notificationId = inserted.id as string;

    let query = supabase
      .from('user_push_tokens')
      .select('id, token')
      .eq('enabled', true);

    if (target === 'users') {
      query = query.in('user_id', userIds);
    }

    const { data: tokenRows, error: tokenError } = await query;
    if (tokenError) throw tokenError;

    const tokens = tokenRows ?? [];
    if (tokens.length === 0) {
      await supabase
        .from('push_notifications')
        .update({ status: 'failed', failed_count: 0, sent_at: new Date().toISOString() })
        .eq('id', notificationId);
      return json({ notification_id: notificationId, sent: 0, failed: 0, message: 'Không có token để gửi' });
    }

    const accessToken = await getFirebaseAccessToken();
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID')!;

    let sent = 0;
    let failed = 0;
    const logs: Array<Record<string, unknown>> = [];
    const invalidTokenIds: string[] = [];

    // FCM HTTP v1 gửi từng token. Dự án nhỏ/student app dùng thế này là đủ.
    // Nếu app rất lớn thì chuyển sang worker queue.
    for (const row of tokens) {
      const result = await sendToFcm({
        projectId,
        accessToken,
        token: row.token,
        title,
        body,
        type,
        data,
      });

      if (result.ok) {
        sent += 1;
      } else {
        failed += 1;
        if (isInvalidFcmToken(result.error)) {
          invalidTokenIds.push(row.id);
        }
      }

      logs.push({
        notification_id: notificationId,
        token_id: row.id,
        token: row.token,
        success: result.ok,
        error: result.ok ? null : result.error,
      });
    }

    if (logs.length > 0) {
      await supabase.from('push_notification_logs').insert(logs);
    }

    if (invalidTokenIds.length > 0) {
      await supabase
        .from('user_push_tokens')
        .update({ enabled: false, updated_at: new Date().toISOString() })
        .in('id', invalidTokenIds);
    }

    const status = failed === 0 ? 'sent' : sent > 0 ? 'partial' : 'failed';
    await supabase
      .from('push_notifications')
      .update({
        status,
        sent_count: sent,
        failed_count: failed,
        sent_at: new Date().toISOString(),
      })
      .eq('id', notificationId);

    return json({ notification_id: notificationId, total: tokens.length, sent, failed, status });
  } catch (e) {
    console.error(e);
    return json({ error: String(e?.message ?? e) }, 500);
  }
});

async function getFirebaseAccessToken(): Promise<string> {
  const serviceAccountRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON');
  if (!serviceAccountRaw) throw new Error('Missing FIREBASE_SERVICE_ACCOUNT_JSON');

  const serviceAccount = JSON.parse(serviceAccountRaw);
  const clientEmail = serviceAccount.client_email;
  const privateKey = String(serviceAccount.private_key).replace(/\\n/g, '\n');

  if (!clientEmail || !privateKey) {
    throw new Error('Invalid Firebase service account JSON');
  }

  const key = await importPKCS8(privateKey, 'RS256');
  const now = Math.floor(Date.now() / 1000);

  const jwt = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(clientEmail)
    .setSubject(clientEmail)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const jsonBody = await res.json();
  if (!res.ok) {
    throw new Error(`OAuth error: ${JSON.stringify(jsonBody)}`);
  }

  return jsonBody.access_token;
}

async function sendToFcm(args: {
  projectId: string;
  accessToken: string;
  token: string;
  title: string;
  body: string;
  type: string;
  data: Record<string, unknown>;
}): Promise<{ ok: true; error?: never } | { ok: false; error: string }> {
  const data: Record<string, string> = {
    ...stringifyData(args.data),
    type: args.type,
    title: args.title,
    body: args.body,
  };

  const channelId = args.type === 'update' ? 'push_update_channel' : 'push_general_channel';

  const fcmPayload = {
    message: {
      token: args.token,
      notification: {
        title: args.title,
        body: args.body,
      },
      data,
      android: {
        priority: 'HIGH',
        notification: {
          channel_id: channelId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    },
  };

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${args.projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${args.accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(fcmPayload),
    },
  );

  const text = await res.text();
  if (!res.ok) {
    return { ok: false, error: text };
  }
  return { ok: true };
}

function stringifyData(data: Record<string, unknown>): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [key, value] of Object.entries(data)) {
    if (value === null || value === undefined) continue;
    out[key] = typeof value === 'string' ? value : JSON.stringify(value);
  }
  return out;
}

function isInvalidFcmToken(error: string): boolean {
  return error.includes('UNREGISTERED') ||
    error.includes('INVALID_ARGUMENT') ||
    error.includes('registration-token-not-registered');
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
