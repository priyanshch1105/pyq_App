import { getApiUrl, showToast } from './main.js';

const API_URL = getApiUrl();
const token = localStorage.getItem('adminToken');

if (!token) {
  window.location.href = '/';
}

function handle401(res) {
  if (res.status === 401 || res.status === 403) {
    localStorage.removeItem('adminToken');
    window.location.href = '/';
    return true;
  }
  return false;
}

function formatDate(value) {
  if (!value) return 'Unknown time';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return 'Unknown time';
  return date.toLocaleString();
}

function renderAnnouncementHistory(items) {
  const container = document.getElementById('announcementHistory');
  if (!container) return;

  if (!items.length) {
    container.innerHTML = '<div class="empty-state">No announcements created yet.</div>';
    return;
  }

  container.innerHTML = items
    .map(
      (item) => `
        <article class="history-card">
          <div class="history-header">
            <div>
              <h4>${item.title}</h4>
              <p>${formatDate(item.created_at)}</p>
            </div>
            <span class="history-badge ${item.is_premium_only ? 'premium' : 'public'}">
              ${item.is_premium_only ? 'Premium only' : 'All users'}
            </span>
          </div>
          <p class="history-body">${item.content}</p>
        </article>
      `,
    )
    .join('');
}

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('logoutBtn')?.addEventListener('click', () => {
    localStorage.removeItem('adminToken');
    window.location.href = '/';
  });

  async function loadStats() {
    try {
      const res = await fetch(`${API_URL}/admin/stats`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (handle401(res)) return;
      if (!res.ok) throw new Error('Failed to load stats');

      const data = await res.json();
      document.getElementById('stat-total-users').textContent = data.total_users;
      document.getElementById('stat-premium-users').textContent = data.premium_users;
      document.getElementById('stat-total-questions').textContent = data.total_questions;
    } catch (_) {
      showToast('Error loading server stats', true);
    }
  }

  async function loadAnnouncements() {
    try {
      const res = await fetch(`${API_URL}/admin/announcements`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (handle401(res)) return;
      if (!res.ok) throw new Error('Failed to load announcements');

      const data = await res.json();
      renderAnnouncementHistory(Array.isArray(data) ? data : []);
    } catch (_) {
      showToast('Error loading announcement history', true);
    }
  }

  document.getElementById('announcementForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('announceBtn');
    btn.disabled = true;
    btn.textContent = 'Dispatching...';

    const payload = {
      title: document.getElementById('announceTitle').value.trim(),
      content: document.getElementById('announceContent').value.trim(),
      is_premium_only: document.getElementById('announcePremium').checked,
    };

    try {
      const res = await fetch(`${API_URL}/admin/announcements`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(payload),
      });
      if (handle401(res)) return;
      if (!res.ok) throw new Error('Failed to dispatch broadcast');

      showToast('Broadcast dispatched successfully');
      e.target.reset();
      loadAnnouncements();
    } catch (err) {
      showToast(err.message || 'Broadcast failed', true);
    } finally {
      btn.disabled = false;
      btn.textContent = 'Dispatch Broadcast';
    }
  });

  document.getElementById('questionForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('questionBtn');
    btn.disabled = true;
    btn.textContent = 'Injecting...';

    const payload = {
      exam: document.getElementById('qExam').value.trim(),
      year: parseInt(document.getElementById('qYear').value, 10) || 2024,
      subject: document.getElementById('qSubject').value.trim(),
      topic: document.getElementById('qTopic').value.trim(),
      difficulty: parseInt(document.getElementById('qDifficulty').value, 10) || 1,
      question: document.getElementById('qBody').value.trim(),
      options: {
        A: document.getElementById('qOptionA').value.trim(),
        B: document.getElementById('qOptionB').value.trim(),
        C: document.getElementById('qOptionC').value.trim(),
        D: document.getElementById('qOptionD').value.trim(),
      },
      correct_answer: document.getElementById('qAnswer').value.trim().toUpperCase(),
      explanation: document.getElementById('qExplanation').value.trim(),
    };

    try {
      const res = await fetch(`${API_URL}/admin/questions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(payload),
      });
      if (handle401(res)) return;
      if (!res.ok) throw new Error('Failed to inject question into databank');

      showToast('Question indexed successfully');
      e.target.reset();
      document.getElementById('qYear').value = '2024';
      document.getElementById('qDifficulty').value = '1';
      loadStats();
    } catch (err) {
      showToast(err.message || 'Question upload failed', true);
    } finally {
      btn.disabled = false;
      btn.textContent = 'Inject into Database';
    }
  });

  document.getElementById('refreshAnnouncementsBtn')?.addEventListener('click', () => {
    loadAnnouncements();
  });

  loadStats();
  loadAnnouncements();
});
