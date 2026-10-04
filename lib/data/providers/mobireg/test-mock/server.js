const express = require('express');
const data = require('./data');

const app = express();
const PORT = process.env.PORT || 8080;
const scenarios = {};
const PROTOCOL_VERSION = 1;
const TTL_FRESH_SECONDS = 60;
const TTL_RETAIN_SECONDS = 1209600;
const MOCK_USER_ID = 8256;
const MOCK_PARENT_ROLE = 2;
const MOCK_SENT_MESSAGE_ID = 23001;
const WRONG_PUPIL_ERRNO = 102;
const ACCOUNT_VIEWS = ['users', 'register-fcm', 'notif-settings'];

const isPupilOnAccount = (body, school) => {
  const account = data.appViews.users(body, school);
  return account.pupils.some(pupil => String(pupil.id) === String(body.pupilId));
};

app.use(express.urlencoded({ extended: true }));
app.use(express.json());

app.use((req, _res, next) => {
  const raw = req.body ? JSON.stringify(req.body) : '';
  const body = req.method === 'POST' ? raw.substring(0, 100) : '';
  console.log(`${req.method} ${req.path} ${body}`);
  next();
});

app.post('/test/scenario', (req, res) => {
  const { school } = req.body;
  if (!school) return res.status(400).json({ error: 'school is required' });
  scenarios[school] = { ...scenarios[school], ...req.body };
  res.json({ status: 'ok', school });
});

app.post('/test/reset', (_req, res) => {
  Object.keys(scenarios).forEach(k => delete scenarios[k]);
  res.json({ status: 'ok' });
});

app.get('/test/health', (_req, res) => {
  res.json({ status: 'ok', scenarios: Object.keys(scenarios) });
});

app.post('/:school/modules/api/auth.php', (req, res) => {
  const { login, password } = req.body;
  const scenario = scenarios[req.params.school] || {};
  if (scenario.failLogin || login !== data.credentials.login || password !== data.credentials.password) {
    return res.json({ status: 'ERROR', message: 'Nieprawidłowy login lub hasło' });
  }
  res.json({ status: 'OK', token: data.jwt, user: { id: MOCK_USER_ID, login, role: MOCK_PARENT_ROLE } });
});

app.post('/:school/modules/api/app.php', (req, res) => {
  const tokens = [req.body.token, req.body.JWTToken];
  if (!tokens.includes(data.jwt)) {
    return res.status(401).type('text/html; charset=UTF-8').send(JSON.stringify({ status: 'ERROR', message: 'Brak tokenu autoryzacji' }));
  }
  const view = data.appViews[req.body.view];
  const needsPupil = !ACCOUNT_VIEWS.includes(req.body.view);
  const payload = view === undefined
    ? { errno: 103, message: 'No view exist' }
    : needsPupil && !isPupilOnAccount(req.body, req.params.school)
      ? { errno: WRONG_PUPIL_ERRNO, message: 'Authorization error' }
      : view(req.body, req.params.school);
  res.type('text/html; charset=UTF-8').send(JSON.stringify({
    v: PROTOCOL_VERSION,
    serverTime: new Date().toISOString(),
    ttlFresh: TTL_FRESH_SECONDS,
    ttlRetain: TTL_RETAIN_SECONDS,
    data: payload,
  }));
});

const SESSION_COOKIE = 'laravel_session=mock-session-id';

app.get('/sso/:school/:token', (_req, res) => {
  res.append('Set-Cookie', `${SESSION_COOKIE}; path=/; HttpOnly`);
  res.append('Set-Cookie', 'XSRF-TOKEN=mock-xsrf; path=/');
  res.redirect(302, '/');
});

app.post('/api/unreadMessages', (_req, res) => {
  res.type('text/plain').send(String(data.inbox.filter(m => m.read_at === null).length));
});

const requireSession = (req, res, next) => {
  const cookie = req.get('Cookie') || req.get('X-Cookie-Jar') || '';
  if (!cookie.includes(SESSION_COOKIE)) {
    return res.status(401).json({ message: 'Unauthenticated.' });
  }
  next();
};

app.use('/api/messages', requireSession);

const folder = (list) => (_req, res) => res.json({ items: list(), total: list().length });

app.post('/api/messages/inbox', folder(() => {
  const extraInbox = Object.values(scenarios).flatMap(s => s.extraInbox || []);
  return [...data.inbox, ...extraInbox];
}));
app.post('/api/messages/sent', folder(() => data.sent));
app.post('/api/messages/trash', folder(() => data.trash));
app.post('/api/messages/important', folder(() => data.important));
app.get('/api/messages/read/:id', (_req, res) => res.json(data.readMessage));
app.post('/api/messages/receivers', (req, res) => {
  res.json(req.body.type ? data.receivers : data.receiverTypes);
});
app.post('/api/messages/receivers/search', (_req, res) => res.json(data.receivers));
app.put('/api/messages', (_req, res) => res.json({ id: MOCK_SENT_MESSAGE_ID }));
app.delete('/api/messages/:id', (_req, res) => res.json({ status: 'ok' }));
app.post('/api/messages/:id/stared', (_req, res) => res.json({ status: 'ok' }));
app.post('/api/messages/:id/restore', (_req, res) => res.json({ status: 'ok' }));

app.listen(PORT, '0.0.0.0', () => {
  console.log(`mobireg-mock listening on http://0.0.0.0:${PORT}`);
});
