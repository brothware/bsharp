const express = require('express');
const data = require('./data');

const app = express();
const PORT = process.env.PORT || 8080;
const scenarios = {};

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

app.post('/:school/modules/api/njson.php', (req, res) => {
  const school = req.params.school;
  const { view, student_id, start_date } = req.body;
  const isSchoolB = school === 'sp5-krakow';
  const scenario = scenarios[school] || {};

  if (scenario.failLogin) {
    return res.json({ errno: 101, error: 'Invalid credentials' });
  }

  if (view === 'Settings' || (!view && !student_id)) {
    return res.json(isSchoolB ? data.schoolB.settings : data.settings);
  }

  if (view === 'ParentStudents') {
    return res.json(isSchoolB ? data.schoolB.parentStudents : data.parentStudents);
  }

  if (student_id || start_date) {
    const base = isSchoolB ? data.schoolB.fullSync : data.fullSync;
    if (scenario.extraMarks) {
      const merged = { ...base, Marks: [...base.Marks, ...scenario.extraMarks] };
      return res.json(merged);
    }
    return res.json(base);
  }

  return res.json(isSchoolB ? data.schoolB.settings : data.settings);
});

app.post('/:school/index.php', (req, res) => {
  const school = req.params.school;
  const scenario = scenarios[school] || {};

  if (scenario.failLogin) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  const token = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6';
  res.redirect(302, `https://rodzic.mobireg.pl/${school}/${token}`);
});

app.post('/api.php', (req, res) => {
  const { view, token, school } = req.body;

  if (!token) {
    return res.status(401).json({ error: 'Unauthorized', message: 'Token is invalid or has expired' });
  }

  const isSchoolB = school === 'sp5-krakow';

  if (isSchoolB) {
    const schoolBViews = {
      users: {
        login: 'mwisniewska', name: 'Agnieszka', surname: 'Wiśniewska',
        messagesToken: 'mock-messages-token-schoolb',
        pupils: [{ id: 7001, name: 'Maja', surname: 'Wiśniewska', className: '7b' }],
      },
      marks: { items: [
        { id: 9001, subjectId: 201, kindLabel: 'Sprawdzian', value: '4', markGroupId: 10001, parentMarkGroupId: 0, date: '2026-03-16', weight: 3, bgColor: null, description: 'Ułamki', comments: null },
        { id: 9002, subjectId: 202, kindLabel: 'Kartkówka', value: '5', markGroupId: 10002, parentMarkGroupId: 0, date: '2026-03-18', weight: 2, bgColor: null, description: 'Lektura', comments: 'Świetna praca' },
      ]},
      homeworks: { items: [] },
      tests: { items: [] },
      reprimands: { items: [] },
      bulletins: { items: [] },
      changelog: { items: [] },
    };
    const viewData = schoolBViews[view];
    if (viewData) return res.json(viewData);
    return res.status(400).json({ error: 'Unknown view' });
  }

  const viewData = data.portalViews[view];
  if (viewData) return res.json(viewData);
  return res.status(400).json({ error: 'Unknown view', message: `View '${view}' not found` });
});

app.get('/sso/:school/:token', (req, res) => {
  res.cookie('session', 'mock-session-id', { httpOnly: true, path: '/' });
  res.redirect(302, '/');
});

app.get('/', (_req, res) => {
  res.type('html').send(
    '<!DOCTYPE html><html><head><title>Poczta</title></head><body>' +
    '<script>window.__config = {"csrfToken":"mock-csrf-token-xyz789","user":{"name":"Tomasz Śliwa"}}</script>' +
    '</body></html>'
  );
});

app.post('/api/messages/inbox', (_req, res) => {
  const schoolScenarios = Object.values(scenarios);
  const extraInbox = schoolScenarios.flatMap(s => s.extraInbox || []);
  res.json([...data.inbox, ...extraInbox]);
});
app.post('/api/messages/sent', (_req, res) => res.json(data.sent));
app.post('/api/messages/trash', (_req, res) => res.json(data.trash));
app.post('/api/messages/important', (_req, res) => res.json(data.important));
app.get('/api/messages/read/:id', (_req, res) => res.json(data.readMessage));
app.post('/api/messages/receivers', (_req, res) => res.json(data.receiverTypes));
app.post('/api/messages/receivers/search', (_req, res) => res.json(data.receivers));
app.put('/api/messages', (_req, res) => res.json({ status: 'ok' }));
app.delete('/api/messages/:id', (_req, res) => res.json({ status: 'ok' }));
app.post('/api/messages/:id/stared', (_req, res) => res.json({ status: 'ok' }));
app.post('/api/messages/:id/restore', (_req, res) => res.json({ status: 'ok' }));

app.listen(PORT, '0.0.0.0', () => {
  console.log(`mobireg-mock listening on http://0.0.0.0:${PORT}`);
});
