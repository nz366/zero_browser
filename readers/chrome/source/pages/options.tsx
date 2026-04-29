/* @jsx h */
import { h } from 'preact'

export interface OptionsProps {
  default?: boolean
  path?: string
}

export default function Options(_props: OptionsProps) {

  // TODO: set minimum image size
  // TODO: set minimum video size
  return (
    <div>
      <h1>It feels like... options?</h1>
      <a href='#home'>go to home</a>
    </div>
  )
}
