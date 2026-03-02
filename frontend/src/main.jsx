import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'

console.log("React entrypoint starting...");
try {
  createRoot(document.getElementById('root')).render(
    <StrictMode>
      <App />
    </StrictMode>,
  )
  console.log("React render called successfully.");
} catch (e) {
  console.error("React render failed:", e);
}
