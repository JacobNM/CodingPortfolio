import { useState } from "react";

function getOnCallPeriod() {
  const now = new Date();
  const day = now.getDay();
  const daysSinceTue = ((day - 2) + 7) % 7;
  const end = new Date(now);
  end.setDate(now.getDate() - daysSinceTue);
  end.setHours(10, 0, 0, 0);
  const start = new Date(end);
  start.setDate(end.getDate() - 7);
  return { start, end };
}

const fmtShort = (d) => d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
const fmtFull = (d) =>
  d.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" });

const CHANNELS = [
  "#sre-prod-infra-alerts",
  "#sre-release-infra-alerts",
  "#sre-staging-infra-alerts",
];

function SlackMessagePreview({ text }) {
  if (!text) return null;
  const lines = text.split("\n");
  return (
    <div style={{ fontFamily: "var(--font-sans)", fontSize: "14px", lineHeight: "1.6", color: "#1d1c1d" }}>
      {lines.map((line, i) => {
        if (!line.trim()) return <div key={i} style={{ height: "4px" }} />;
        const parts = [];
        let remaining = line;
        let key = 0;
        const regex = /\*([^*]+)\*/g;
        let last = 0, m;
        const segs = [];
        while ((m = regex.exec(line)) !== null) {
          if (m.index > last) segs.push({ t: line.slice(last, m.index), b: false });
          segs.push({ t: m[1], b: true });
          last = m.index + m[0].length;
        }
        if (last < line.length) segs.push({ t: line.slice(last), b: false });
        return (
          <div key={i} style={{ marginBottom: "2px" }}>
            {segs.map((s, j) =>
              s.b ? <strong key={j}>{s.t}</strong> : <span key={j}>{s.t}</span>
            )}
          </div>
        );
      })}
    </div>
  );
}

function LogTerminal({ logs }) {
  if (!logs.length) return null;
  return (
    <div
      style={{
        background: "var(--color-background-tertiary)",
        borderTop: "0.5px solid var(--color-border-tertiary)",
        padding: "12px 20px",
        fontFamily: "var(--font-mono)",
        fontSize: "12px",
      }}
    >
      {logs.map((l, i) => (
        <div key={i} style={{ display: "flex", gap: "12px", marginBottom: "2px" }}>
          <span style={{ color: "var(--color-text-tertiary)", flexShrink: 0 }}>{l.t}</span>
          <span
            style={{
              color: i === logs.length - 1 ? "var(--color-text-primary)" : "var(--color-text-secondary)",
            }}
          >
            {l.msg}
          </span>
        </div>
      ))}
    </div>
  );
}

function ScheduleBlock({ title, code }) {
  return (
    <div
      style={{
        border: "0.5px solid var(--color-border-tertiary)",
        borderRadius: "var(--border-radius-md)",
        overflow: "hidden",
        marginBottom: "8px",
      }}
    >
      <div
        style={{
          background: "var(--color-background-secondary)",
          padding: "6px 12px",
          fontSize: "12px",
          fontWeight: 500,
          color: "var(--color-text-secondary)",
          borderBottom: "0.5px solid var(--color-border-tertiary)",
        }}
      >
        {title}
      </div>
      <pre
        style={{
          margin: 0,
          padding: "10px 12px",
          fontFamily: "var(--font-mono)",
          fontSize: "12px",
          color: "var(--color-text-secondary)",
          background: "var(--color-background-primary)",
          overflowX: "auto",
          lineHeight: 1.5,
        }}
      >
        {code}
      </pre>
    </div>
  );
}

export default function SREHandoff() {
  const [phase, setPhase] = useState("idle");
  const [preview, setPreview] = useState("");
  const [error, setError] = useState("");
  const [logs, setLogs] = useState([]);
  const [scheduleOpen, setScheduleOpen] = useState(false);
  const { start, end } = getOnCallPeriod();

  const addLog = (msg) =>
    setLogs((p) => [
      ...p,
      {
        t: new Date().toLocaleTimeString("en-US", {
          hour12: false,
          hour: "2-digit",
          minute: "2-digit",
          second: "2-digit",
        }),
        msg,
      },
    ]);

  async function handleGenerate() {
    setPhase("generating");
    setLogs([]);
    setError("");
    setPreview("");
    addLog("Connecting to Slack MCP...");

    const systemPrompt = `You are an SRE on-call handoff generator.

TASK: Read the past 7 days of Slack messages from the alert channels, then return a single formatted handoff message — nothing else, no preamble, no commentary.

STEP 1 — Find channel IDs using slack_search_channels for each:
- sre-prod-infra-alerts
- sre-release-infra-alerts
- sre-staging-infra-alerts

STEP 2 — Read each channel using slack_read_channel. Fetch enough messages to cover ${fmtFull(start)} → ${fmtFull(end)}.

STEP 3 — Analyze: most frequent/noisy alerts, auto-resolved vs persistent, recurring patterns, anything needing follow-up.

STEP 4 — Return ONLY this Slack-formatted message (no extra text before or after):

@sre-on-call 👋 *On-Call Handoff* | ${fmtShort(start)} → ${fmtShort(end)} · 10:00 AM

━━━━━━━━━━━━━━━━━━━━
*📡 #sre-prod-infra-alerts*
• [3–4 bullets, smart and concise]

*📡 #sre-release-infra-alerts*
• [3–4 bullets]

*📡 #sre-staging-infra-alerts*
• [3–4 bullets]

📋 *Action Items* (include only if there are real follow-ups)
• [item]

_🤖 Auto-generated handoff · ${fmtShort(end)} at 10:00 AM_

Icons to use: 🔴 critical/ongoing  🟠 high  🟡 medium  🟢 auto-resolved  ✅ resolved  📈 pattern  🔁 recurring  ⚠️ watch`;

    try {
      const res = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: "claude-sonnet-4-20250514",
          max_tokens: 2000,
          system: systemPrompt,
          messages: [{ role: "user", content: "Generate the handoff report now." }],
          mcp_servers: [{ type: "url", url: "https://mcp.slack.com/mcp", name: "slack" }],
        }),
      });

      addLog("Reading #sre-prod-infra-alerts...");
      addLog("Reading #sre-release-infra-alerts...");
      addLog("Reading #sre-staging-infra-alerts...");

      const data = await res.json();
      if (data.error) throw new Error(data.error.message);

      addLog("Analyzing patterns and frequencies...");

      const text = data.content
        .filter((b) => b.type === "text")
        .map((b) => b.text)
        .join("\n")
        .trim();

      if (!text) throw new Error("No handoff message returned from API");

      addLog("Handoff generated successfully");
      setPreview(text);
      setPhase("preview");
    } catch (e) {
      addLog(`Error: ${e.message}`);
      setError(e.message || "Unknown error");
      setPhase("error");
    }
  }

  async function handlePost() {
    setPhase("posting");
    addLog("Finding #eng-falcons channel...");

    try {
      const res = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: "claude-sonnet-4-20250514",
          max_tokens: 300,
          messages: [
            {
              role: "user",
              content: `Use slack_search_channels to find the channel ID for "eng-falcons", then use slack_send_message to post this exact message to that channel. Reply only with "SENT" when done.\n\n${preview}`,
            },
          ],
          mcp_servers: [{ type: "url", url: "https://mcp.slack.com/mcp", name: "slack" }],
        }),
      });

      addLog("Posting to #eng-falcons...");
      const data = await res.json();
      if (data.error) throw new Error(data.error.message);

      addLog("Posted to #eng-falcons successfully");
      setPhase("done");
    } catch (e) {
      addLog(`Error: ${e.message}`);
      setError(e.message);
      setPhase("error");
    }
  }

  const busy = phase === "generating" || phase === "posting";

  return (
    <div style={{ fontFamily: "var(--font-sans)", maxWidth: "680px", padding: "8px 0" }}>
      <style>{`
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes pulse { 0%,100% { opacity:1; } 50% { opacity:0.4; } }
        .spin { animation: spin 0.75s linear infinite; }
        .pulse-dot { animation: pulse 1.5s ease-in-out infinite; }
      `}</style>

      <h2
        style={{
          fontSize: "18px",
          fontWeight: 500,
          margin: "0 0 4px",
          color: "var(--color-text-primary)",
        }}
      >
        SRE on-call handoff
      </h2>
      <p style={{ margin: "0 0 20px", fontSize: "14px", color: "var(--color-text-secondary)" }}>
        Scans alert channels → analyzes patterns → posts to{" "}
        <code style={{ fontFamily: "var(--font-mono)", fontSize: "13px" }}>#eng-falcons</code>
      </p>

      {/* Period + channels card */}
      <div
        style={{
          background: "var(--color-background-primary)",
          border: "0.5px solid var(--color-border-tertiary)",
          borderRadius: "var(--border-radius-lg)",
          padding: "1rem 1.25rem",
          marginBottom: "12px",
        }}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "flex-start",
            gap: "16px",
            flexWrap: "wrap",
          }}
        >
          <div>
            <div
              style={{
                fontSize: "11px",
                fontFamily: "var(--font-mono)",
                textTransform: "uppercase",
                letterSpacing: "0.07em",
                color: "var(--color-text-tertiary)",
                marginBottom: "4px",
              }}
            >
              On-call period
            </div>
            <div style={{ fontSize: "14px", color: "var(--color-text-primary)" }}>
              {fmtFull(start)} 10:00 AM
              <span style={{ color: "var(--color-text-tertiary)", margin: "0 6px" }}>→</span>
              {fmtFull(end)} 10:00 AM
            </div>
          </div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: "6px", paddingTop: "2px" }}>
            {CHANNELS.map((ch) => (
              <span
                key={ch}
                style={{
                  background: "var(--color-background-info)",
                  color: "var(--color-text-info)",
                  border: "0.5px solid var(--color-border-info)",
                  borderRadius: "var(--border-radius-md)",
                  padding: "2px 8px",
                  fontSize: "12px",
                  fontFamily: "var(--font-mono)",
                }}
              >
                {ch}
              </span>
            ))}
          </div>
        </div>
      </div>

      {/* Main action card */}
      <div
        style={{
          background: "var(--color-background-primary)",
          border: "0.5px solid var(--color-border-tertiary)",
          borderRadius: "var(--border-radius-lg)",
          overflow: "hidden",
          marginBottom: "12px",
        }}
      >
        {/* Toolbar */}
        <div
          style={{
            padding: "14px 20px",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            gap: "12px",
            flexWrap: "wrap",
            borderBottom:
              logs.length || preview ? "0.5px solid var(--color-border-tertiary)" : "none",
          }}
        >
          <div style={{ display: "flex", gap: "8px", flexWrap: "wrap", alignItems: "center" }}>
            <button
              onClick={handleGenerate}
              disabled={busy}
              style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "13px" }}
            >
              {phase === "generating" ? (
                <>
                  <span
                    className="spin"
                    style={{
                      display: "inline-block",
                      width: "12px",
                      height: "12px",
                      border: "1.5px solid var(--color-border-secondary)",
                      borderTopColor: "var(--color-text-primary)",
                      borderRadius: "50%",
                    }}
                  />
                  Generating...
                </>
              ) : (
                "Generate handoff"
              )}
            </button>

            {phase === "preview" && (
              <button
                onClick={handlePost}
                style={{ fontSize: "13px", display: "flex", alignItems: "center", gap: "6px" }}
              >
                {phase === "posting" ? (
                  <>
                    <span
                      className="spin"
                      style={{
                        display: "inline-block",
                        width: "12px",
                        height: "12px",
                        border: "1.5px solid var(--color-border-secondary)",
                        borderTopColor: "var(--color-text-primary)",
                        borderRadius: "50%",
                      }}
                    />
                    Posting...
                  </>
                ) : (
                  "Post to #eng-falcons"
                )}
              </button>
            )}

            {(phase === "done" || phase === "error") && (
              <button
                onClick={() => {
                  setPhase("idle");
                  setPreview("");
                  setLogs([]);
                  setError("");
                }}
                style={{ fontSize: "13px" }}
              >
                Start over
              </button>
            )}
          </div>

          {phase === "done" && (
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: "6px",
                fontSize: "13px",
                color: "var(--color-text-success)",
              }}
            >
              <span
                style={{
                  width: "7px",
                  height: "7px",
                  borderRadius: "50%",
                  background: "var(--color-background-success)",
                  border: "1.5px solid var(--color-text-success)",
                  flexShrink: 0,
                }}
              />
              Posted to #eng-falcons
            </div>
          )}

          {phase === "generating" && (
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: "6px",
                fontSize: "12px",
                color: "var(--color-text-tertiary)",
              }}
            >
              <span
                className="pulse-dot"
                style={{
                  width: "6px",
                  height: "6px",
                  borderRadius: "50%",
                  background: "var(--color-text-info)",
                  flexShrink: 0,
                }}
              />
              Reading channels...
            </div>
          )}
        </div>

        {/* Log terminal */}
        <LogTerminal logs={logs} />

        {/* Preview */}
        {preview && (phase === "preview" || phase === "posting" || phase === "done") && (
          <div
            style={{
              padding: "16px 20px",
              borderTop: logs.length ? "0.5px solid var(--color-border-tertiary)" : "none",
            }}
          >
            <div
              style={{
                fontSize: "11px",
                fontFamily: "var(--font-mono)",
                textTransform: "uppercase",
                letterSpacing: "0.07em",
                color: "var(--color-text-tertiary)",
                marginBottom: "10px",
              }}
            >
              Preview — Slack message
            </div>
            <div
              style={{
                background: "#ffffff",
                border: "0.5px solid #e8e8e8",
                borderRadius: "var(--border-radius-md)",
                padding: "14px 18px",
                boxSizing: "border-box",
              }}
            >
              <SlackMessagePreview text={preview} />
            </div>
          </div>
        )}

        {/* Error state */}
        {phase === "error" && error && (
          <div
            style={{
              padding: "12px 20px",
              background: "var(--color-background-danger)",
              borderTop: "0.5px solid var(--color-border-danger)",
              fontSize: "13px",
              fontFamily: "var(--font-mono)",
              color: "var(--color-text-danger)",
            }}
          >
            {error}
          </div>
        )}
      </div>

      {/* Scheduling notes */}
      <div
        style={{
          background: "var(--color-background-primary)",
          border: "0.5px solid var(--color-border-tertiary)",
          borderRadius: "var(--border-radius-lg)",
          overflow: "hidden",
        }}
      >
        <button
          onClick={() => setScheduleOpen((o) => !o)}
          style={{
            width: "100%",
            background: "none",
            border: "none",
            padding: "14px 20px",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            cursor: "pointer",
            fontSize: "13px",
            fontWeight: 500,
            color: "var(--color-text-primary)",
            textAlign: "left",
          }}
        >
          <span>How to fully automate this — every Tuesday at 10:00 AM</span>
          <span style={{ color: "var(--color-text-tertiary)", fontSize: "16px", lineHeight: 1 }}>
            {scheduleOpen ? "−" : "+"}
          </span>
        </button>

        {scheduleOpen && (
          <div
            style={{
              padding: "0 20px 20px",
              borderTop: "0.5px solid var(--color-border-tertiary)",
            }}
          >
            <p
              style={{
                fontSize: "13px",
                color: "var(--color-text-secondary)",
                margin: "14px 0 12px",
              }}
            >
              Extract the two{" "}
              <code style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>fetch()</code>{" "}
              calls (generate + post) into a Node.js script. Set{" "}
              <code style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>
                ANTHROPIC_API_KEY
              </code>{" "}
              as an env var, then schedule with any of these:
            </p>

            <ScheduleBlock
              title="GitHub Actions  (recommended — no infra needed)"
              code={`# .github/workflows/sre-handoff.yml
on:
  schedule:
    - cron: '0 15 * * 2'  # Tuesdays 10 AM ET (UTC-5)
jobs:
  handoff:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: node scripts/sre-handoff.js
        env:
          ANTHROPIC_API_KEY: \${{ secrets.ANTHROPIC_API_KEY }}`}
            />

            <ScheduleBlock
              title="Linux / macOS cron"
              code={`# crontab -e
0 10 * * 2 /usr/bin/node /path/to/sre-handoff.js`}
            />

            <ScheduleBlock
              title="AWS EventBridge + Lambda"
              code={`# EventBridge schedule expression (10 AM ET = 15:00 UTC)
cron(0 15 ? * TUE *)

# Lambda handler: call the same fetch() logic as the Node script`}
            />

            <p
              style={{
                fontSize: "12px",
                color: "var(--color-text-tertiary)",
                margin: "12px 0 0",
                fontFamily: "var(--font-mono)",
              }}
            >
              Tip: the{" "}
              <code style={{ fontFamily: "var(--font-mono)" }}>mcp_servers</code> param passes
              automatically — no OAuth token management needed in your script.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}