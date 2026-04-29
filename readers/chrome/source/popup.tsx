/* @jsx h */
import { h, render } from 'preact'
import OptionsButton from './components/options_button.tsx'
import ConnectionStatus from './components/connection_status.tsx'
import TabItems from './components/tab_items.tsx'

const mountPoint = document.getElementById('mount')

if (mountPoint) {
  render(
    <main>
      <ConnectionStatus />
      <TabItems />
      <OptionsButton />
    </main>,
    mountPoint,
  )
}
