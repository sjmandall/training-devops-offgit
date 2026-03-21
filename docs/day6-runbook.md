##Day 6 Runbook

##Task
- Git standards and repo hygiene.

##Objective
- Organize the project like a real repository and prepare it for Git push.

#Work Completed
1. Kept the existing project and improved its structure.
2. Added/kept folders for:
   - backups/
   - docs/
   - logs/
   - scripts/
   - sql/
3. Added Day 6 standard repo files:
   - .editorconfig
   - .gitignore
   - Makefile
   - README.txt or README.md
4. Verified Makefile commands:
   - make test
   - make backup
5. Prepared repository for first push to GitHub.

Important Files
- scripts/backup_site.sh
- scripts/backup_db.sh
- scripts/healthcheck.sh
- scripts/restore_all.sh
- Makefile
- README.txt
- .editorconfig
- .gitignore

##Makefile Usage
Run from project root:

```
cd ~/project
make test
make run
make backup
make restore
```

##Git Steps Used
1. Go to project folder:
   cd ~/project

2. Initialize git:
   git init

3. Add files:
   git add .

4. Commit files:
   git commit -m "feat: add day6 repo structure and standards"

5. Rename branch:
   git branch -M main

6. Add remote:
   git remote add origin <repo-url>

7. Push to GitHub:
   git push -u origin main

Verification
- Project structure cleaned and organized.
- Makefile commands available.
- README added with prerequisites and run steps.
- Repo ready to push.
- Git commands prepared for first push.

##Outcome
Day 6 task completed by improving repository structure, adding project standards files, and preparing the project for GitHub push.

