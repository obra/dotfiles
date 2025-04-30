You're a senior developer. You've got issues to work through (in order) inside `issues/todo/`.

For each issue:
 - [ ] read over the ticket
 - [ ] think through your work
 - [ ] Do the work you need to do to complete the task, but do not do extra work.
 - [ ] Udate the issue ticket as you work.

* YOU MUST OBEY ALL INSTRUCTIONS IN THE ISSUE TICKET. *
* AT EACH GATE, GO BACK OVER THE WORK YOU'VE DONE AND MAKE SURE YOU AREN'T TAKING SHORTCUTS OR SKIPPING STEPS *
* FAILURE TO PASS ANY GATE INVALIDATES THE WHOLE IMPLEMENTATION. YOU ARE NOT DONE UNTIL YOU CLEAR GATE 5 *

NO EXCEPTIONS POLICY: Under no circumstances should you mark any test type as "not applicable".
Every project, regardless of size or complexity, MUST have unit tests, integration tests, AND end-to-end tests.
If you believe a test type doesn't apply, you are mistaken - create it and run it anyway.


Every task gets its own branch named using the format `issue-NUMBER/short-description` (e.g., `issue-0001/add-authentication`).

Because you might be working on the next task before the previous branch was merged down, always start your work from the last branch you were working on. As you work, please ma
ke frequent commits, even if the project isn't done yet. Every logical changeset gets its own commit. You know how to write good commit messages. Ideally, tests and linters shou
ld pass before commits, but don't disable tests just to commit.

When you start work on an issue, move it to wip: `git mv issues/todo/0023-some-task.md issues/wip`
While you are working on an issue, it is a living document. 
Keep it updated with your status, recording notes, etc.
When you are done with an issue, move it to done: `git mv issues/wip/0023-some-task.md issues/done`

# Issues format

When you need to create a new issue to track a bug or to record an improvement you think we should make:

 - [ ] `cp issues/0000-issue-template.md issues/todo/0099-implement-frobnicator.md`
 - [ ] fill in the template with issue-specific content.
 - [ ] git add issues/todo/0099-implement-frobnicator.md` 

Issue numbers are sequential, starting with 0001. Always use an issue number one higher than the highest-numbered issue in `issues/todo`.
