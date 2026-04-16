import { useEffect, useMemo, useRef, useState } from 'react';
import { API_BASE_URL } from './config/env';

function getWsBaseUrl() {
  if (API_BASE_URL.startsWith('https://')) {
    return API_BASE_URL.replace('https://', 'wss://');
  }
  if (API_BASE_URL.startsWith('http://')) {
    return API_BASE_URL.replace('http://', 'ws://');
  }
  return API_BASE_URL;
}

async function apiFetch(path, { token, method = 'GET', body, headers = {} } = {}) {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    method,
    headers: {
      ...(body instanceof FormData ? {} : { 'Content-Type': 'application/json' }),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...headers,
    },
    body: body instanceof FormData ? body : body ? JSON.stringify(body) : undefined,
  });

  if (!response.ok) {
    let detail = 'Request failed';
    try {
      const data = await response.json();
      detail = data.detail || detail;
    } catch (error) {
      detail = response.statusText || detail;
    }
    throw new Error(detail);
  }

  if (response.status === 204) {
    return null;
  }

  return response.json();
}

const navItems = [
  { id: 'dashboard', label: 'Dashboard' },
  { id: 'notifications', label: 'Notifications' },
  { id: 'questions', label: 'Question Upload' },
];

const emptyStats = {
  total_users: 0,
  premium_users: 0,
  total_questions: 0,
  active_users: 0,
  active_rooms: 0,
  total_announcements: 0,
};

const emptyRealtime = {
  active_users: 0,
  active_rooms: 0,
  tracked_users: [],
};

export default function App() {
  const [token, setToken] = useState(() => localStorage.getItem('pyq_admin_token') || '');
  const [me, setMe] = useState(null);
  const [activeTab, setActiveTab] = useState('dashboard');
  const [stats, setStats] = useState(emptyStats);
  const [realtime, setRealtime] = useState(emptyRealtime);
  const [announcements, setAnnouncements] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');

  const [loginForm, setLoginForm] = useState({ email: '', password: '' });
  const [announcementForm, setAnnouncementForm] = useState({
    title: '',
    content: '',
    is_premium_only: false,
  });
  const [uploadResult, setUploadResult] = useState(null);
  const [selectedFile, setSelectedFile] = useState(null);

  const wsRef = useRef(null);
  const pingRef = useRef(null);

  const isAuthenticated = Boolean(token && me?.is_admin);
  const wsBaseUrl = useMemo(() => getWsBaseUrl(), []);

  useEffect(() => {
    if (!token) {
      setMe(null);
      return;
    }

    let ignore = false;
    setLoading(true);
    apiFetch('/auth/me', { token })
      .then((user) => {
        if (ignore) {
          return;
        }
        if (!user.is_admin) {
          throw new Error('This account is not an admin account.');
        }
        setMe(user);
        setError('');
      })
      .catch((err) => {
        if (ignore) {
          return;
        }
        logout();
        setError(err.message);
      })
      .finally(() => {
        if (!ignore) {
          setLoading(false);
        }
      });

    return () => {
      ignore = true;
    };
  }, [token]);

  useEffect(() => {
    if (!isAuthenticated) {
      return;
    }
    loadDashboard();
    loadAnnouncements();
  }, [isAuthenticated]);

  useEffect(() => {
    if (!isAuthenticated) {
      if (wsRef.current) {
        wsRef.current.close();
      }
      if (pingRef.current) {
        window.clearInterval(pingRef.current);
      }
      return;
    }

    const socket = new WebSocket(`${wsBaseUrl}/admin/ws/dashboard?token=${encodeURIComponent(token)}`);
    wsRef.current = socket;

    socket.onmessage = (event) => {
      try {
        const payload = JSON.parse(event.data);
        if (typeof payload.active_users === 'number') {
          setRealtime({
            active_users: payload.active_users,
            active_rooms: payload.active_rooms || 0,
            tracked_users: payload.tracked_users || [],
          });
          setStats((prev) => ({
            ...prev,
            active_users: payload.active_users,
            active_rooms: payload.active_rooms || 0,
          }));
        }
      } catch (err) {
        console.error('Invalid websocket payload', err);
      }
    };

    socket.onerror = () => {
      setError('Realtime dashboard connection lost. Manual refresh still works.');
    };

    pingRef.current = window.setInterval(() => {
      if (socket.readyState === WebSocket.OPEN) {
        socket.send(JSON.stringify({ event: 'ping' }));
      }
    }, 10000);

    return () => {
      socket.close();
      if (pingRef.current) {
        window.clearInterval(pingRef.current);
      }
    };
  }, [isAuthenticated, token, wsBaseUrl]);

  async function loadDashboard() {
    try {
      const [statsRes, realtimeRes] = await Promise.all([
        apiFetch('/admin/stats', { token }),
        apiFetch('/admin/realtime', { token }),
      ]);
      setStats(statsRes);
      setRealtime(realtimeRes);
    } catch (err) {
      setError(err.message);
    }
  }

  async function loadAnnouncements() {
    try {
      const data = await apiFetch('/admin/announcements', { token });
      setAnnouncements(data);
    } catch (err) {
      setError(err.message);
    }
  }

  async function handleLogin(event) {
    event.preventDefault();
    setLoading(true);
    setError('');
    try {
      const data = await apiFetch('/auth/login', {
        method: 'POST',
        body: loginForm,
      });
      localStorage.setItem('pyq_admin_token', data.access_token);
      setToken(data.access_token);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  function logout() {
    localStorage.removeItem('pyq_admin_token');
    setToken('');
    setMe(null);
  }

  async function handleAnnouncementSubmit(event) {
    event.preventDefault();
    setLoading(true);
    setError('');
    setToast('');
    try {
      const announcement = await apiFetch('/admin/announcements', {
        token,
        method: 'POST',
        body: announcementForm,
      });
      setAnnouncements((prev) => [announcement, ...prev]);
      setAnnouncementForm({ title: '', content: '', is_premium_only: false });
      setStats((prev) => ({
        ...prev,
        total_announcements: prev.total_announcements + 1,
      }));
      setToast('Notification sab users ke liye queue ho gayi.');
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function handleUpload(event) {
    event.preventDefault();
    if (!selectedFile) {
      setError('Please choose a JSON file first.');
      return;
    }

    const formData = new FormData();
    formData.append('file', selectedFile);

    setLoading(true);
    setError('');
    setToast('');
    setUploadResult(null);
    try {
      const result = await apiFetch('/admin/bulk-questions', {
        token,
        method: 'POST',
        body: formData,
      });
      setUploadResult(result);
      setToast('Question bank successfully upload ho gaya.');
      await loadDashboard();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  if (!isAuthenticated) {
    return (
      <div className="auth-shell">
        <div className="auth-card">
          <p className="eyebrow">PYQ Admin</p>
          <h1>React admin panel for your existing FastAPI backend</h1>
          <p className="muted">
            Login with an admin account to monitor active users, broadcast notifications,
            and upload question banks from JSON.
          </p>
          <form className="form-grid" onSubmit={handleLogin}>
            <label>
              <span>Email</span>
              <input
                type="email"
                value={loginForm.email}
                onChange={(event) => setLoginForm((prev) => ({ ...prev, email: event.target.value }))}
                placeholder="admin@example.com"
                required
              />
            </label>
            <label>
              <span>Password</span>
              <input
                type="password"
                value={loginForm.password}
                onChange={(event) => setLoginForm((prev) => ({ ...prev, password: event.target.value }))}
                placeholder="********"
                required
              />
            </label>
            <button type="submit" disabled={loading}>
              {loading ? 'Signing in...' : 'Login as Admin'}
            </button>
          </form>
          {error ? <p className="error-text">{error}</p> : null}
        </div>
      </div>
    );
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div>
          <p className="eyebrow">PYQ Control Room</p>
          <h2>{me?.email}</h2>
          <p className="muted">Existing backend same rahega. Admin panel React se chalega.</p>
        </div>
        <nav className="nav-list">
          {navItems.map((item) => (
            <button
              key={item.id}
              type="button"
              className={item.id === activeTab ? 'nav-item active' : 'nav-item'}
              onClick={() => setActiveTab(item.id)}
            >
              {item.label}
            </button>
          ))}
        </nav>
        <button type="button" className="ghost-button" onClick={logout}>
          Logout
        </button>
      </aside>

      <main className="content">
        <header className="page-header">
          <div>
            <h1>
              {activeTab === 'dashboard' && 'Live Dashboard'}
              {activeTab === 'notifications' && 'Broadcast Notifications'}
              {activeTab === 'questions' && 'Bulk Question Upload'}
            </h1>
            <p className="muted">
              API Base URL: <code>{API_BASE_URL}</code>
            </p>
          </div>
          <button type="button" className="ghost-button" onClick={loadDashboard}>
            Refresh
          </button>
        </header>

        {error ? <div className="banner error-banner">{error}</div> : null}
        {toast ? <div className="banner success-banner">{toast}</div> : null}

        {activeTab === 'dashboard' ? (
          <section className="stack">
            <div className="stats-grid">
              <StatCard label="Live Active Users" value={stats.active_users} accent="sunset" />
              <StatCard label="Active Study Rooms" value={stats.active_rooms} accent="ocean" />
              <StatCard label="Total Users" value={stats.total_users} accent="forest" />
              <StatCard label="Premium Users" value={stats.premium_users} accent="amber" />
              <StatCard label="Question Bank" value={stats.total_questions} accent="berry" />
              <StatCard label="Notifications Sent" value={stats.total_announcements} accent="steel" />
            </div>

            <div className="panel-grid">
              <section className="panel">
                <div className="panel-heading">
                  <div>
                    <h3>Recent active users</h3>
                    <p className="muted">5 minute activity window based on authenticated traffic.</p>
                  </div>
                  <span className="live-pill">Live</span>
                </div>
                <div className="activity-list">
                  {realtime.tracked_users.length ? (
                    realtime.tracked_users.map((user) => (
                      <article className="activity-item" key={user.user_id}>
                        <strong>{user.email}</strong>
                        <span>{formatDateTime(user.last_seen)}</span>
                      </article>
                    ))
                  ) : (
                    <p className="muted">Abhi koi recent active user track nahi hua.</p>
                  )}
                </div>
              </section>

              <section className="panel">
                <div className="panel-heading">
                  <div>
                    <h3>Realtime integration notes</h3>
                    <p className="muted">Flutter app bhi in endpoints ko immediately consume kar sakti hai.</p>
                  </div>
                </div>
                <ul className="notes-list">
                  <li>`POST /admin/announcements` se push notification data create hota hai.</li>
                  <li>`WS /announcements/ws?token=...` se app live announcement events le sakti hai.</li>
                  <li>`POST /admin/bulk-questions` se upload ke turant baad `/questions` API updated bank serve karega.</li>
                </ul>
              </section>
            </div>
          </section>
        ) : null}

        {activeTab === 'notifications' ? (
          <section className="stack">
            <section className="panel">
              <div className="panel-heading">
                <div>
                  <h3>Send to all users</h3>
                  <p className="muted">Premium-only toggle se segmented notification bhi bhej sakte ho.</p>
                </div>
              </div>
              <form className="form-grid" onSubmit={handleAnnouncementSubmit}>
                <label>
                  <span>Title</span>
                  <input
                    type="text"
                    value={announcementForm.title}
                    onChange={(event) =>
                      setAnnouncementForm((prev) => ({ ...prev, title: event.target.value }))
                    }
                    placeholder="New mock test live"
                    required
                  />
                </label>
                <label>
                  <span>Message</span>
                  <textarea
                    rows="5"
                    value={announcementForm.content}
                    onChange={(event) =>
                      setAnnouncementForm((prev) => ({ ...prev, content: event.target.value }))
                    }
                    placeholder="Aaj raat 8 baje live practice challenge start hoga..."
                    required
                  />
                </label>
                <label className="checkbox-row">
                  <input
                    type="checkbox"
                    checked={announcementForm.is_premium_only}
                    onChange={(event) =>
                      setAnnouncementForm((prev) => ({
                        ...prev,
                        is_premium_only: event.target.checked,
                      }))
                    }
                  />
                  <span>Only premium users</span>
                </label>
                <button type="submit" disabled={loading}>
                  {loading ? 'Sending...' : 'Broadcast notification'}
                </button>
              </form>
            </section>

            <section className="panel">
              <div className="panel-heading">
                <div>
                  <h3>Notification history</h3>
                  <p className="muted">Latest announcements first.</p>
                </div>
              </div>
              <div className="announcement-list">
                {announcements.map((item) => (
                  <article className="announcement-item" key={item.id}>
                    <div className="announcement-topline">
                      <strong>{item.title}</strong>
                      <span>{item.is_premium_only ? 'Premium' : 'All users'}</span>
                    </div>
                    <p>{item.content}</p>
                    <small>{formatDateTime(item.created_at)}</small>
                  </article>
                ))}
              </div>
            </section>
          </section>
        ) : null}

        {activeTab === 'questions' ? (
          <section className="stack">
            <section className="panel">
              <div className="panel-heading">
                <div>
                  <h3>Upload JSON question bank</h3>
                  <p className="muted">Ek baar file dalo, backend duplicate check ke saath import karega.</p>
                </div>
              </div>
              <form className="form-grid" onSubmit={handleUpload}>
                <label>
                  <span>Question file</span>
                  <input
                    type="file"
                    accept=".json,application/json"
                    onChange={(event) => setSelectedFile(event.target.files?.[0] || null)}
                  />
                </label>
                <button type="submit" disabled={loading}>
                  {loading ? 'Uploading...' : 'Upload JSON'}
                </button>
              </form>
              <div className="json-hint">
                <h4>Expected JSON shape</h4>
                <pre>{`[
  {
    "exam": "JEE_MAIN",
    "subject": "Physics",
    "topic": "Kinematics",
    "year": 2024,
    "difficulty": 2,
    "question": "Question text",
    "options": { "A": "...", "B": "...", "C": "...", "D": "..." },
    "correct_answer": "A",
    "explanation": "Why A is correct"
  }
]`}</pre>
              </div>
            </section>

            {uploadResult ? (
              <section className="panel">
                <div className="panel-heading">
                  <div>
                    <h3>Last upload result</h3>
                    <p className="muted">Import summary from backend.</p>
                  </div>
                </div>
                <div className="stats-grid compact">
                  <StatCard label="Processed" value={uploadResult.total_processed} accent="steel" />
                  <StatCard label="Inserted" value={uploadResult.inserted} accent="forest" />
                  <StatCard label="Skipped" value={uploadResult.skipped} accent="amber" />
                  <StatCard label="Failed" value={uploadResult.failed} accent="sunset" />
                </div>
                {uploadResult.errors?.length ? (
                  <div className="error-list">
                    {uploadResult.errors.map((item, index) => (
                      <p key={`${item.row}-${index}`}>
                        Row {item.row}: {item.error}
                      </p>
                    ))}
                  </div>
                ) : (
                  <p className="muted">No row-level errors.</p>
                )}
              </section>
            ) : null}
          </section>
        ) : null}
      </main>
    </div>
  );
}

function StatCard({ label, value, accent }) {
  return (
    <article className={`stat-card ${accent}`}>
      <span>{label}</span>
      <strong>{value}</strong>
    </article>
  );
}

function formatDateTime(value) {
  try {
    return new Date(value).toLocaleString();
  } catch (error) {
    return value;
  }
}
