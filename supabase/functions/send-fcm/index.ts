import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'
import { GoogleAuth } from 'npm:google-auth-library@9.6.3'

serve(async (req) => {
    try {
        const payload = await req.json()
        const record = payload.record // The inserted notification

        if (!record || !record.title) {
            return new Response('Missing notification data', { status: 400 })
        }

        // Initialize Supabase client
        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        const supabase = createClient(supabaseUrl, supabaseKey)

        // 1. Extract target roles from related_entity_type (e.g. "task||roles:manager,admin")
        let targetRoles: string[] = []
        const rawType = record.related_entity_type;
        if (rawType && rawType.includes('||roles:')) {
            const parts = rawType.split('||roles:');
            if (parts.length > 1) {
                targetRoles = parts[1].split(',');
            }
        }

        console.log(`[Push FCM] Record ID: ${record.id}, Target roles:`, targetRoles);

        if (targetRoles.length === 0) {
            console.log('[Push FCM] No target roles, skipping push.');
            return new Response('No target roles, skipping push.', { status: 200 })
        }

        // 2. Find Users who have these roles
        const { data: profiles, error: profileError } = await supabase
            .from('profiles')
            .select('id, role')
            .in('role', targetRoles)

        if (profileError || !profiles || profiles.length === 0) {
            console.log('[Push FCM] No users found with these target roles. Profile Error:', profileError);
            return new Response('No users found for target roles', { status: 200 })
        }

        const targetUserIds = profiles.map(p => p.id)
        console.log(`[Push FCM] Found ${profiles.length} users with matching roles.`);

        // 3. Get FCM Tokens for those users
        const { data: tokensData, error: tokenError } = await supabase
            .from('fcm_tokens')
            .select('token')
            .in('user_id', targetUserIds)

        if (tokenError || !tokensData || tokensData.length === 0) {
            console.log('[Push FCM] No device tokens found for target users. Token Error:', tokenError);
            return new Response('No device tokens found for target users', { status: 200 })
        }

        const tokens = tokensData.map(t => t.token)
        console.log(`[Push FCM] Found ${tokens.length} FCM tokens to send to.`);

        // 4. Authenticate with Google / Firebase
        // NOTE: You must add SERVICE_ACCOUNT_JSON to your Supabase Edge Function secrets
        const serviceAccountStr = Deno.env.get('SERVICE_ACCOUNT_JSON')
        if (!serviceAccountStr) {
            throw new Error('Missing SERVICE_ACCOUNT_JSON secret')
        }

        const serviceAccount = JSON.parse(serviceAccountStr)
        const auth = new GoogleAuth({
            credentials: {
                client_email: serviceAccount.client_email,
                private_key: serviceAccount.private_key,
            },
            scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
        })

        const client = await auth.getClient()
        const accessToken = (await client.getAccessToken()).token
        const projectId = serviceAccount.project_id

        // 5. Send push notification to all tokens
        const sendPromises = tokens.map(async (token) => {
            const fcmPayload = {
                message: {
                    token: token,
                    notification: {
                        title: record.title,
                        body: record.message || '',
                    },
                    data: {
                        id: record.id,
                        entityId: record.related_entity_id || '',
                        entityType: rawType ? rawType.split('||')[0] : '',
                    }
                }
            }

            const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${accessToken}`,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(fcmPayload)
            })

            return res.json()
        })

        const results = await Promise.all(sendPromises)
        console.log('[Push FCM] Send results:', JSON.stringify(results));

        return new Response(JSON.stringify({ success: true, results }), {
            headers: { 'Content-Type': 'application/json' },
            status: 200
        })

    } catch (error) {
        console.error('Push error:', error)
        return new Response(JSON.stringify({ error: error.message }), { status: 500 })
    }
})
