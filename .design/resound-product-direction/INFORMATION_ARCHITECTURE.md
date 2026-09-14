# Information architecture: Resound

## Product framing

Resound is a lesson-memory and practice-review app for musicians. It should not feel like a recorder with tags bolted on. The product earns its place when it brings the right bit of a teacher's advice back at the right practice session.

The main user is a student. A teacher or coach may later share feedback, assignments, and clips, but that is a companion workflow. It should not dictate the first version's navigation.

## Feature ideas

### Product manager view

1. AI lesson recap. After a recording, propose a short summary, a few takeaways, and candidate themes. The student approves or corrects each item.
2. Practice queue. Turn saved takeaways into a short list for the next session, ordered by a due date, teacher emphasis, and the student's own priority.
3. Source-linked clips. Every takeaway opens the exact source timestamp or video segment. This is the trust mechanism for AI output.
4. Teacher handoff. Give a teacher a simple way to send an assignment, response clip, or follow-up note to a student without becoming a full learning-management system.
5. Lesson timeline. Show a student's progress by lesson date, repertoire, technique, and recurring themes. This makes the value of consistent use visible.

### Product designer view

1. One-tap capture. Put recording within reach everywhere, with audio as the default and clear ways to add video, import media, or write a reflection.
2. A review-first landing screen. Open to the few items worth revisiting today, then let the student move into the full archive when needed.
3. The moment card. Use one recognizable card for a clip, takeaway, note, or teacher assignment. It always shows the source, theme, and next action.
4. Lightweight annotation. Let students select a transcript span or timestamp, then save a clip, note, or practice item without filling in a long form.
5. Calm post-lesson flow. After saving a lesson, invite the student to name the lesson and approve highlights. Do not force organization while they are packing up.

### Software engineer view

1. On-device capture with an offline outbox. Save recording and edits locally first, then sync the source media and metadata when a connection returns.
2. Timestamped transcript and semantic index. Store transcript segments with time ranges, embeddings, themes, and links to their parent recording. This enables trustworthy search and clipped playback.
3. A durable content graph. Model a lesson as a source recording with derived clips, takeaways, practice items, notes, tags, and optional teacher ownership. Do not flatten everything into an unstructured note field.
4. Background processing pipeline. Upload, transcribe, summarize, index, and notify in separate resumable steps. Each result needs status, retry, and provenance.
5. Share and permissions layer. Give every shared item an explicit owner, audience, and revoke action before adding real teacher collaboration.

## Top five bets

| Bet | Why it comes first | Assumption to test |
|---|---|---|
| Source-linked AI takeaways | It turns a long recording into a useful practice memory without asking the student to trust a black box. | Students will save and replay suggested takeaways more often when the original moment is one tap away. |
| Practice queue | This closes the gap between a lesson and the next practice session. It is the product's clearest recurring reason to open Resound. | Students prefer a short, editable list over browsing recordings before practice. |
| Fast capture and after-the-fact organization | Recording must work in the room, even when attention is on the teacher and instrument. | Students will capture more if tags, titles, and summaries can wait. |
| Semantic search and theme pages | The archive becomes valuable when a student can find every explanation of vibrato, comping, or breathing across lessons. | Theme-based retrieval beats date-only browsing once someone has several lessons. |
| Teacher handoff | It can make Resound part of the lesson relationship rather than a private student utility. | Teachers will share a small number of precise assignments if the workflow is faster than composing a message elsewhere. |

The first three are the MVP. Search becomes compelling after enough content exists. Teacher handoff should follow only after the student loop is working.

## Site map

Resound is a native iOS app, so this map uses screens and proposed deep-link patterns rather than web URLs.

- Review `resound://review`
  - Today `resound://review/today`
  - Practice item `resound://practice/{practice-item-id}`
  - Takeaway detail `resound://takeaways/{takeaway-id}`
- Library `resound://library`
  - Recent lessons `resound://library?sort=recent`
  - Lesson / source recording `resound://recordings/{recording-id}`
  - Clip `resound://clips/{clip-id}`
  - Text note `resound://notes/{note-id}`
  - Tag or theme collection `resound://library?theme={slug}`
- Create, a global action rather than a destination
  - Record audio
  - Record video
  - Import media
  - Write a note
  - Save a selected transcript range as a clip or takeaway
- Find `resound://find`
  - Search results `resound://find?q={query}`
  - Themes `resound://themes`
  - Theme detail `resound://themes/{theme-slug}`
  - Tags `resound://tags`
  - Date archive `resound://library?date={yyyy-mm}`
- You `resound://you`
  - Goals and instruments `resound://you/goals`
  - People and sharing `resound://you/people`
  - Settings `resound://settings`
  - Sync and account `resound://settings/sync`

## Navigation model

### Primary navigation

Use four persistent bottom tabs plus a raised central Create action.

| Position | Label | Job | Why it belongs here |
|---|---|---|---|
| 1 | Review | Show today's practice queue, recently saved takeaways, and overdue items. | This is the value-return loop and should be the default tab after onboarding. |
| 2 | Library | Browse raw lessons, clips, and notes by recency. | The existing Studio becomes a dedicated archive rather than the whole app. |
| Center action | Create | Record, import, write, or save a clip. | Capture is an action with several entry modes. Making it a tab wastes a navigation slot and confuses selected state. |
| 3 | Find | Search transcripts and notes, then browse themes, tags, and dates. | Retrieval is a separate intent from browsing recent material. |
| 4 | You | Goals, teacher connections, sync status, and settings. | Personal and account-level tools should not compete with lesson content. |

Do not use a generic "Home" tab. "Review" says what the student gets when they open the app. Do not make "Lessons" a tab either. A lesson is a source record, while a clip, a takeaway, or a practice item can all be the thing a student needs.

The existing floating capture dock should become the center Create action. On Library it can still expand into its current audio, video, import, and text options. On every other tab, it should open the same creation sheet. A recording flow remains full-screen so it does not feel like a lightweight note action.

### Secondary navigation

- Review uses a segmented control only when needed: Today, Upcoming, Completed.
- Library uses filter chips for format, tag, theme, date, and teacher. Keep the default view recent and simple.
- Find begins with search. Theme, Tag, and Date are browse modes below the search field, not more tabs.
- Detail screens use a top navigation stack. A source recording has tabs or a compact switcher for Playback, Transcript, and Notes only when those views exist.

### Utility navigation

Settings moves out of the Library toolbar into You. Sync state stays visible where it matters, such as an unsynced recording or a small status row in You, rather than earning a primary destination.

### Mobile behavior

Keep bottom navigation visible at the root of each tab. Hide it during full-screen recording, playback editing, and modal save flows, then return the student to the originating tab. Preserve each tab's navigation stack and filters when switching tabs.

## Content hierarchy

### Review

1. The next one to three practice items. A student often opens Resound with limited time.
2. The linked takeaway and replay control. The advice must be audible or visible in context.
3. A quick completion or snooze action. Practice plans need to change without ceremony.
4. Recent lesson recap and older items.

### Library

1. Recent lesson sources and recently saved clips.
2. Filters for date, tag, theme, media type, and teacher.
3. Capture action, available globally.
4. Archive management, sync state, and bulk organization.

### Find

1. Search field with results that quote the matching transcript or note text.
2. Exact linked timestamp or clip for every result.
3. Theme collections and related concepts.
4. Tags and date archive.

### Recording detail

1. Playback and the current moment in the recording.
2. Saved clips and takeaways from this source.
3. Transcript or text content.
4. Notes, tags, sharing, and metadata.

### You

1. Current goal and next lesson context.
2. Teacher or coach connections and shared work.
3. Account, sync, and settings.

## User flows

### Capture a lesson and save the useful part

1. The student taps Create from any root tab.
2. They choose audio, video, import, or text.
3. Resound saves locally immediately and returns them to the recording detail.
4. Processing produces transcript and takeaway suggestions.
5. The student approves, edits, or dismisses a suggestion.
6. The saved takeaway links to the exact source range and optionally enters the practice queue.

### Practice before the next lesson

1. The student opens Review.
2. They see a short ordered list of takeaways and assignments.
3. They open an item, read the note, and replay the source clip.
4. They mark it practiced, change its due date, or add a reflection.
5. Resound updates the queue and preserves the history for later review.

### Retrieve an old explanation

1. The student opens Find.
2. They search a phrase such as "left hand tension" or open the Technique theme.
3. Results show matching snippets, linked clips, and lesson date.
4. They open the result at the relevant timestamp and can save it into the current practice queue.

### Teacher follow-up, later phase

1. A teacher shares an assignment or response clip with a student.
2. The student receives it in Review with the teacher's name and due date.
3. The student practices, adds a response if invited, and marks it complete.
4. The teacher sees the response only when the student explicitly shares it.

## Naming conventions

| Concept | Label in UI | Notes |
|---|---|---|
| Original audio, video, or imported file | Lesson recording | A source object, even if it was recorded after the lesson. |
| Saved time range from a source | Clip | Plain language and familiar to musicians. |
| A concise instruction or insight | Takeaway | The distilled point, always linked to a source when one exists. |
| A planned action for practice | Practice item | More concrete than task, without implying classroom software. |
| AI-derived topic cluster | Theme | Use Tags for user-applied labels and Themes for grouped related material. |
| Free-form written content | Note | Covers reflections and manual notes. |
| A person who gives instruction | Teacher | Use Coach only if the relationship is explicitly configured that way. |

## Component reuse map

| Component | Used on | Behavior differences |
|---|---|---|
| Root tab shell | Review, Library, Find, You | Preserves each tab's navigation path and hosts global Create. |
| Create sheet | All root tabs and detail screens | Offers context-aware actions, such as saving a selected transcript span when invoked from detail. |
| Moment card | Review, Library, Find, recording detail | Shows a clip, takeaway, note, or assignment with source and next action. |
| Source player | Recording detail, clip detail, Review, Find result | Starts at a timestamp or plays a bounded clip. |
| Filter chip row | Library and Find browse modes | Library filters the archive. Find filters semantic results. |
| Processing status | Recording detail, Library card, You | Detailed retry controls only on detail and You. |

## Content growth plan

Recordings, transcripts, clips, takeaways, practice history, tags, and themes will grow continuously. Library should use cursor pagination after the recent screen. Find needs full-text and semantic retrieval, with filters for theme, tag, date range, teacher, and media type. Theme pages should cluster related items without duplicating source data. Preserve a stable source relationship for every derived item so deleting or changing a title does not break retrieval.

Avoid a primary navigation item for every future content type. Clips, notes, assignments, and shared material should enter through Review, Library, Find, and detail views according to the user's job in that moment.

## Deep-link strategy

- Use `resound://{section}` for root destinations.
- Use stable UUIDs for recordings, clips, notes, takeaways, and practice items.
- Use readable slugs for themes, with an internal stable ID behind them if names can change.
- Use query parameters only for transient filters and search state, such as `q`, `theme`, `tag`, `date`, and `sort`.
- Shared links should resolve to a specific item and show its source relationship before any action is taken.
