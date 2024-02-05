import React from 'react';
import { createRoot } from 'react-dom/client';
import Onboarding from './pages/Onboarding';
import App from './App';

const container = document.getElementById('root');
const root = createRoot(container!);

root.render(
  <React.StrictMode>
      <App />
    <Onboarding />
  </React.StrictMode>
);