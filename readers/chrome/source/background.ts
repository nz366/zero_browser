import type Chrome from "@bpev/bext/types/chrome";
import browserAPI from "@bpev/bext";

// ─── Page-scanning helper ─────────────────────────────────────────────────────
// Runs in the context of the target tab via chrome.scripting.executeScript.
// Returns { images, lists } — both arrays serialisable as JSON.

function scanTab(tabId: number) {
  return browserAPI.scripting
    .executeScript({
      target: { tabId },
      func: () => {
        const images = Array.from(document.querySelectorAll("img"))
          .map((img, domIndex) => ({ img, domIndex }))
          .filter(({ img }) => img.naturalWidth > 4 && img.naturalHeight > 4)
          .map(({ img, domIndex }) => ({
            domIndex,
            src: img.currentSrc || img.src || "",
            alt: img.alt || "",
          }));

        const lists: any[] = [];
        const listTags = ["ul", "ol", "div", "section", "article", "figure", "nav"];

        function countDesc(el: Element, sel: string) {
          return el.querySelectorAll(sel).length;
        }
        function maxDepth(el: Element, sel: string) {
          const found = Array.from(el.querySelectorAll(sel));
          if (!found.length) return 0;
          let max = 0;
          found.forEach((child) => {
            let d = 0, cur: Element | null = child;
            while (cur && cur !== el) { cur = cur.parentElement; d++; }
            if (d > max) max = d;
          });
          return max;
        }

        listTags.forEach((tag) => {
          document.querySelectorAll(tag).forEach((el, domIndex) => {
            const imgs = countDesc(el, "img");
            const vids = countDesc(el, "video");
            if (imgs + vids >= 2) {
              lists.push({
                tag,
                domIndex,
                id: el.id || "",
                childCount: el.children.length,
                imgCount: imgs,
                videoCount: vids,
                depth: maxDepth(el, "img, video"),
              });
            }
          });
        });

        return { images, lists };
      },
    })
    .then((results: any[]) => results[0]?.result || { images: [], lists: [] });
}

// ─── WebSocket connection to local server ─────────────────────────────────────

let socket: WebSocket | null = null;
let reconnectTimer: ReturnType<typeof setTimeout> | null = null;

function connect() {
  // Don't open a second socket if one is already open or connecting
  if (socket && (socket.readyState === WebSocket.OPEN || socket.readyState === WebSocket.CONNECTING)) {
    return;
  }

  if (reconnectTimer !== null) {
    clearTimeout(reconnectTimer);
    reconnectTimer = null;
  }

  try {
    socket = new WebSocket("ws://127.0.0.1:9191");
  } catch {
    reconnectTimer = setTimeout(connect, 3000);
    return;
  }

  socket.onmessage = async (event) => {
    try {
      const data = JSON.parse(event.data);
      // TODO: bind request tab id to reuse existing tab for responding with data or opening a new tab

      // Action: fetch — open a hidden tab, scan it, send results back
      if (data.action === "fetch" && data.url) {
        const tab = await browserAPI.tabs.create({ url: data.url, active: false });

        const onUpdated = (tabId: number, changeInfo: Chrome.TabChangeInfo) => {
          if (tabId !== tab.id || changeInfo.status !== "complete") return;
          browserAPI.tabs.onUpdated.removeListener(onUpdated);

          scanTab(tab.id!)
            .then((res) => {
              socket?.send(JSON.stringify({ requestId: data.requestId, ...res }));
            })
            .catch((err: any) => {
              socket?.send(JSON.stringify({ requestId: data.requestId, error: err.message }));
            });
        };

        browserAPI.tabs.onUpdated.addListener(onUpdated);
      }
    } catch (e: any) {
      console.error(e);
    }
  };

  socket.onclose = () => {
    socket = null;
    reconnectTimer = setTimeout(connect, 3000);
  };
  socket.onerror = () => socket?.close();
}

// ─── Keepalive: prevent MV3 service-worker idle termination ──────────────────
// Chrome terminates inactive service workers after ~30 s. The alarm fires every
// 25 s, keeping the worker alive and ensuring the WebSocket is reconnected if
// it was dropped while the worker was suspended.

// Use raw globalThis.chrome for alarms — @bpev/bext doesn't wrap this API.
// Chrome minimum alarm interval is 30 s (0.5 min); we use 0.4 min (~24 s) in
// development but clamp to 0.5 in production to stay within policy.
const _chrome = (globalThis as any).chrome as Chrome;
_chrome.alarms.create("keepalive", { periodInMinutes: 0.5 });

_chrome.alarms.onAlarm.addListener((alarm: { name: string }) => {
  if (alarm.name === "keepalive") {
    connect(); // no-op if socket is already OPEN or CONNECTING
  }
});

connect();

// ─── Popup message handlers ───────────────────────────────────────────────────

browserAPI.runtime.onMessage.addListener(
  (
    message: { action: string },
    _sender: unknown,
    sendResponse: (r: unknown) => void,
  ) => {
    // WebSocket connection status
    if (message?.action === "getStatus") {
      sendResponse({ state: socket ? socket.readyState : 3 });
      return true;
    }

    // Scan whichever tab is currently active and return images + lists
    if (message?.action === "scanActiveTab") {
      browserAPI.tabs
        .query({ active: true, currentWindow: true })
        .then((tabs: any[]) => {
          const tab = tabs[0];
          if (!tab?.id) {
            sendResponse({ images: [], lists: [], error: "No active tab" });
            return Promise.resolve(null);
          }
          return scanTab(tab.id);
        })
        .then((result: any) => {
          if (result) sendResponse(result);
        })
        .catch((err: any) => {
          sendResponse({ images: [], lists: [], error: err.message });
        });

      return true; // keep message channel open for async sendResponse
    }
  },
);
