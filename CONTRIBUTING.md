# Contributing to Masheev Skills

We welcome contributions that help developers integrate Masheev into their applications.

## Adding a New Skill

1. Create a directory under `skills/` with a lowercase-hyphenated name
2. Add a `SKILL.md` with required YAML frontmatter (`name`, `description`)
3. Keep `SKILL.md` body under 500 lines
4. Put detailed docs in `references/` subdirectory
5. Test the skill by installing it locally and using it with an AI coding agent

## Improving an Existing Skill

- Fix inaccurate code examples or outdated API signatures
- Add missing framework examples (Vue, Svelte, etc.)
- Improve the description for better trigger accuracy
- Add `references/` files for edge cases

## Skill Quality Checklist

- [ ] `name` matches the directory name
- [ ] `description` includes what the skill does AND when to use it
- [ ] Code examples use correct, current API signatures
- [ ] SKILL.md body is under 500 lines
- [ ] Reference files over 300 lines include a table of contents
- [ ] No hardcoded URLs or tokens in examples

## Running Locally

```bash
# Install a skill from your local clone
npx skills add ./path/to/masheev-skills --skill masheev-widget

# Or symlink into your project's .claude/skills/ directory
ln -s /path/to/masheev-skills/skills/masheev-widget .claude/skills/masheev-widget
```
