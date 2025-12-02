import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const SUPPORT_EMAIL = "contact.polaris.ia@gmail.com"; // Email qui reçoit les notifications (doit correspondre au compte Resend)

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface HelpRequest {
  subject: string;
  message: string;
  userEmail: string;
  userName: string;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { subject, message, userEmail, userName }: HelpRequest = await req.json();

    console.log(`📧 New help request from ${userEmail}`);
    console.log(`   Subject: ${subject}`);

    // Construire l'email HTML
    const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #47C5FB;">📬 Nouvelle demande d'aide - ChallengeMe</h2>
        
        <div style="background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <p><strong>De:</strong> ${userName}</p>
          <p><strong>Email:</strong> <a href="mailto:${userEmail}">${userEmail}</a></p>
          <p><strong>Sujet:</strong> ${subject}</p>
        </div>
        
        <div style="background: #fff; border: 1px solid #e0e0e0; padding: 20px; border-radius: 8px;">
          <h3 style="margin-top: 0;">Message:</h3>
          <p style="white-space: pre-wrap;">${message}</p>
        </div>
        
        <p style="color: #888; font-size: 12px; margin-top: 20px;">
          Envoyé depuis l'application ChallengeMe
        </p>
      </div>
    `;

    // Envoyer via Resend API
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: "ChallengeMe <noreply@resend.dev>", // Domaine par défaut Resend
        to: [SUPPORT_EMAIL],
        reply_to: userEmail, // Pour répondre directement à l'utilisateur
        subject: `[ChallengeMe] ${subject}`,
        html: htmlContent,
      }),
    });

    const data = await res.json();

    if (!res.ok) {
      console.error("❌ Resend API error:", data);
      return new Response(JSON.stringify({ error: data }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log("✅ Email sent successfully:", data.id);

    return new Response(JSON.stringify({ success: true, id: data.id }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("❌ Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
