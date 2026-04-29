/* @jsx h */
import { h } from "preact";
import { useEffect, useState } from "preact/hooks";
import browserAPI from "@bpev/bext";

// ── Types ──────────────────────────────────────────────────────────────────

interface PageImage {
  domIndex: number;
  src: string;
  alt: string;
}

interface PageList {
  tag: string;
  domIndex: number;
  id: string;
  childCount: number;
  imgCount: number;
  videoCount: number;
  depth: number;
}

interface ScanResult {
  images: PageImage[];
  lists: PageList[];
  error?: string;
}

type LoadState = "loading" | "done" | "error";

// ── Helpers ────────────────────────────────────────────────────────────────

async function scanActiveTab(): Promise<ScanResult> {
  const res = (await browserAPI.runtime.sendMessage({
    action: "scanActiveTab",
  })) as ScanResult;
  return res;
}

// ── Styles (inline for portability) ───────────────────────────────────────

const S = {
  root: {
    fontFamily: "system-ui, sans-serif",
    fontSize: "12px",
    color: "#e2e8f0",
    padding: "8px 0",
    width: "100%",
  } as h.JSX.CSSProperties,

  section: {
    marginBottom: "10px",
  } as h.JSX.CSSProperties,

  sectionHeader: {
    fontSize: "10px",
    fontWeight: 700,
    letterSpacing: "0.08em",
    textTransform: "uppercase" as const,
    color: "#94a3b8",
    padding: "0 12px 4px",
    borderBottom: "1px solid #1e293b",
    marginBottom: "4px",
  } as h.JSX.CSSProperties,

  listItem: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    padding: "5px 12px",
    cursor: "pointer",
    borderRadius: "6px",
    transition: "background 0.15s",
  } as h.JSX.CSSProperties,

  tag: {
    fontSize: "10px",
    fontWeight: 700,
    background: "#1e40af33",
    color: "#93c5fd",
    border: "1px solid #1e40af55",
    borderRadius: "4px",
    padding: "1px 5px",
    flexShrink: 0,
  } as h.JSX.CSSProperties,

  listMeta: {
    color: "#94a3b8",
    whiteSpace: "nowrap" as const,
    overflow: "hidden",
    textOverflow: "ellipsis",
    flex: 1,
  } as h.JSX.CSSProperties,

  badge: {
    fontSize: "10px",
    background: "#0f172a",
    color: "#64748b",
    border: "1px solid #1e293b",
    borderRadius: "999px",
    padding: "1px 6px",
    flexShrink: 0,
  } as h.JSX.CSSProperties,

  imgRow: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    padding: "4px 12px",
    cursor: "pointer",
    borderRadius: "6px",
  } as h.JSX.CSSProperties,

  thumb: {
    width: "32px",
    height: "32px",
    objectFit: "cover" as const,
    borderRadius: "4px",
    flexShrink: 0,
    background: "#1e293b",
  } as h.JSX.CSSProperties,

  imgSrc: {
    color: "#94a3b8",
    flex: 1,
    overflow: "hidden",
    textOverflow: "ellipsis",
    whiteSpace: "nowrap" as const,
  } as h.JSX.CSSProperties,

  dimText: {
    color: "#475569",
    padding: "12px",
    textAlign: "center" as const,
  } as h.JSX.CSSProperties,

  spinner: {
    display: "flex",
    justifyContent: "center",
    padding: "16px",
    color: "#475569",
  } as h.JSX.CSSProperties,
};

// ── Component ──────────────────────────────────────────────────────────────

export default function TabItems() {
  const [state, setState] = useState<LoadState>("loading");
  const [result, setResult] = useState<ScanResult>({ images: [], lists: [] });

  useEffect(() => {
    scanActiveTab()
      .then((res) => {
        setResult(res);
        setState(res.error ? "error" : "done");
      })
      .catch(() => setState("error"));
  }, []);

  if (state === "loading") {
    return <div style={S.spinner}>Scanning page…</div>;
  }

  if (state === "error" || result.error) {
    return (
      <div style={S.dimText}>
        {result.error ?? "Could not scan page."}
      </div>
    );
  }

  const { lists, images } = result;

  return (
    <div style={S.root}>
      {/* ── Image containers ── */}
      {lists.length > 0 && (
        <div style={S.section}>
          <div style={S.sectionHeader}>
            Image containers ({lists.length})
          </div>
          {lists.map((l) => (
            <div
              key={`${l.tag}-${l.domIndex}`}
              style={S.listItem}
              title={l.id ? `#${l.id}` : `${l.tag}[${l.domIndex}]`}
            >
              <span style={S.tag}>&lt;{l.tag}&gt;</span>
              <span style={S.listMeta}>
                {l.id ? `#${l.id}` : `[${l.domIndex}]`}
                {"  "}
                <span style={{ color: "#475569" }}>
                  {l.childCount} children
                </span>
              </span>
              <span style={S.badge}>
                {l.imgCount > 0 && `${l.imgCount}🖼`}
                {l.videoCount > 0 && ` ${l.videoCount}🎬`}
              </span>
            </div>
          ))}
        </div>
      )}

      {/* ── Individual images ── */}
      {images.length > 0 && (
        <div style={S.section}>
          <div style={S.sectionHeader}>Images ({images.length})</div>
          {images.map((img) => (
            <div key={img.domIndex} style={S.imgRow} title={img.src}>
              <img
                src={img.src}
                alt={img.alt}
                style={S.thumb}
                loading="lazy"
              />
              <span style={S.imgSrc}>
                {img.alt || new URL(img.src).pathname.split("/").pop() || img.src}
              </span>
            </div>
          ))}
        </div>
      )}

      {lists.length === 0 && images.length === 0 && (
        <div style={S.dimText}>No images found on this page.</div>
      )}
    </div>
  );
}
