##Day 7 Runbook

##Task
Git workflow and release process.

##Objective
Implement a GitFlow-lite workflow using main and develop branches, create a feature branch, open a PR/MR with a review checklist, tag release v1.0.0, and generate a release notes file from commits.

#Workflow Design
1. main branch:
   - Stable production-ready branch.
   - Used for final release state.
2. develop branch:
   - Integration branch for ongoing work.
   - Receives feature branch merges before release.
3. feature branch:
   - Created for isolated task work.
   - Merged into develop through PR/MR review.

Deliverables
1. PR/MR link or screenshots.
2. Tag v1.0.0.
3. RELEASE_NOTES_v1.0.0.md file.

Branch Strategy
- main = stable release branch
- develop = staging/integration branch
- feature/release-process = task branch for Day 7 work

###Commands Used

Step 1: Go to project folder
cd ~/project

Step 2: Ensure main branch exists and is updated
git checkout main
git pull origin main

Step 3: Create develop branch
git checkout -b develop
git push -u origin develop

Step 4: Create feature branch from develop
git checkout -b feature/release-process

Step 5: Add a Day 7 note file for feature work
mkdir -p docs
echo "Day 7 Git workflow and release process completed." >> docs/day7-notes.txt

Step 6: Stage and commit changes
git add .
git commit -m "feat: add day7 git workflow notes"

Step 7: Push feature branch
git push -u origin feature/release-process

PR/MR Creation
1. Open GitHub or GitLab repository in browser.
2. Create a PR/MR from:
   - source: feature/release-process
   - target: develop
3. Add title:
   Day 7: Git workflow and release process
4. Add review checklist in description.

PR Review Checklist
- Changes tested locally
- No unnecessary files included
- Documentation updated
- Branch naming is correct
- Commit message is meaningful
- Ready to merge into develop

Merge Process
1. Merge feature/release-process into develop after review.
2. Pull updated develop branch locally:
   git checkout develop
   git pull origin develop

3. Merge develop into main:
   git checkout main
   git pull origin main
   git merge develop

4. Push main branch:
   git push origin main

Release Tagging
Create annotated tag for release:
git tag -a v1.0.0 -m "Release v1.0.0"

Push tag to remote:
git push origin v1.0.0

Release Notes Generation
Generate markdown release notes file from commit history:

{
  echo "# Release Notes v1.0.0"
  echo
  echo "Release date: 2026-03-23"
  echo
  echo "## Changes"
  git log --pretty=format:"- %h %s"
} > RELEASE_NOTES_v1.0.0.md

Stage and commit release notes:
git add RELEASE_NOTES_v1.0.0.md
git commit -m "docs: add release notes for v1.0.0"
git push origin main

Verification Commands
Check local branches:
git branch

Check remote branches:
git branch -r

Check tag:
git tag

View release notes file:
cat RELEASE_NOTES_v1.0.0.md

Check recent commits:
git log --oneline --decorate -5

Expected Outcome
- main branch exists and contains release-ready code.
- develop branch exists for integration.
- feature/release-process branch created and pushed.
- PR/MR opened from feature branch to develop.
- Review checklist included in PR/MR.
- develop merged into main for release.
- Annotated tag v1.0.0 created and pushed.
- RELEASE_NOTES_v1.0.0.md created from commit history.

Submission Evidence
1. Screenshot or link of PR/MR.
2. Screenshot or output showing tag v1.0.0.
3. RELEASE_NOTES_v1.0.0.md present in repository.

Single Flow Command Reference
cd ~/project && \
git checkout main && \
git pull origin main && \
git checkout -b develop && \
git push -u origin develop && \
git checkout -b feature/release-process && \
mkdir -p docs && \
echo "Day 7 Git workflow and release process completed." >> docs/day7-notes.txt && \
git add . && \
git commit -m "feat: add day7 git workflow notes" && \
git push -u origin feature/release-process

Post-PR Release Commands
git checkout develop
git pull origin develop
git checkout main
git pull origin main
git merge develop
git push origin main
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
{
  echo "# Release Notes v1.0.0"
  echo
  echo "Release date: 2026-03-23"
  echo
  echo "## Changes"
  git log --pretty=format:"- %h %s"
} > RELEASE_NOTES_v1.0.0.md
git add RELEASE_NOTES_v1.0.0.md
git commit -m "docs: add release notes for v1.0.0"
git push origin main

###Conclusion
Day 7 completed by implementing GitFlow-lite branching, creating feature work through a dedicated branch, preparing PR/MR review evidence, tagging the release as v1.0.0, and generating markdown release notes from Git commits.


