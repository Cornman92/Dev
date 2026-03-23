# Dev Workspace — 300-Step Roadmap

Aligned with [FEATURES-AND-AUTOMATIONS-PLAN.md](../FEATURES-AND-AUTOMATIONS-PLAN.md). Use this as a checklist; not all steps are sequential.

---

## Phase 1 — Quick Wins & Foundation (1–40)

1. ✅ Unified MCP test runner (`npm run test:mcp-all`)
2. ✅ Add project-scaffolder to root package.json
3. ✅ Generate-WorkspaceReport.ps1
4. ✅ Root package.json: report:workspace, dashboard:start
5. ✅ _lint-migrate.ps1 accepts Path parameter and batch
6. ✅ consolidate_workspace.ps1 -WhatIf support
7. ✅ Invoke-McpHealthCheck.ps1 with -AsJson
8. ✅ Invoke-AllMcpTests.ps1
9. ✅ Test-ConsolidationState.ps1
10. ✅ Workspace README at D:\Dev
11. ✅ docs/MCP-SERVER-INDEX.md
12. ✅ docs/AUTOMATION-RUNBOOK.md
13. ✅ dev-dashboard paths fixed (active-projects → D:\Dev)
14. ✅ GET /api/workspace-report
15. ✅ GET /api/mcp-status
16. ✅ Root .github/workflows/ci.yml (MCP tests, workspace report)
17. ✅ Schedule-WorkspaceReport.ps1
18. ✅ Invoke-MigrationDryRun.ps1
19. ✅ docs/scheduled-tasks-windows.md
20. ✅ docs/pre-commit-hooks.md
21. ✅ unified-mcp-server README
22. ✅ POST /api/quick-action (mcp-tests, lint, report)
23. ✅ GET /api/code-analysis?path=...
24. ✅ project-scaffolder templates/dev-workspace-mcp-stub.md
25. ✅ Dashboard job in root ci.yml
26. ✅ .github/workflows/nightly.yml
27. ✅ GET /api/projects/:id/coverage
28. ✅ GET /api/projects/:id/deployments, POST for deployments
29. ✅ Document WORKSPACE_ROOT in dashboard env.example (config/env.example)
30. ✅ Add dashboard frontend panel for workspace report (WorkspacePanel: Report tab)
31. ✅ Add dashboard frontend panel for MCP status (WorkspacePanel: MCP Status tab)
32. ✅ Add dashboard frontend for quick actions (WorkspacePanel: Quick Actions tab)
33. Add coverage chart component (Chart.js) in frontend
34. Add deployment status component in frontend
35. Persist layout preferences (localStorage or backend)
36. Add auth middleware (JWT or session) stub
37. Add metrics aggregation API (time ranges)
38. Add export API (CSV/JSON) for projects and builds
39. Add GitHub webhook receiver endpoint stub
40. Add rate limiting and security review for quick-action

---

## Phase 2 — Dashboard Completion (41–90)

41. Complete test coverage chart with trend line
42. Deployment status filters (environment, status)
43. Customizable dashboard layout (grid drag-and-drop)
44. User preference store (SQLite or JSON)
45. Login page and session handling
46. GitHub OAuth integration (optional)
47. Role-based access (viewer vs admin)
48. Advanced metrics visualization (histograms)
49. Compare coverage across projects
50. Alerts configuration UI (build failed, coverage drop)
51. Browser notification permission and display
52. Webhook URL configuration in UI
53. Scheduled report export (cron/Task Scheduler doc)
54. Dashboard dark/light theme persistence
55. Project health score formula tuning
56. Build status badges (shields.io style)
57. Commit activity heatmap
58. Branch protection status display
59. PR status summary
60. Test run history table
61. Coverage history CSV export
62. Deployment history export
63. Dashboard unit tests (Jest/Vitest)
64. API integration tests
65. WebSocket reconnection tests
66. E2E test (Playwright) for main flows
67. Dockerfile for dashboard
68. Docker Compose for dashboard + DB
69. Health check endpoint for orchestrators
70. Logging to file with rotation
71. Structured logging (JSON)
72. Error tracking (e.g. optional Sentry)
73. Performance monitoring (response times)
74. Dashboard documentation in README
75. API versioning (e.g. /api/v1/)
76. OpenAPI/Swagger spec for API
77. Postman/Insomnia collection
78. Dashboard config schema validation
79. Feature flags (env-based)
80. A/B test scaffolding (optional)
81. Multi-workspace support (optional)
82. Project tags and categories
83. Search across projects and commits
84. Filter by date range
85. Pagination for all list endpoints
86. Cursor-based pagination for large lists
87. Caching headers (ETag) for report
88. MCP status caching (TTL) to avoid repeated PS calls
89. Quick-action timeout configuration
90. Audit log for quick actions and deployments

---

## Phase 3 — MCP & Automation (91–140)

91. unified-mcp-server: implement aggregation (proxy to other MCPs)
92. unified-mcp-server: add to root test:mcp-all (pytest in CI)
93. project-scaffolder: template for new PowerShell module (Dev style)
94. project-scaffolder: template for dashboard widget stub
95. powershell-mcp-server: document “run script” tool for dashboard
96. code-analysis-mcp-server: batch analyze directory
97. Dashboard: batch code-analysis for workspace paths
98. Scheduled task XML export for Windows (one-click import)
99. GitHub Actions: scheduled workflow for report at 0 0 * * *
100. Pre-commit hook installer script (PowerShell)
101. Husky or pre-commit framework config
102. Lint multiple scripts in one _lint-migrate.ps1 call (already supported)
103. Consolidation check in CI (fail if drift)
104. Migration what-if in CI (optional job)
105. Nightly workflow: upload logs to artifact and expose “last run” API
106. Dashboard: “Last nightly run” widget
107. Dashboard CI: run in matrix (Node 18, 20)
108. Better11 CI: already in Better11/.github; document in root
109. BetterShell CI: add .github/workflows in BetterShell if applicable
110. NuGet restore in CI for .NET projects
111. PSScriptAnalyzer in CI for PowerShell (root or per-repo)
112. Pester in CI for PowerShell modules
113. Coverage upload (codecov/codecov.io) optional
114. Dependency review action (Dependabot)
115. Security scan (e.g. npm audit, dotnet list package --vulnerable)
116. Container scan for dashboard image
117. Branch protection rules (document)
118. Required status checks (document)
119. Release workflow (tag → build → artifact)
120. Changelog generation from commits
121. Version bump script (semver)
122. MCP server versioning and changelog
123. Backward compatibility tests for MCP tools
124. MCP tool schema validation (Zod) in each server
125. Rate limiting per MCP tool (if exposed via HTTP)
126. Timeout configuration per quick-action
127. Sandbox for quick-action (optional)
128. Allow-list for quick-action scripts (security)
129. Notification when MCP test fails (Slack/Teams/email stub)
130. Dashboard sync job: configurable interval per project
131. Retry logic for GitHub API in sync
132. Exponential backoff for rate limits
133. Webhook signature verification (GitHub)
134. Webhook idempotency (dedupe by delivery ID)
135. Scheduled report email (optional)
136. Report attachment (CSV/PDF) in email
137. Dashboard backup script (DB + config)
138. Restore procedure documentation
139. Disaster recovery runbook
140. Capacity planning notes (concurrent users, DB size)

---

## Phase 4 — Advanced Dashboard & Ops (141–200)

141. Customizable widgets: add/remove panels
142. Widget configuration (refresh interval, filters)
143. Dashboard layout templates (presets)
144. Export/import layout
145. Per-user layouts (when auth is in place)
146. Team or org-level default layout
147. Real-time collaboration (optional, ambitious)
148. Comments or annotations on projects
149. Project documentation tab (link to wiki/docs)
150. Embedded runbooks per project
151. Links to CI/CD runs (GitHub Actions, Azure DevOps)
152. Multiple CI systems (GitLab, Jenkins stubs)
153. Custom status badges (user-defined)
154. SLA tracking (uptime, response time)
155. Cost or resource metrics (placeholder)
156. Integration with monitoring (Prometheus/Grafana stub)
157. Alerting rules engine (simple)
158. Escalation (e.g. after N failures)
159. Maintenance mode (hide or disable actions)
160. Feature flags per project
161. Project archiving (soft delete)
162. Bulk operations (sync all, export all)
163. Dashboard CLI (e.g. npm run dashboard:cli)
164. Backup automation (scheduled)
165. DB migration system (e.g. node-pg-migrate style for SQLite)
166. Seed data script for demo
167. Demo mode (read-only, sample data)
168. Onboarding wizard for new users
169. Tooltips and help in UI
170. Keyboard shortcuts
171. Accessibility (ARIA, focus, screen reader)
172. i18n/l10n (language strings)
173. RTL support (optional)
174. Mobile-responsive dashboard
175. PWA (installable dashboard)
176. Offline support (cache report)
177. Dashboard performance: lazy load panels
178. Virtual scrolling for long lists
179. Debounce search and filters
180. Service worker for cache
181. CDN or static asset optimization
182. Gzip/Brotli for API responses
183. DB indexes review and add as needed
184. Connection pooling (if moving to PostgreSQL)
185. Read replicas (if scaling)
186. Horizontal scaling (stateless dashboard)
187. Session store (Redis) for multi-instance
188. Load balancer configuration doc
189. Kubernetes/Docker Swarm notes (optional)
190. Terraform or IaC for deployment (optional)
191. Environment parity (dev/staging/prod)
192. Secrets management (e.g. Azure Key Vault, env)
193. Compliance checklist (GDPR, logging)
194. Security headers (CSP, HSTS)
195. Penetration test scope doc
196. Incident response runbook
197. Status page (optional)
198. Uptime monitoring (external)
199. Dependency update policy (Renovate/Dependabot)
200. Deprecation policy for API versions

---

## Phase 5 — Ecosystem & Polish (201–260)

201. Better11: link from root README to Better11 docs
202. BetterShell: consolidation status in dashboard
203. BetterPE: deployment tracking for images
204. Skills: document in INDEX and CLAUDE
205. Skills-MCP: integration with MCP index
206. DotFiles: optional project in dashboard
207. docs/INDEX.md: include ROADMAP-300 and USER-GUIDE
208. docs/ARCHITECTURE.md: add dashboard and MCP
209. CONTRIBUTING.md: how to add new MCP server
210. CODE_OF_CONDUCT.md (optional)
211. Security policy (SECURITY.md)
212. License file (MIT or existing)
213. Changelog (CHANGELOG.md) for workspace root
214. Version workspace root (semver)
215. Release notes template
216. Blog or announcement template for releases
217. Video walkthrough (outline)
218. Screenshots for README
219. Badges in README (build, coverage, license)
220. API documentation site (e.g. Docusaurus)
221. Glossary (MCP, workspace, consolidation, etc.)
222. FAQ
223. Troubleshooting guide
224. Performance tuning guide
225. Scaling guide
226. Migration guide (OneDrive → D:\Dev) in docs
227. Developer onboarding checklist
228. Pair programming guide
229. Code review checklist
230. Definition of done
231. Sprint or iteration template
232. Retrospective template
233. Post-mortem template
234. Metrics: cycle time, lead time (optional)
235. User feedback mechanism (form or issue template)
236. Feature request template
237. Bug report template
238. RFC template for large changes
239. Architecture decision records (ADRs)
240. Tech stack diagram (Mermaid)
241. Sequence diagram for key flows
242. Data flow diagram
243. Network diagram (if multi-service)
244. Runbook index (link all runbooks)
245. Escalation contacts (placeholder)
246. Vendor list (GitHub, Node, etc.)
247. Compliance matrix (optional)
248. Training plan (optional)
249. Certification or audit trail (optional)
250. Community guidelines (if open source)
251. Moderation policy (if community)
252. Sponsorship or funding (optional)
253. Roadmap public view (filtered)
254. Voting on features (optional)
255. Beta program (optional)
256. Deprecation announcements process
257. Sunset policy for features
258. Data retention policy
259. Privacy policy (if PII)
260. Terms of use (if applicable)

---

## Phase 6 — Innovation & Future (261–300)

261. AI-assisted summaries for commit messages
262. AI-generated release notes
263. Anomaly detection for coverage/build (stub)
264. Predictive “at risk” projects (stub)
265. Recommendation engine (suggest actions)
266. Natural language query for dashboard (stub)
267. Voice or chat interface (stub)
268. Mobile app (React Native/Flutter stub)
269. Desktop app (Tauri/Electron) wrapping dashboard
270. Browser extension for quick status
271. IDE extension (VS Code) for workspace status
272. Slack/Teams bot for status
273. Discord bot (optional)
274. API for third-party integrations
275. Webhook outbound (notify external systems)
276. Plugin system for dashboard
277. Custom MCP tools from config
278. GraphQL API (optional)
279. Real-time collaboration (shared cursor)
280. Multi-tenant (multiple workspaces)
281. SSO (SAML/OIDC)
282. Audit log export to SIEM
283. Compliance reports (auto-generated)
284. Cost allocation by project (stub)
285. Resource tagging
286. Green/sustainability metrics (stub)
287. Carbon footprint estimate (stub)
288. Accessibility audit (automated)
289. Performance budget (Lighthouse CI)
290. Core Web Vitals tracking
291. Error budget (SRE)
292. SLA dashboard
293. SLO definitions and tracking
294. Chaos engineering (optional)
295. Canary deployment (optional)
296. Feature flags service (optional)
297. Experimentation framework (A/B) (optional)
298. Analytics (privacy-preserving)
299. Feedback loop (close the loop with users)
300. Continuous improvement backlog (this roadmap)

---

*Check off steps as completed; reprioritize as needed. See [USER-GUIDE.md](./USER-GUIDE.md) for how to use the workspace and dashboard.*
