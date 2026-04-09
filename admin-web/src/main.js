const DEFAULT_API_URL = 'http://127.0.0.1:8000';

export function getApiUrl() {
  return localStorage.getItem('pyqApiUrl') || DEFAULT_API_URL;
}

export function setApiUrl(url) {
  const normalized = (url || '').trim().replace(/\/+$/, '');
  const finalUrl = normalized || DEFAULT_API_URL;
  localStorage.setItem('pyqApiUrl', finalUrl);
  return finalUrl;
}

export function showToast(message, isError = false) {
  const toast = document.getElementById('toast');
  if (!toast) return;

  toast.textContent = message;
  toast.className = `alert show ${isError ? 'alert-error' : 'alert-success'}`;
  setTimeout(() => {
    toast.className = 'alert';
  }, 3000);
}

document.addEventListener('DOMContentLoaded', () => {
  const token = localStorage.getItem('adminToken');
  const apiInput = document.getElementById('apiBaseUrl');

  if (apiInput) {
    apiInput.value = getApiUrl();
  }

  if (token && window.location.pathname === '/') {
    window.location.href = '/dashboard.html';
  }

  const loginForm = document.getElementById('loginForm');
  if (!loginForm) return;

  loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const btn = document.getElementById('loginBtn');
    const apiUrl = setApiUrl(apiInput?.value);

    btn.textContent = 'Authenticating...';
    btn.disabled = true;

    try {
      const response = await fetch(`${apiUrl}/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });

      if (!response.ok) {
        throw new Error('Invalid credentials. Check your email or password.');
      }

      const data = await response.json();
      const accessToken = data.access_token;

      const meRes = await fetch(`${apiUrl}/auth/me`, {
        headers: { Authorization: `Bearer ${accessToken}` },
      });

      if (!meRes.ok) {
        throw new Error('Failed to retrieve user scope.');
      }

      const profile = await meRes.json();
      if (!profile.is_admin) {
        throw new Error('Access denied. This account is not marked as admin.');
      }

      localStorage.setItem('adminToken', accessToken);
      window.location.href = '/dashboard.html';
    } catch (error) {
      showToast(error.message || 'Login failed', true);
    } finally {
      btn.textContent = 'Authenticate as Admin';
      btn.disabled = false;
    }
  });
});
