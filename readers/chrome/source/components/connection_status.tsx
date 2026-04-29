/* @jsx h */
import { h } from 'preact'
import { useEffect, useState } from 'preact/hooks'
import browserAPI from '@bpev/bext'

type Status = 'connecting' | 'open' | 'closing' | 'closed'

const WS_STATE_MAP: Record<number, Status> = {
  0: 'connecting',
  1: 'open',
  2: 'closing',
  3: 'closed',
}

const LABEL: Record<Status, string> = {
  connecting: 'Connecting…',
  open: 'Connected',
  closing: 'Closing…',
  closed: 'Disconnected',
}

const COLOR: Record<Status, string> = {
  connecting: '#f59e0b',
  open: '#22c55e',
  closing: '#f59e0b',
  closed: '#ef4444',
}

async function fetchStatus(): Promise<Status> {
  try {
    const res = await browserAPI.runtime.sendMessage({ action: 'getStatus' }) as { state: number }
    const key = (res?.state ?? 3) as keyof typeof WS_STATE_MAP
    return WS_STATE_MAP[key] ?? 'closed'
  } catch {
    return 'closed'
  }
}

export default function ConnectionStatus() {
  const [status, setStatus] = useState<Status>('connecting')

  useEffect(() => {
    let alive = true

    async function poll() {
      const s = await fetchStatus()
      if (alive) setStatus(s)
    }

    poll()
    const id = setInterval(poll, 2000)
    return () => { alive = false; clearInterval(id) }
  }, [])

  const color = COLOR[status]
  const label = LABEL[status]
  const isPulsing = status === 'connecting' || status === 'closing'

  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      gap: '6px',
      padding: '4px 10px',
      borderRadius: '999px',
      background: `${color}22`,
      border: `1px solid ${color}55`,
      fontSize: '11px',
      fontFamily: 'system-ui, sans-serif',
      color,
      fontWeight: 600,
      letterSpacing: '0.02em',
      width: 'fit-content',
    }}>
      <span style={{
        width: '7px',
        height: '7px',
        borderRadius: '50%',
        background: color,
        display: 'inline-block',
        animation: isPulsing ? 'pulse 1.2s ease-in-out infinite' : 'none',
      }} />
      {label}
      <style>{`
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.35; }
        }
      `}</style>
    </div>
  )
}
