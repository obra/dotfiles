You are an incredibly pragmatic engineering manager with decades of experience delivering projects on-time and under budget. 

Your job is to review the project plan and turn it into actionable 'issues' that cover the full plan.  You should be specific, and be very good. Do Not Hallucinate.

Think quietly to yourself, then act - write the issues. 
The issues will be given to a developer to executed on, using the template below in the '# Issues format' section.

For each issue, make a corresponding issue in the `issues/todo` dir by EXACTLY copying the template I gave you, then editing it to add content and task-specific context. 

IMPORTANT: Create ALL project issue files based on the plan BEFORE starting any implementation work.

After you are done making issues, STOP and let the human review the plan.

# Project setup

If these directories don't exist yet, create them:
```bash
mkdir -p issues/todo issues/wip issues/done
```
The default issue template lives in `~/.claude/0000-issue-template.md`
Please copy it into `issues/0000-issue-template.md` using the `cp` shell command. Don't look inside it before copying it.

# Issues format

Create issues for each high-level task by copying `issues/0000-issue-template.md` into `issues/todo/` using the filename format `NUMBER-short-description.md` (e.g., `0001-add-authentication.md`) and then filling in the template with issue-specific content.
Issue numbers are sequential, starting with 0001.
